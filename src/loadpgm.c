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

   sprintf(srvPgm_ , "%-10.10s" , srvPgm);
   sprintf(lib_    , "%-10.10s" , lib);

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
   PJXNODE pParm , pOutParm , pInParm;
   PJXNODE pReturnObject;
   PJXNODE pParms;
   BOOL    freeAfter;
   UCHAR   parmbuffer [320000];
   PUCHAR  pParmBuffer = parmbuffer;
   SHORT   parmIx = 0;
   PVOID   argArray[256];
   SHORT   parmNum;
   UCHAR   rootNode [128];


   if ( pMethod->userMethodIsProgram) {
      strcpy ( rootNode , "/pcml/program/data"); // assume only PEP
   } else {
      sprintf ( rootNode ,  "/pcml/program%c%cname=%s%c/data",BraBeg , Masterspace, pMethod->procedure, BraEnd );
   }

   pOutParm = pInParm = pParm = jx_GetNode  (pMethod->pPcml , rootNode) ;

   if ((parms != NULL)
   &&  (parms->signature != NODESIG)) {
      pParms  = jx_ParseString ((PUCHAR) parms, "" );
      freeAfter = TRUE;
   } else {
      pParms  = parms;
      freeAfter = FALSE;
   }

   for (pInParm = pParm; pInParm ;  pInParm = jx_GetNodeNext(pInParm) ) {
      PUCHAR nodeType = jx_GetNodeNamePtr (pInParm);
      PUCHAR name   = parmMetaValue ( pInParm, "name");
      PUCHAR type   = parmMetaValue ( pInParm, "type");
      PUCHAR length = parmMetaValue ( pInParm, "length");
      PUCHAR usage  = parmMetaValue ( pInParm, "usage");
      int len = length ? atoi(length) : 0;
      int dtaLen, bufLen;
      PUCHAR pValue =  jx_GetNodeValuePtr(jx_GetNode  (pParms ,name),"") ;
      argArray [parmIx++] = pParmBuffer;

      if ( 0 == strcmp ( type, "char")) {
         padncpy ( pParmBuffer , pValue , len);
         pParmBuffer[len] = '\0'; // terminate for now
         bufLen = len+ 1 ; // room for zero term
      } else if ( 0 == strcmp ( type, "varchar")) {
         long actlen = strlen ( pValue );
         memcpy ( pParmBuffer  , pValue , actlen + 1); // include the zero term
         bufLen = len+ 1 ; // room for zero term
      } else if ( 0 == strcmp ( type, "int")) {
         switch (len) {
            case 8: *(long long *) pParmBuffer = atoll (pValue); break;
            case 4: *(long *) pParmBuffer = atol (pValue); break;
            case 2: *(int *) pParmBuffer = atoi (pValue); break;
            case 1: *(char *) pParmBuffer = atoi (pValue); break;
         }
         bufLen = len;
      } else if ( 0 == strcmp ( type, "byte")) {
         *(char *) pParmBuffer = atoi (pValue);
         bufLen = len ;
      } else if ( 0 == strcmp ( type, "packed")) {
         SHORT  precision = atoi(parmMetaValue ( pInParm, "precision"));
         str2packedMem ( pParmBuffer , pValue , len , precision);
         bufLen = (len + 1) / 2;
      } else if ( 0 == strcmp ( type, "zoned")) {
         SHORT  precision = atoi(parmMetaValue ( pInParm, "precision"));
         str2zonedMem ( pParmBuffer , pValue , len , precision);
         bufLen = len;
      } else if ( 0 == strcmp ( type, "date")) {
         PUCHAR format = parmMetaValue ( pInParm, "dateformat");
         convertDate ( pParmBuffer , pValue , format);
         bufLen = 11 ; // room for zero term
      } else if ( 0 == strcmp ( type, "time")) {
         memcpy ( pParmBuffer , "00.00.00", 9);
         memcpy ( pParmBuffer , pValue , strlen(pValue));
         bufLen = 9 ; // room for zero term
      } else if ( 0 == strcmp ( type, "timestamp")) {
         memcpy ( pParmBuffer , "0001-01-01-00.00.00.000000", 27);
         memcpy ( pParmBuffer , pValue , strlen(pValue));
         bufLen = 27 ; // room for zero term
      }

      pParmBuffer += bufLen;
   }

   if ( pMethod->userMethodIsProgram) {
      _CALLPGMV ( &pMethod->userMethod , argArray , parmIx );
   } else {
      jx_callProc (pMethod->userMethod , argArray , parmIx);
   }

   pReturnObject = jx_NewObject(NULL);
   parmIx= 0;
   for (pOutParm = pParm; pOutParm ;  pOutParm = jx_GetNodeNext(pOutParm), parmIx++ ) {
      PUCHAR usage  = parmMetaValue ( pOutParm, "usage");

      if (0 == strcmp(usage , "inputoutput")) {
         PUCHAR name   = parmMetaValue ( pOutParm, "name");
         PUCHAR type   = parmMetaValue ( pOutParm, "type");
         PUCHAR length = parmMetaValue ( pOutParm, "length");
         int len = length ? atoi(length) : 0;
         UCHAR temp [256];
         UCHAR data [256];
         PUCHAR pData = data;
         NODETYPE nodeType = VALUE;

         pParmBuffer = argArray [parmIx];
         if ( 0 == strcmp ( type, "char")) {
            pData = righttrimlen(pParmBuffer , len );
         } else if ( 0 == strcmp ( type, "varchar")) {
            substr (data  , pParmBuffer + 2 , *(short int *) pParmBuffer);
         } else if ( 0 == strcmp ( type, "packed")) {
            SHORT  precision = atoi(parmMetaValue ( pOutParm, "precision"));
            pData = fmtPacked(data  , pParmBuffer , len  , precision, '.');
            nodeType = LITERAL;
         } else if ( 0 == strcmp ( type, "int")) {
            switch (len) {
               case 8: sprintf ( data , "%lld" ,*(long long *) pParmBuffer); break;
               case 4: sprintf ( data , "%ld"  ,*(long *)      pParmBuffer); break;
               case 2: sprintf ( data , "%d"   ,*(short int *) pParmBuffer); break;
               case 1: sprintf ( data , "%d"   ,*(short int *) pParmBuffer); break; // check !!
            }
            nodeType = LITERAL;
         } else if ( 0 == strcmp ( type, "byte")) {
            sprintf ( data , "%d"   , 0 + pParmBuffer[0]);  // check !!
            nodeType = LITERAL;
         } else if ( 0 == strcmp ( type, "zoned")) {
            SHORT  precision = atoi(parmMetaValue ( pOutParm, "precision"));
            pData = fmtZoned (data  , pParmBuffer , len  , precision, '.');
            nodeType = LITERAL;
         } else if ( 0 == strcmp ( type, "date")) {
            PUCHAR format = parmMetaValue ( pOutParm, "DATEFORMAT");
            PUCHAR seprator = parmMetaValue ( pOutParm, "dateseparator");
            pData = fmtDate  ( data , pParmBuffer , format , convertSeperator(seprator));
         } else if ( 0 == strcmp ( type, "time")) {
            PUCHAR seprator = parmMetaValue ( pOutParm, "timeseparator"); // TODO
            pData = fmtTime  ( data , pParmBuffer , convertSeperator(seprator));
         } else if ( 0 == strcmp ( type, "timestamp")) {
            memcpy ( data  , "0001-01-01-00.00.00.000000", 27);
            memcpy ( data  , pParmBuffer , len == 0 ? 26 : len);
         }
         jx_SetValueByName( pReturnObject , str2lower (temp, name ) , pData , nodeType );
      }
   }

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

   memcpy ( libpgm      , Program , 10 );
   memcpy ( libpgm +10  , library , 10 );

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

   memcpy ( libpgm      , Program , 10 );
   memcpy ( libpgm +10  , library , 10 );

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
   pgm.pPcml = jx_ProgramMeta(library , program);
   strcpy(pgm.library   , library);
   strcpy(pgm.program   , program);

   pgm.userMethodIsProgram = TRUE;
   pgm.userMethod = jx_loadProgram ( library, program);
   pResult = call (&pgm, parms , options);
   jx_NodeDelete( pgm.pPcml);
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
   pgm.pPcml = jx_ProcedureMeta(library , srvPgm , procedure );
   pgm.userMethodIsProgram = FALSE;
   strcpy(pgm.library   , library);
   strcpy(pgm.program   , srvPgm);
   strcpy(pgm.procedure , procedure);

   pgm.userMethod = jx_loadServiceProgramProc ( library, srvPgm , procedure);
   pResult = call (&pgm, parms , options);
   jx_NodeDelete( pgm.pPcml);
   return pResult;
}
