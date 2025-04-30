/* SYSIFCOPT(*IFSIO) TERASPACE(*YES *TSIFC)   STGMDL(*SNGLVL) */
/* ------------------------------------------------------------- */
/* SYSIFCOPT(*IFSIO) OPTION(*EXPMAC *SHOWINC)                    */
/* Program . . . : CALLsRVPGM                                    */
/* Date  . . . . : 14.06.2012                                    */
/* Design  . . . : Niels Liisberg                                */
/* Function  . . : Load service program and procedures           */
/*                                                               */
/*By    Date      Task   Description                         */
/* NL     14.06.2012         New module                          */
/* ------------------------------------------------------------- */
#include <QLEAWI.h>
#include <signal.h>
#include <mih/stsppo.h>
#include <mih/setsppo.h>
#include <mih/MIDTTM.h>
#include <qwtsetp.h>
#include <miptrnam.h>
#include <qsygetph.h>
#include <qbnrpii.h>
#include <mih/callpgmv.h>
#include <errno.h>
#include <stdio.h>

#include "ostypes.h"
#include "apierr.h"
#include "parms.h"
#include "trycatch.h"
#include "utl100.h"

#include "jsonxml.h"

extern UCHAR BraBeg;
extern UCHAR BraEnd;
extern UCHAR Masterspace;


/* ------------------------------------------------------------- */
_SYSPTR jx_loadServiceProgram (PUCHAR lib , PUCHAR srvPgm)
{
   UCHAR srvPgm_  [11];
   UCHAR lib_     [11];
   _SYSPTR pgm;

   padncpy (srvPgm_ , srvPgm , 10);
   padncpy (lib_    , lib    , 10);

   try {
      pgm = rslvsp(WLI_SRVPGM , srvPgm_  , lib_  , _AUTH_OBJ_MGMT);
   }
   catch (NULL) {
      pgm = NULL;
   }
   return pgm;
}
/* ------------------------------------------------------------- */
_SYSPTR jx_loadProc (_SYSPTR srvPgm ,  PUCHAR procName)
{
   _SYSPTR proc;
   int type;
   APIERR  apierr;
   UINT64 mark;
   int expNo = 0;
   int expLen = 0;
   int i;
   int acInfoLen;
   Qle_ABP_Info_t acinfo;
   Qus_EC_t       ec;

   if (srvPgm == NULL) return NULL;

   ec.Bytes_Provided = sizeof(ec);
   apierr.size = sizeof(apierr);
   acInfoLen = sizeof(acinfo);
   QleActBndPgmLong(&srvPgm, &mark , &acinfo , &acInfoLen , &ec);
   proc = QleGetExpLong(&mark , &expNo  , &expLen , procName , &proc , &type , &ec);
   return proc;
}
/* ------------------------------------------------------------- */
_SYSPTR jx_loadServiceProgramProc (PUCHAR lib , PUCHAR srvPgm, PUCHAR procName)
{
    _SYSPTR pgm = jx_loadServiceProgram (lib , srvPgm);
    return jx_loadProc (pgm, procName);
}
/* ------------------------------------------------------------- */
_SYSPTR jx_loadProgram (PUCHAR lib , PUCHAR pgm)
{
   UCHAR pgm_  [11];
   UCHAR lib_  [11];
   _SYSPTR pPgm;

   sprintf(pgm_ , "%-10.10s" , pgm);
   sprintf(lib_ , "%-10.10s" , lib);

   try {
      pPgm = rslvsp(WLI_PGM , pgm_  , lib_  , _AUTH_OBJ_MGMT);
   }
   catch (NULL) {
      pPgm = NULL;
   }
   return pPgm;
}

static void convertDate ( PUCHAR pOut, PUCHAR pIn , PUCHAR pFormat )
{
   if (0 == strcmp ( pFormat , "ISO")) {
      strcpy(pOut, pIn); // noxDb is always in ISO
   } else if (0 == strcmp ( pFormat , "EUR")) { // YYYY-MM-DD to DD/MM/YYYY
      strcpy (pOut , "0001-01-01");
      memcpy ( pOut + 6 , pIn +0 , 4); // YYYY
      memcpy ( pOut + 3 , pIn +5 , 2); // MM
      memcpy ( pOut + 0 , pIn +8 , 2); // DD
   } // todo  - more to come
   else {
      strcpy ( pOut , pFormat); // Abbend !!
   }
}
static PUCHAR fmtDate ( PUCHAR pOut, PUCHAR pIn , PUCHAR pFormat , UCHAR separator )
{
   if (0 == strcmp ( pFormat , "ISO")) {
      strcpy(pOut, pIn); // noxDb is always in ISO
   } else if (0 == strcmp ( pFormat , "EUR")) { // YYYY-MM-DD to DD/MM/YYYY
      strcpy (pOut , "01-01-0001");
      memcpy ( pOut + 0 , pIn +6 , 4); // YYYY
      memcpy ( pOut + 5 , pIn +3 , 2); // MM
      memcpy ( pOut + 8 , pIn +0 , 2); // DD
      pOut[2] = pOut[5] = separator;
      pOut[10] = '\0';
   } // todo  - more to come
   else {
      strcpy ( pOut , pFormat); // Abbend !!
   }
   return pOut;
}

static PUCHAR fmtTime ( PUCHAR pOut, PUCHAR pIn , UCHAR separator )
{
   strcpy (pOut , pIn);
   pOut[2] = pOut[5] = separator;
   pOut[8] = '\0';
   return pOut;
}


static UCHAR convertSeperator (PUCHAR pSeprator)
{
   if (0 == strcmp ( pSeprator , "hyphen")) {
      return '-';
   } else if (0 == strcmp ( pSeprator , "period")) {
      return '.';
   } else if (0 == strcmp ( pSeprator , "slash")) {
      return '/';
   } else if (0 == strcmp ( pSeprator , "blank")) {
      return ' ';
   } else {
      return '-'; // Abbend !!
   }
}
static PUCHAR parmMetaValue (PJXNODE pNode , PUCHAR key)
{
   return jx_GetAttrValuePtr ( jx_AttributeLookup (  pNode, key));
}
static int min(int a, int b)
{
   return (a<b) ? a : b;
}
static int buildArgBufferArray (PJXMETHOD pMethod, PJXNODE pParms, PVOID argArray [256] , PUCHAR  pParmBuffer)
{

   int args = 0;
   int bufTotlen;
   PUCHAR pBuf;
   PJXNODE pLib , pPgm ,pProc , pInterface, pParmObj;

   // TODO move this to a function
   pLib  = jx_GetNode(pMethod->pMetaNode, pMethod->library);
   pPgm  = jx_GetNode(pLib , pMethod->program);
   pProc = jx_GetNode(pPgm , pMethod->procedure);

   pInterface = (pProc == NULL) ? pPgm : pProc;
   bufTotlen =  atoi(jx_GetValuePtr  (pInterface , "buflen" , "0")) ;

   memset ( pParmBuffer , '\0',  bufTotlen);

   pParmObj = jx_GetNodeChild(jx_GetNode ( pInterface , "parms"));
   while (pParmObj) {
      JX_DTYPE dType = *jx_GetValuePtr (pParmObj , "dType" , "?");
      int offset     = atoi(jx_GetValuePtr  (pParmObj , "offset" , "0"));
      int prec       = atoi(jx_GetValuePtr  (pParmObj , "prec"   , "0"));
      int length     = atoi(jx_GetValuePtr  (pParmObj , "length"   , "0"));
      int buflen     = atoi(jx_GetValuePtr  (pParmObj , "buflen"   , "0"));
      PUCHAR format  = jx_GetValuePtr   (pParmObj , "format" , "");
      UCHAR  use     = *jx_GetValuePtr  (pParmObj , "use"    , "B");
      PUCHAR name    = jx_GetValuePtr   (pParmObj , "name"   , "????");
      PUCHAR pValue  = jx_GetValuePtr   (pParms , name , "");

      pBuf = pParmBuffer + offset;
      argArray [args++] = pBuf;

      switch (dType) {
         case JX_DTYPE_CHAR: {
            padncpy ( pBuf, pValue , length);
            break;
         }
         case JX_DTYPE_VARCHAR: {
            ULONG actlen = min(strlen (pValue), length);
            if (prec == 2) {
               *(PUSHORT) pBuf = actlen;
            } else {
               *(PULONG)  pBuf = actlen;
            }
            memcpy ( pBuf + prec, pValue , actlen); // include the zero term
            break;
         }

         case JX_DTYPE_INT: {
            switch (length) {
               case 8: *(long long *) (pBuf) = atoll (pValue); break;
               case 4: *(long *) pBuf = atol (pValue); break;
               case 2: *(int *) pBuf = atoi (pValue); break;
               case 1: *(char *) pBuf = atoi (pValue); break;
            }
            break;
         }
         case JX_DTYPE_BYTE: {
            *(PUCHAR) pBuf = atoi (pValue);
            break;
         }
         case JX_DTYPE_PACKED: {
            str2packedMem ( pBuf  , pValue , length, prec);
            break;
         }
         case JX_DTYPE_ZONED: {
            str2zonedMem ( pBuf , pValue , length, prec);
            break;
         }
         case JX_DTYPE_DATE: {
            convertDate  ( pBuf , pValue , format);
            break;
         }
         case JX_DTYPE_TIME: {
            memcpy ( pBuf , "00.00.00", 8);
            memcpy ( pBuf , pValue , min(strlen(pValue), length));
            break;
         }
         case JX_DTYPE_TIME_STAMP: {
            memcpy ( pBuf , "0001-01-01-00.00.00.000000000", length);
            memcpy ( pBuf , pValue , min(strlen(pValue), length));
            break;
         }
         case JX_DTYPE_UNKNOWN: {
            break;
         }

      }
      pParmObj = jx_GetNodeNext(pParmObj);
   }
   return args;
}

static PJXNODE buildReturnObject (PJXMETHOD  pMethod, PJXNODE pParms, PVOID argArray [256], int args , PUCHAR pParmBuffer)
{
   int argIx= 0;

   PJXNODE pParmMeta = pMethod->pMetaNode;
   PJXNODE pReturnObject = jx_NewObject(NULL);
   PJXNODE pLib , pPgm ,pProc , pInterface, pParmObj;

   // TODO move this to a function
   pLib  = jx_GetNode(pMethod->pMetaNode, pMethod->library);
   pPgm  = jx_GetNode(pLib , pMethod->program);
   pProc = jx_GetNode(pPgm , pMethod->procedure);

   pInterface = (pProc == NULL) ? pPgm : pProc;

   pParmObj = jx_GetNodeChild(jx_GetNode ( pInterface , "parms"));
   while (pParmObj) {
      if (*jx_GetValuePtr  (pParmObj , "use"    , "B") == 'B') {

         UCHAR temp [256];
         UCHAR data [32000];
         PUCHAR pData = data;
         NODETYPE nodeType = VALUE;
         JX_DTYPE dType = *jx_GetValuePtr (pParmObj , "dType" , "?");
         int offset     = atoi(jx_GetValuePtr  (pParmObj , "offset" , "0"));
         int prec       = atoi(jx_GetValuePtr  (pParmObj , "prec"   , "0"));
         int length     = atoi(jx_GetValuePtr  (pParmObj , "length"   , "0"));
         int buflen     = atoi(jx_GetValuePtr  (pParmObj , "buflen"   , "0"));
         PUCHAR format  = jx_GetValuePtr   (pParmObj , "format" , "");
         UCHAR  use     = *jx_GetValuePtr  (pParmObj , "use"    , "B");
         UCHAR  seperator  = *jx_GetValuePtr  (pParmObj , "seperator" , ".");
         PUCHAR name    = jx_GetValuePtr   (pParmObj , "name"   , "????");

         pParmBuffer = argArray [argIx];

         switch (dType) {
            case JX_DTYPE_CHAR: {
               pData = righttrimlen(pParmBuffer , length );
               break;
            }
            case JX_DTYPE_VARCHAR: {
               int actlen =  (prec == 2) ?  *(PUSHORT) pParmBuffer : *(PULONG) pParmBuffer;
               substr (data  , pParmBuffer + prec ,actlen);
               break;
            }

            case JX_DTYPE_INT: {
               switch (length) {
                  case 8: sprintf ( data , "%lld" ,*(long long *) pParmBuffer); break;
                  case 4: sprintf ( data , "%ld"  ,*(long *)      pParmBuffer); break;
                  case 2: sprintf ( data , "%d"   ,*(short int *) pParmBuffer); break;
                  case 1: sprintf ( data , "%d"   ,*(short int *) pParmBuffer); break; // check !!
                  }
               break;
            }
            case JX_DTYPE_BYTE: {
               sprintf ( data , "%c"   ,* pParmBuffer);
               break;
            }
            case JX_DTYPE_PACKED: {
               pData = fmtPacked(data  , pParmBuffer , length  , prec , '.');
               nodeType = LITERAL;
               break;
            }
            case JX_DTYPE_ZONED: {
               pData = fmtZoned (data  , pParmBuffer , length  , prec, '.');
               nodeType = LITERAL;
               break;
            }
            case JX_DTYPE_DATE: {
               pData = fmtDate  ( data , pParmBuffer , format , seperator);
               break;
            }
            case JX_DTYPE_TIME: {
               pData = fmtTime  ( data , pParmBuffer , seperator);
               break;
            }
            case JX_DTYPE_TIME_STAMP: {
               substr  ( data  ,  pParmBuffer , length);
               break;
            }
            case JX_DTYPE_UNKNOWN: {
               break;
            }
         }
         jx_SetValueByName( pReturnObject , str2lower (temp, name ) , pData , nodeType );
      }
      argIx++;
      pParmObj = jx_GetNodeNext(pParmObj);
   }

   return pReturnObject;
}
/* --------------------------------------------------------------------------- *\
   parse PCML:
   <pcml version="7.0">
      <program name="ALLTYPES" entrypoint="ALLTYPES">
         <data name="CHAR" type="char" length="10" usage="inputoutput"/>
         <data name="INT" type="int" length="8" precision="63" usage="inputoutput"/>
         <data name="PACKED" type="packed" length="9" precision="2" usage="inputoutput"/>
         <data name="IND" type="char" length="1" usage="inputoutput"/>
         <data name="DATE" type="date" dateformat="ISO" dateseparator="hyphen" usage="inputoutput"/>
         <data name="TIME" type="time" timeformat="ISO" timeseparator="period" usage="inputoutput"/>
         <data name="TIMESTAMP" type="timestamp" usage="inputoutput"/>
      </program>
      <program name="NAMEAGE" entrypoint="NAMEAGE">
         <data name="NAME" type="char" length="10" usage="input"/>
         <data name="TEXT" type="char" length="200" usage="inputoutput"/>
         <data name="AGE" type="packed" length="5" precision="0" usage="inputoutput"/>
      </program>
   </pcml>
\* --------------------------------------------------------------------------- */

/* --------------------------------------------------------------------------- *\
    Call the plain program resolved by the system pointer:
\* --------------------------------------------------------------------------- */
static PJXNODE  call    (PJXMETHOD pMethod , PJXNODE parms, ULONG options)
{
   PJXNODE pReturnObject;
   PJXNODE pParms;
   BOOL    freeAfter;
   UCHAR   parmbuffer [320000];
   PVOID   argArray[256];
   int     args;

   if ((parms != NULL)
   &&  (parms->signature != NODESIG)) {
      pParms  = jx_ParseString ((PUCHAR) parms, "" );
      freeAfter = TRUE;
   } else {
      pParms  = parms;
      freeAfter = FALSE;
   }

   args = buildArgBufferArray ( pMethod, pParms, argArray, parmbuffer);

   if ( pMethod->userMethodIsProgram) {
      _CALLPGMV ( &pMethod->userMethod , argArray , args );
   } else {
      jx_callProc (pMethod->userMethod , argArray , args);
   }

   pReturnObject = buildReturnObject (pMethod, pParms, argArray, args , parmbuffer);


   if (freeAfter) {
      jx_NodeDelete (pParms);
   }

   return pReturnObject;
}

/* --------------------------------------------------------------------------- *\
    Get the pcml from the program
\* --------------------------------------------------------------------------- */
PJXNODE  jx_ProgramMeta ( PUCHAR library , PUCHAR Program)
{
   Qbn_Interface_Entry_t * pet;
   Qbn_PGII0100_t * ppgi;
   UCHAR buffer [100000];
   long long err = 0;
   long i;
   PJXNODE pPcml;
   PUCHAR pcml;
   UCHAR libpgm [20];

   padncpy ( libpgm      , Program , 10 );
   padncpy ( libpgm +10  , library , 10 );

   QBNRPII (
      buffer ,                   /* Receiver variable                    */
      sizeof(buffer),            /* Length of receiver variable          */
      "RPII0100 ",               /* Format name                          */
      libpgm     ,               /* Qualified object name                */
      "*PGM      ",              /* Object Type                          */
      "*ALLBNDMOD          ",    /* Qualified bound module name          */
      &err                       /* Error code                           */
   );
   ppgi = (Qbn_PGII0100_t *) buffer;
   pet = (Qbn_Interface_Entry_t * ) (buffer + ppgi->Offset_First_Entry);
   pcml = buffer + pet->Offset_Interface_Info;
   pcml [pet->Interface_Info_Length_Ret] = '\0';
   pPcml  = jx_ParseString(pcml, "");
   return  pPcml;
}
/* --------------------------------------------------------------------------- *\
    Get the pcml from the program
\* --------------------------------------------------------------------------- */
PJXNODE  jx_ProcedureMeta ( PUCHAR library , PUCHAR Program , PUCHAR Procedure)
{
   Qbn_Interface_Entry_t * pet;
   Qbn_PGII0100_t * ppgi;
   UCHAR buffer [100000];
   long long err = 0;
   long i;
   PJXNODE pPcml;
   PUCHAR pcml;
   UCHAR libpgm [20];

   padncpy ( libpgm      , Program , 10 );
   padncpy ( libpgm +10  , library , 10 );

   QBNRPII (
      buffer ,                   /* Receiver variable                    */
      sizeof(buffer),            /* Length of receiver variable          */
      "RPII0100 ",               /* Format name                          */
      libpgm     ,               /* Qualified object name                */
      "*SRVPGM      ",              /* Object Type                          */
      "*ALLBNDMOD          ",    /* Qualified bound module name          */
      &err                       /* Error code                           */
   );
   ppgi = (Qbn_PGII0100_t *) buffer;
   pet = (Qbn_Interface_Entry_t * ) (buffer + ppgi->Offset_First_Entry);
   for (i=0;i< ppgi->Number_Entries; i++ ) {
      pcml = buffer + pet->Offset_Interface_Info;
      pcml [pet->Interface_Info_Length_Ret] = '\0';
      pPcml  = jx_ParseString(pcml, "");
      if (*library == '*') {
         memcpy ( library , pet->Module_Library, 10);
      }

      return  pPcml;
      // TODO !! pOpenAPI->ccsid = pet->Interface_Info_CCSID;
      /*

      printf ("Module : %10.10s \n" ,  pet->Module_Name);
      printf ("library: %10.10s \n" ,  pet->Module_library);
      printf ("ccsid  : %d \n" ,  pet->Interface_Info_CCSID);
      printf ("pcml   : %s \n" ,  pcml);
      */
      pet = (Qbn_Interface_Entry_t *) ((char *) pet + pet->Offset_Next_Entry);
   }
   return NULL;
}
/* --------------------------------------------------------------------------- *\
   Convert pcml to uniform json used for both programs and service programs
\* --------------------------------------------------------------------------- */
PJXNODE  jx_ApplicationMetaJson ( PUCHAR library , PUCHAR program , PUCHAR objectType)
{
   PJXNODE pResultObject;
   PJXNODE pPcml , pParmMeta , pParms, pParm, pLib, pProgram, pProcedure , pPcmlProgram , pPcmlParms;

   int     args;
   int     offset;
   UCHAR   tempPgm [11];
   UCHAR   tempLib [11];
   UCHAR   tempProc [256];

   if (objectType[1] == 'P') {
      pPcml = jx_ProgramMeta ( library , program );
   } else {
      pPcml = jx_ProcedureMeta ( library , program , "*ALL");
   }

   if (pPcml == NULL ) return NULL;

   pPcmlProgram = jx_GetNode  (pPcml , "/pcml/program");
   if (pPcmlProgram == NULL) {
      jx_NodeDelete (pPcml);
      return NULL;
   }

   pResultObject = jx_NewObject(NULL);
   pLib          = jx_NewObject(NULL);
   pProgram      = jx_NewObject(NULL);

   strtrimncpy ( tempPgm  , program , 10);
   strtrimncpy ( tempLib  , library , 10);

   while (pPcmlProgram) {
      PUCHAR  entrypoint     = parmMetaValue ( pPcmlProgram, "entrypoint");
      args = 0;
      offset = 0;

      pParms    = jx_NewArray (NULL);
      pParmMeta = jx_GetNode  (pPcmlProgram , "data");
      while (pParmMeta) {

         PUCHAR nodeType  = jx_GetNodeNamePtr (pParmMeta);
         PUCHAR name      = parmMetaValue ( pParmMeta, "name");
         PUCHAR type      = parmMetaValue ( pParmMeta, "type");
         PUCHAR length    = parmMetaValue ( pParmMeta, "length");
         PUCHAR usage     = parmMetaValue ( pParmMeta, "usage");
         PUCHAR precision = NULL;
         PUCHAR format    = NULL;
         PUCHAR separator = NULL;
         UCHAR  separatorChar = '.';
         UCHAR  dType;
         UCHAR  use      =  (0 == strcmp(usage , "inputoutput")) ? 'B' : 'I';

         int len = length ? atoi(length) : 0;
         int bufLen = len;

         // Struct? (No types no structs)
         if ( type == NULL ) {
            // Is it a varchar
            PJXNODE pChild1 = jx_GetNodeChild ( pParmMeta);
            PJXNODE pChild2 = jx_GetNodeNext  ( pChild1 );

            if ((pChild1 && pChild2)
            && ( 0 == strcmp (parmMetaValue ( pChild1, "name") ,"length")
            &&   0 == strcmp (parmMetaValue ( pChild2, "name") ,"string"))) {
               int lenlen = atoi(parmMetaValue ( pChild1, "length"));
               int size   = atoi(parmMetaValue ( pParmMeta, "outputsize"));
               dType = JX_DTYPE_VARCHAR;
               type = "varchar"; // Override the struct to varchar
               len = size - lenlen;
               precision = (lenlen == 2) ? "2" : "4";
               bufLen = size;
            } else {
               // Other struct -- TODO CALL
            }
         } else if ( 0 == strcmp ( type, "char")) {
            dType = JX_DTYPE_CHAR;
         //} else if ( 0 == strcmp ( type, "varchar")) {
         //   dType = JX_DTYPE_VARCHAR;
         } else if ( 0 == strcmp ( type, "int")) {
            dType = JX_DTYPE_INT;
         } else if ( 0 == strcmp ( type, "byte")) {
            dType = JX_DTYPE_BYTE;
         } else if ( 0 == strcmp ( type, "packed")) {
            dType = JX_DTYPE_PACKED;
            bufLen = (len + 1) / 2;
            precision= parmMetaValue ( pParmMeta, "precision");
         } else if ( 0 == strcmp ( type, "zoned")) {
            dType = JX_DTYPE_ZONED;
            precision= parmMetaValue ( pParmMeta, "precision");
         } else if ( 0 == strcmp ( type, "date")) {
            dType = JX_DTYPE_DATE;
            separator = parmMetaValue ( pParmMeta, "dateseparator");
            separatorChar = convertSeperator(separator);
            format = parmMetaValue ( pParmMeta, "dateformat");
            bufLen = 10 ; // TODO More?
         } else if ( 0 == strcmp ( type, "time")) {
            dType = JX_DTYPE_TIME;
            separator = parmMetaValue ( pParmMeta, "timeseparator");
            separatorChar = convertSeperator(separator);
            bufLen = 8 ;
         } else if ( 0 == strcmp ( type, "timestamp")) {
            dType = JX_DTYPE_TIME_STAMP;
            precision= parmMetaValue ( pParmMeta, "precision");
            if (precision == NULL) {
               bufLen = 26 ; // TODO -  Precision default room for zero term
            } else {
               bufLen = 20 + atoi(precision) ;
            }

         } else {
            dType = JX_DTYPE_UNKNOWN;
         }
         pParm = jx_NewObject (NULL);
         jx_SetValueByName(pParm  , "name"  , name   , VALUE);
         jx_SetValueByName(pParm  , "type"  , type   , VALUE);
         jx_SetCharByName (pParm  , "dType" , dType  , OFF);
         jx_SetCharByName (pParm  , "use"   , use    , OFF);
         jx_SetIntByName  (pParm  , "offset", offset , OFF);
         jx_SetIntByName  (pParm  , "buflen", bufLen , OFF);
         jx_SetIntByName  (pParm  , "length", len , OFF);
         if (precision) {
            jx_SetValueByName (pParm, "prec",  precision , LITERAL);
         }
         if (format) {
            jx_SetValueByName (pParm, "format",  format , VALUE);
         }
         if (separator) {
            jx_SetCharByName (pParm, "separator",  separatorChar , VALUE);
         }

         jx_ArrayPush ( pParms , pParm , FALSE);

         pParmMeta = jx_GetNodeNext(pParmMeta);
         offset += bufLen;
      }

      if (objectType[1] == 'P') { // *PGM
         jx_SetIntByName ( pProgram , "buflen", offset , OFF);
         jx_NodeMoveInto ( pProgram , "parms" , pParms);
      } else {
         pProcedure    = jx_NewObject(NULL);
         jx_SetIntByName ( pProcedure , "buflen", offset , OFF);
         jx_NodeMoveInto ( pProcedure , "parms" , pParms);
         strtrimncpy ( tempProc , entrypoint , PROC_NAME_MAX);
         jx_NodeMoveInto ( pProgram , tempProc, pProcedure);
      }

      pPcmlProgram = jx_GetNodeNext(pPcmlProgram);

   }

   jx_NodeMoveInto ( pLib          , tempPgm , pProgram);
   jx_NodeMoveInto ( pResultObject , tempLib , pLib);

   jx_NodeDelete (pPcml);
   return pResultObject;

}


/* --------------------------------------------------------------------------- *\
    Handler :
\* --------------------------------------------------------------------------- */
PJXNODE  jx_CallProgram (PUCHAR library , PUCHAR program, PJXNODE parmsP, ULONG optionsP)
{

   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   JXMETHOD pgm;
   PJXNODE pResult;

   PJXNODE parms   = (pParms->OpDescList->NbrOfParms >= 3 ) ? parmsP : NULL;
   ULONG   options = (pParms->OpDescList->NbrOfParms >= 4 ) ? optionsP : 0;

   memset ( &pgm , 0 , sizeof(pgm));
   strcpy(pgm.library   , library);
   strcpy(pgm.program   , program);
   pgm.pMetaNode  = jx_ProgramMeta(pgm.library, pgm.program);

   pgm.userMethodIsProgram = TRUE;
   pgm.userMethod = jx_loadProgram ( pgm.library, pgm.program);
   pResult = call (&pgm, parms , options);
   jx_NodeDelete( pgm.pMetaNode );
   return pResult;
}
/* --------------------------------------------------------------------------- *\
    Handler :
\* --------------------------------------------------------------------------- */
PJXNODE  jx_CallProcedure (PUCHAR library, PUCHAR srvPgm, PUCHAR procedure, PJXNODE parmsP, ULONG optionsP)
{

   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   JXMETHOD pgm;
   PJXNODE pResult;


   PJXNODE parms   = (pParms->OpDescList->NbrOfParms >= 4 ) ? parmsP : NULL;
   ULONG   options = (pParms->OpDescList->NbrOfParms >= 5 ) ? optionsP : 0;

   memset ( &pgm , 0 , sizeof(pgm));
   strtrimncpy (pgm.library   , library , 10);
   strtrimncpy (pgm.program   , srvPgm , 10);
   strtrimncpy (pgm.procedure , procedure , PROC_NAME_MAX );
   pgm.pMetaNode = jx_ApplicationMetaJson (pgm.library , pgm.program , pgm.procedure );
   pgm.userMethodIsProgram = FALSE;

   pgm.userMethod = jx_loadServiceProgramProc ( pgm.library, pgm.program , pgm.procedure);
   pResult = call (&pgm, parms , options);
   jx_NodeDelete( pgm.pMetaNode);
   return pResult;
}
