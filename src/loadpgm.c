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
#include <mih/matptr.h>
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
#include "mem001.h"

#include "jsonxml.h"

extern UCHAR BraBeg;
extern UCHAR BraEnd;
extern UCHAR Masterspace;

//  local prototype:
static void  copyNodeIntoBuffer (PJXMETHODPARM pMethodParm , PUCHAR pParmBuffer , PJXNODE pParms  );

// -------------------------------------------------------------
void getLibraryForSysPtr (_SYSPTR proc, UCHAR * lib)
{
   _MPTR_Template_T op;
   op.Obj_Ptr.Template_Size = sizeof(op);
   matptr (&op, proc);
   memcpy (lib , &op.Obj_Ptr.Library_ID.Name , 10);
}

/* ------------------------------------------------------------- */
_SYSPTR jx_loadServiceProgram (PUCHAR lib , PUCHAR srvPgm)
{
   UCHAR srvPgm_  [11];
   UCHAR lib_     [11];
   _SYSPTR pgm;

   sprintf(srvPgm_ ,"%-10.10s", srvPgm);
   sprintf(lib_    ,"%-10.10s", lib);

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
/* ------------------------------------------------------------- */

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
/* ------------------------------------------------------------- */

static PUCHAR fmtDate ( PUCHAR pOut, PUCHAR pIn , PUCHAR pFormat )
{
   if (0 == strcmp ( pFormat , "ISO")) {
      substr (pOut, pIn , 10 ); // noxDb is always in ISO
   } else if (0 == strcmp ( pFormat , "EUR")) { // DD/MM/YYYY to YYYY-MM-DD
      memcpy ( pOut + 0 , pIn +6 , 4); // YYYY
      memcpy ( pOut + 5 , pIn +3 , 2); // MM
      memcpy ( pOut + 8 , pIn +0 , 2); // DD
      pOut[2] = pOut[5] = '-';
      pOut[10] = '\0';
   } // todo  - more to come
   else {
      substr (pOut, pIn , 10 ); // noxDb is always in ISO
   }
   return pOut;
}
/* ------------------------------------------------------------- */

static PUCHAR fmtTime ( PUCHAR pOut, PUCHAR pIn )
{
   substr  (pOut , pIn , 8);
   pOut[2] = pOut[5] = '.';
   return pOut;
}
/* ------------------------------------------------------------- */
static UCHAR convertSeperator (PUCHAR pSeprator)
{
   if (pSeprator == NULL) {
      return '\0';
   } else if (0 == strcmp ( pSeprator , "hyphen")) {
      return '-';
   } else if (0 == strcmp ( pSeprator , "period")) {
      return '.';
   } else if (0 == strcmp ( pSeprator , "slash")) {
      return '/';
   } else if (0 == strcmp ( pSeprator , "blank")) {
      return ' ';
   } else {
      return '-'; // default !!
   }
}
/* ------------------------------------------------------------- */
static PUCHAR parmMetaValue (PJXNODE pNode , PUCHAR key)
{
   PUCHAR value = jx_GetAttrValuePtr ( jx_AttributeLookup (  pNode, key));
   if (value) {
      return value;
   } else {
      return "";
   }
}
/* ------------------------------------------------------------- */
static int  parmMetaValueInt (PJXNODE pNode , PUCHAR key, int dftvalue)
{
   PUCHAR value = jx_GetAttrValuePtr ( jx_AttributeLookup (  pNode, key));
   if (value) {
      return atoi(value);
   } else {
      return dftvalue;
   }
}
/* ------------------------------------------------------------- */
static int min(int a, int b)
{
   return (a<b) ? a : b;
}
/* ------------------------------------------------------------- */
static PJXMETHODPARM getParmDefinition( PJXNODE pNode)
{
   return (PJXMETHODPARM) jx_GetValuePtr  (pNode , "def" , NULL);
}
/* ------------------------------------------------------------- */
static void copyValueIntoBuffer(PJXMETHODPARM pMethodParm , PUCHAR pBuf, PUCHAR  pValue )
{

   switch (pMethodParm->dType) {
      case JX_DTYPE_CHAR: {
         // Boolean Hack for backwards compability (PCML-V7)
         if (pMethodParm->length == 1 && (0 == strcmp(pValue, "false") || 0 == strcmp(pValue, "true"))) {
            *(PUCHAR) pBuf = (*pValue == 'f') ? '0' : '1';
         } else {
            padncpy ( pBuf, pValue , pMethodParm->length);
         }
         break;
      }
      case JX_DTYPE_VARCHAR: {
         ULONG actlen = min(strlen (pValue), pMethodParm->length);
         if (pMethodParm->precision == 4) {
            *(PULONG)  pBuf = actlen;
         } else {
            *(PUSHORT) pBuf = actlen;
         }
         memcpy ( pBuf + pMethodParm->precision, pValue , actlen); // include the zero term
         break;
      }

      case JX_DTYPE_INT: {
         str2integerMem ( pBuf  , pValue , pMethodParm->length, pMethodParm->precision);
         break;
      }
      case JX_DTYPE_BYTE: {
         *(PUCHAR) pBuf = atoi (pValue);
         break;
      }
      case JX_DTYPE_PACKED: {
         str2packedMem ( pBuf  , pValue , pMethodParm->length, pMethodParm->precision);
         break;
      }
      case JX_DTYPE_ZONED: {
         str2zonedMem ( pBuf , pValue , pMethodParm->length, pMethodParm->precision);
         break;
      }
      case JX_DTYPE_DATE: {
         convertDate  ( pBuf , pValue , pMethodParm->format);
         break;
      }
      case JX_DTYPE_TIME: {
         memcpy ( pBuf , "00.00.00", 8);
         memcpy ( pBuf , pValue , min(strlen(pValue), pMethodParm->length));
         break;
      }
      case JX_DTYPE_TIME_STAMP: {
         memcpy ( pBuf , "0001-01-01-00.00.00.000000000", pMethodParm->length);
         memcpy ( pBuf , pValue , min(strlen(pValue), pMethodParm->length));
         break;
      }
      case JX_DTYPE_BOOL: {
         *(PUCHAR) pBuf = (*pValue == '\0' || *pValue == '0' || *pValue == 'f') ? '0' : '1';
         break;
      }
      case JX_DTYPE_UNKNOWN: {
         break;
      }
   }
}
static void  copyArrayIntoBuffer (PJXMETHODPARM pMethodParm , PUCHAR pParmBuffer , PJXNODE pParms)
{
   PJXNODE pArray =  jx_GetNode   (pParms , pMethodParm->name);
   pArray = (jx_GetNodeType (pArray) == ARRAY) ? jx_GetNodeChild (pArray) :  NULL;

   if (pMethodParm->dType == JX_DTYPE_STRUCTURE) {
      for (int i=0; i < pMethodParm->dim ; i++) {
         PJXNODE pStructParm = jx_GetNode ( pArray , pMethodParm->name);
         PJXNODE pStructObj = jx_GetNodeChild(pMethodParm->pStructure);
         while (pStructObj) {
            PJXMETHODPARM pDef = getParmDefinition (pStructObj);
            copyNodeIntoBuffer ( pDef , pParmBuffer + pDef->offset , pStructParm);
            pStructObj = jx_GetNodeNext(pStructObj);
         }
      }
   } else {
      for (int i=0; i < pMethodParm->dim ; i++) {
         PUCHAR pValue  = jx_GetNodeValuePtr (pArray,"");
         copyValueIntoBuffer(pMethodParm , pParmBuffer, pValue );
         pParmBuffer += pMethodParm->size;
         pArray = jx_GetNodeNext(pArray);
      }
   }
}
static void  copyNodeIntoBuffer (PJXMETHODPARM pMethodParm , PUCHAR pParmBuffer , PJXNODE pParms  )
{
   if (pMethodParm->dim > 0) {
      copyArrayIntoBuffer (pMethodParm , pParmBuffer , pParms);
   } else {

      if (pMethodParm->dType == JX_DTYPE_STRUCTURE) {
         PJXNODE pStructParm = jx_GetNode ( pParms , pMethodParm->name);
         PJXNODE pStructObj = jx_GetNodeChild(pMethodParm->pStructure);
         while (pStructObj) {
            PJXMETHODPARM pDef = getParmDefinition (pStructObj);
            copyNodeIntoBuffer ( pDef , pParmBuffer + pDef->offset , pStructParm);
            pStructObj = jx_GetNodeNext(pStructObj);
         }
      } else {
         PUCHAR pValue  = jx_GetValuePtr   (pParms , pMethodParm->name , "");
         copyValueIntoBuffer(pMethodParm , pParmBuffer, pValue );
      }
   }
}
static int buildArgBufferArray (PJXMETHOD pMethod, PJXNODE pParms, PVOID argArray [256] , PUCHAR * ppArgBuffer)
{

   int args = 0;
   ULONG   bufTotlen;
   PUCHAR  pParmBuffer;
   PJXNODE pInterface, pParmObj;

   pInterface = (pMethod->pProc == NULL) ? pMethod->pPgm : pMethod->pProc;
   bufTotlen =  atol(jx_GetValuePtr  (pInterface , "buflen" , "0")) ;

   pParmBuffer = memAlloc (bufTotlen);
   memset ( pParmBuffer , '\0',  bufTotlen);
   *ppArgBuffer = pParmBuffer;

   pParmObj = jx_GetNodeChild(jx_GetNode ( pInterface , "parms"));
   while (pParmObj) {
      PJXMETHODPARM pMethodParm = getParmDefinition (pParmObj);
      PUCHAR pBuf = pParmBuffer + pMethodParm->offset;
      argArray [args++] = pBuf;
      copyNodeIntoBuffer (pMethodParm , pBuf, pParms);
      pParmObj = jx_GetNodeNext(pParmObj);
   }
   return args;
}

static PJXNODE newReturnNode (PJXMETHODPARM pMethodParm, PUCHAR pParmBuffer )
{

   UCHAR data [32000]; // TODO - dynamic size

   switch (pMethodParm->dType) {
      case JX_DTYPE_STRUCTURE: {
         break;
      }
      case JX_DTYPE_CHAR: {
         strrighttrimncpy(data ,pParmBuffer , pMethodParm->length );
         break;
      }
      case JX_DTYPE_VARCHAR: {
         int actlen =  (pMethodParm->precision == 4) ? *(PULONG) pParmBuffer : *(PUSHORT) pParmBuffer ;
         substr (data  , pParmBuffer + pMethodParm->precision ,actlen);
         break;
      }
      case JX_DTYPE_BYTE: {
         USHORT i = *(PUCHAR) pParmBuffer;
         sprintf ( data , "%hd" , *pParmBuffer);
         break;
      }
      case JX_DTYPE_INT: {
         BOOL isSigned = (pMethodParm->precision % 2 != 0) ? TRUE : FALSE;
         fmtInteger (data , pParmBuffer , pMethodParm->length , isSigned );
         break;
      }
      case JX_DTYPE_PACKED: {
         fmtPacked(data  , pParmBuffer , pMethodParm->length  , pMethodParm->precision , '.');
         break;
      }
      case JX_DTYPE_ZONED: {
         fmtZoned (data  , pParmBuffer , pMethodParm->length  , pMethodParm->precision, '.');
         break;
      }
      case JX_DTYPE_DATE: {
         fmtDate  ( data , pParmBuffer , pMethodParm->format);
         break;
      }
      case JX_DTYPE_TIME: {
         fmtTime  ( data , pParmBuffer);
         break;
      }
      case JX_DTYPE_TIME_STAMP: {
         substr  ( data  ,  pParmBuffer , pMethodParm->length);
         break;
      }
      case JX_DTYPE_BOOL: {
         strcpy ( data , (*pParmBuffer == '1') ? "true" : "false");
         break;
      }
      case JX_DTYPE_UNKNOWN: {
         break;
      }
   }
   return jx_NewNode(pMethodParm->name , data , pMethodParm->graphDataType );

}
/* ------------------------------------------------------------- */
/* TODO only work one level !!! */
/* ------------------------------------------------------------- */
static void  setReturnObject (PJXNODE pReturnObject, PJXMETHODPARM pMethodParm , PUCHAR pParmBuffer )
{
   if (pMethodParm->dType == JX_DTYPE_STRUCTURE) {
      PJXNODE pReturnStruct = jx_NewObject(NULL);
      PJXNODE pStructObj = jx_GetNodeChild(pMethodParm->pStructure);
      while (pStructObj) {
         PJXMETHODPARM pStructParm = getParmDefinition (pStructObj);
         setReturnObject ( pReturnStruct , pStructParm, pParmBuffer + pStructParm->offset);
         pStructObj = jx_GetNodeNext(pStructObj);
      }
      jx_NodeMoveInto (pReturnObject , pMethodParm->name , pReturnStruct);
   } else if (pMethodParm->dim > 0) {
      PJXNODE pReturnArray = jx_NewArray(NULL);
      for (int i = 0 ; i< pMethodParm->dim ; i++) {
         jx_ArrayPush ( pReturnArray , newReturnNode (pMethodParm,  pParmBuffer),FALSE);
         pParmBuffer += pMethodParm->size;
      }
      jx_NodeMoveInto (pReturnObject , pMethodParm->name , pReturnArray);
   } else {
      jx_NodeMoveInto (pReturnObject , pMethodParm->name  , newReturnNode (pMethodParm,  pParmBuffer));
   }
}
/* ------------------------------------------------------------- */
static PJXNODE buildReturnObject (PJXMETHOD  pMethod, PJXNODE pParms, PVOID argArray [256], int args)
{
   int argIx= 0;
   PJXNODE pInterface, pParmObj;
   PJXNODE pReturnObject = jx_NewObject(NULL);

   pInterface = (pMethod->pProc == NULL) ? pMethod->pPgm : pMethod->pProc;

   pParmObj = jx_GetNodeChild(jx_GetNode ( pInterface , "parms"));
   while (pParmObj) {
      PJXMETHODPARM pMethodParm = getParmDefinition (pParmObj);
      if (pMethodParm->use == 'B') { // BOTH .. TODO in enum
         setReturnObject (pReturnObject , pMethodParm,  argArray [argIx]);
      }
      argIx++;
      pParmObj = jx_GetNodeNext(pParmObj);
   }

   return pReturnObject;
}

/* --------------------------------------------------------------------------- *\
<?xml version="1.0" encoding="UTF-8" ?>
<pcml version="8.0">
  <struct name="employee_t">
    <data name="id" type="int" length="4" precision="31" usage="inherit"/>
    <data name="name" type="char" length="50" usage="inherit"/>
    <data name="age" type="int" length="4" precision="31" usage="inherit"/>
    <data name="income" type="packed" length="9" precision="2" usage="inherit"/>
    <data name="birthDate" type="date" dateformat="ISO" dateseparator="hyphen" usage="inherit"/>
    <data name="birthTime" type="time" timeformat="ISO" timeseparator="period" usage="inherit"/>
    <data name="updated" type="timestamp" usage="inherit"/>
    <data name="isMale" type="char" length="1" boolean="true" usage="inherit"/>
  </struct>
  <program name="complex" entrypoint="COMPLEX">
    <data name="id" type="int" length="4" precision="31" usage="input"/>
    <data name="employee" type="struct" struct="employee_t" usage="inputoutput"/>
  </program>
  <program name="allTypes" entrypoint="ALLTYPES">
    <data name="char" type="char" length="10" usage="inputoutput"/>
    <data name="varchar" type="varchar" length="10" usage="inputoutput"/>
    <data name="int8" type="int" length="8" precision="63" usage="inputoutput"/>
    <data name="int4" type="int" length="4" precision="31" usage="inputoutput"/>
    <data name="uns8" type="int" length="8" precision="64" usage="inputoutput"/>
    <data name="uns4" type="int" length="4" precision="32" usage="inputoutput"/>
    <data name="uns2" type="byte" length="1" usage="inputoutput"/>
    <data name="packed" type="packed" length="9" precision="2" usage="inputoutput"/>
    <data name="zoned" type="zoned" length="9" precision="2" usage="inputoutput"/>
    <data name="ind" type="char" length="1" boolean="true" usage="inputoutput"/>
    <data name="date" type="date" dateformat="ISO" dateseparator="hyphen" usage="inputoutput"/>
    <data name="time" type="time" timeformat="ISO" timeseparator="period" usage="inputoutput"/>
    <data name="timestamp" type="timestamp" usage="inputoutput"/>
  </program>
  <program name="nameAge" entrypoint="NAMEAGE">
    <data name="Name" type="char" length="10" usage="input"/>
    <data name="Text" type="char" length="200" usage="inputoutput"/>
    <data name="Age" type="packed" length="5" precision="0" usage="inputoutput"/>
  </program>
</pcml>\* --------------------------------------------------------------------------- */

/* --------------------------------------------------------------------------- *\
    Call the plain program resolved by the system pointer:
\* --------------------------------------------------------------------------- */
static PJXNODE  call    (PJXMETHOD pMethod , PJXNODE parms, ULONG options)
{
   PJXNODE pReturnObject;
   PJXNODE pParms;
   BOOL    freeAfter;
   PUCHAR  pArgBuffer;
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

   args = buildArgBufferArray ( pMethod, pParms, argArray, &pArgBuffer);

   if ( pMethod->userMethodIsProgram) {
      jx_callPgm ( pMethod->userMethod , argArray , args );
   } else {
      jx_callProc (pMethod->userMethod , argArray , args);
   }

   pReturnObject = buildReturnObject (pMethod, pParms, argArray, args);

   memFree (&pArgBuffer);

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

   // would yield QTEMP - where it is build
   // if (*library == '*') {
   //    memcpy ( library , pet->Module_Library, 10);
   // }

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

      // would yield QTEMP - where it is build
      // if (*library == '*') {
      //    memcpy ( library , pet->Module_Library, 10);
      // }

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
JX_DTYPE convertDataType (PUCHAR type)
{
   if (type == NULL) {
      return JX_DTYPE_UNKNOWN;
   } else if (0 == strcmp(type , "char")) {
      return JX_DTYPE_CHAR;
   } else if (0 == strcmp(type , "packed")) {
      return JX_DTYPE_PACKED;
   } else if (0 == strcmp(type , "zoned")) {
      return JX_DTYPE_ZONED;
   } else if (0 == strcmp(type , "varchar")) {
      return JX_DTYPE_VARCHAR;
   } else if (0 == strcmp(type , "date")) {
      return JX_DTYPE_DATE;
   } else if (0 == strcmp(type , "time")) {
      return JX_DTYPE_TIME;
   } else if (0 == strcmp(type , "timestamp")) {
      return JX_DTYPE_TIME_STAMP;
   } else if (0 == strcmp(type , "int")) {
      return JX_DTYPE_INT;
   } else if (0 == strcmp(type , "byte")) {
      return JX_DTYPE_BYTE;
   } else if (0 == strcmp(type , "struct")) {
      return JX_DTYPE_STRUCTURE;
   } else {
      return JX_DTYPE_UNKNOWN;
   }
}

/* --------------------------------------------------------------------------- *\
   Create a new method parameter object
\* --------------------------------------------------------------------------- */
PJXMETHODPARM newMethodParm ( PJXNODE pParmMeta)
{
   PUCHAR p;
   PJXMETHODPARM pMethodParm  = memAlloc (sizeof(JXMETHODPARM));
   memset (pMethodParm , 0, sizeof(JXMETHODPARM));
   strcpy(pMethodParm->name , parmMetaValue ( pParmMeta, "name"));
   //  TODO !! Cater for PCML version before 7.0
   // if (0 == strcmp("struct" ,jx_GetNodeNamePtr (pParmMeta))) {
   //   pMethodParm->dType = JX_DTYPE_STRUCTURE;
   //} else {
   if (*parmMetaValue ( pParmMeta, "boolean") == 't') { // short for "true"
      pMethodParm->dType  = JX_DTYPE_BOOL;
   } else {
      pMethodParm->dType  = convertDataType(parmMetaValue ( pParmMeta, "type"));
   }
   pMethodParm->use       =  (0 == strcmp(parmMetaValue ( pParmMeta, "usage") , "inputoutput")) ? 'B' : 'I';
   pMethodParm->length    =  parmMetaValueInt ( pParmMeta, "length", 0);
   pMethodParm->precision = parmMetaValueInt ( pParmMeta, "precision", 0);
   pMethodParm->dim       = parmMetaValueInt ( pParmMeta, "count", 0);
   // pMethodParm->format    = NULL;
   // pMethodParm->separator = NULL;
   // pMethodParm->separatorChar = '.';
   // pMethodParm->dType     = '?';
   pMethodParm->size      = pMethodParm->length;
   pMethodParm->graphDataType = VALUE;
   return pMethodParm;
}
PJXNODE buildMethodParmObject ( PJXMETHODPARM pMethodParm)
{
   PJXNODE  pParmObject = jx_NewObject (NULL);
   jx_SetValueByName(pParmObject  , "name"  , pMethodParm->name   , VALUE);
   jx_SetCharByName (pParmObject  , "type"  , pMethodParm->dType  , OFF);
   jx_SetCharByName (pParmObject  , "use"   , pMethodParm->use    , OFF);
   jx_SetIntByName  (pParmObject  , "offset", pMethodParm->offset , OFF);
   jx_SetIntByName  (pParmObject  , "size"  , pMethodParm->size , OFF);
   jx_SetIntByName  (pParmObject  , "length", pMethodParm->length , OFF);
   jx_SetIntByName  (pParmObject  , "prec" ,  pMethodParm->precision, OFF);
   if (*pMethodParm->format) {
      jx_SetValueByName(pParmObject  , "format", pMethodParm->format   , VALUE);
   }
   if (pMethodParm->separatorChar) {
      jx_SetCharByName (pParmObject  , "separator",  pMethodParm->separatorChar , VALUE);
   }
   if (pMethodParm->dim > 0) {
      jx_SetIntByName  (pParmObject  , "dim" ,  pMethodParm->dim, OFF);
   }
   jx_SetValueByName(pParmObject  , "def" , (PUCHAR) pMethodParm  , NOXDB_POINTER);
   if (pMethodParm->pStructure) {
      jx_SetValueByName(pParmObject  , "struct" , (PUCHAR) pMethodParm->pStructure  , NOXDB_SUBGRAPH);
   }


   return pParmObject;
}
PJXNODE buildParmElements(PJXNODE pPcmlProgram, PSHORT offset, PJXNODE pProgram)
{

   PJXNODE pParms    = jx_NewArray (NULL);
   PJXNODE pParmMeta = jx_GetNode  (pPcmlProgram , "data");
   while (pParmMeta) {
      PJXNODE     pParm;
      PJXMETHODPARM pMethodParm = newMethodParm ( pParmMeta);

      switch ( pMethodParm->dType) {

         case JX_DTYPE_STRUCTURE: {
            // Is it a varchar
            PJXNODE pChild1 = jx_GetNodeChild ( pParmMeta);
            PJXNODE pChild2 = jx_GetNodeNext  ( pChild1 );

            if ((pChild1 && pChild2)
            && ( 0 == strcmp (parmMetaValue ( pChild1, "name") ,"length")
            &&   0 == strcmp (parmMetaValue ( pChild2, "name") ,"string"))) {
               pMethodParm->dType = JX_DTYPE_VARCHAR;
               pMethodParm->precision = parmMetaValueInt ( pChild1, "length", 2);
               pMethodParm->size = parmMetaValueInt ( pParmMeta, "outputsize", 0);
               pMethodParm->length = pMethodParm->size - pMethodParm->precision;
            } else {
               UCHAR nodeName [256];
               sprintf ( nodeName , "__structs__/%s", parmMetaValue ( pParmMeta , "struct"));
               pMethodParm->pStructure  = jx_GetNode  (pProgram , nodeName);
               pMethodParm->length = 0;
               for (PJXNODE pElements = jx_GetNodeChild ( pMethodParm->pStructure ) ; pElements ; pElements =  jx_GetNodeNext  (pElements )) {
                  pMethodParm->length += atoi(jx_GetValuePtr (pElements, "size", "0"));
               }
               pMethodParm->size = (pMethodParm->dim > 0) ? pMethodParm->dim * pMethodParm->length : pMethodParm->length;
            }
            break;
         }
         case JX_DTYPE_CHAR:{
            pMethodParm->graphDataType = VALUE;
            break;
         }
         case JX_DTYPE_VARCHAR: {
            pMethodParm->graphDataType = VALUE;
            if (pMethodParm->precision == 0) {
               pMethodParm->precision = 2;
            }
            pMethodParm->size = pMethodParm->precision + pMethodParm->length;
            break;
         }
         case JX_DTYPE_INT:
         case JX_DTYPE_BYTE:
         case JX_DTYPE_BOOL:
         case JX_DTYPE_ZONED: {
            pMethodParm->graphDataType = LITERAL;
            break;
         }
         case JX_DTYPE_PACKED: {
            pMethodParm->graphDataType = LITERAL;
            pMethodParm->size = (pMethodParm->length + 1) / 2;
            break;
         }
         case JX_DTYPE_DATE:  {
            strcpy ( pMethodParm->format , parmMetaValue ( pParmMeta, "dateformat"));
            pMethodParm->graphDataType = VALUE;
            pMethodParm->separatorChar = convertSeperator(
               parmMetaValue ( pParmMeta, "dateseparator")
            );
            pMethodParm->length = pMethodParm->size  = 10 ; // TODO More?
            break;
         }

         case JX_DTYPE_TIME:  {
            strcpy ( pMethodParm->format , parmMetaValue ( pParmMeta, "timeformat"));
            pMethodParm->graphDataType = VALUE;
            pMethodParm->separatorChar = convertSeperator(
               parmMetaValue ( pParmMeta, "timeseparator")
            );
            pMethodParm->length = pMethodParm->size = 8 ;
            break;
         }
         case JX_DTYPE_TIME_STAMP: {
            if ( *parmMetaValue ( pParmMeta, "precision") == '\0') {
               pMethodParm->precision = 6;
            }
            pMethodParm->length = 20 + pMethodParm->precision;
            pMethodParm->size = pMethodParm->length;
            break;
         }

         default:
            pMethodParm->graphDataType = VALUE;
      }

      pMethodParm->offset = *offset;

      pParm = buildMethodParmObject (pMethodParm);

      jx_ArrayPush ( pParms , pParm , FALSE);

      pParmMeta = jx_GetNodeNext(pParmMeta);
      if (pMethodParm->dim > 0) {
         *offset += pMethodParm->size * pMethodParm->dim;
      } else {
         *offset += pMethodParm->size;
      }
   }
   return pParms;
}
/* --------------------------------------------------------------------------- *\
   Load all complex (if any) datatypes and make a __structs__ node
\* --------------------------------------------------------------------------- */
void buildStructures ( PJXNODE pProgram , PJXNODE pPcml)
{
   PJXNODE pPcmlStruct = jx_GetNode  (pPcml , "/pcml/struct");
   if (pPcmlStruct) {

      PJXNODE pStructs  = jx_NewObject(NULL);

      while ( pPcmlStruct && 0==strcmp(jx_GetNodeNamePtr(pPcmlStruct),"struct")) {
         PUCHAR  structureName = parmMetaValue ( pPcmlStruct, "name");
         SHORT   offset = 0;
         PJXNODE pElements = buildParmElements(pPcmlStruct , &offset , pProgram);
         jx_NodeMoveInto (pStructs, structureName, pElements );
         pPcmlStruct = jx_GetNodeNext(pPcmlStruct);
      }
      jx_NodeMoveInto (pProgram, "__structs__", pStructs );
   }
}
/* --------------------------------------------------------------------------- *\
   Convert pcml to uniform json used for both programs and service programs
\* --------------------------------------------------------------------------- */
PJXNODE  jx_ApplicationMetaJson ( PUCHAR library , PUCHAR program , PUCHAR objectType)
{
   PJXNODE pResultObject, pPcml , pParmMeta , pLib, pProgram, pProcedure , pPcmlProgram , pPcmlParms;

   UCHAR   tempPgm [11];
   UCHAR   tempLib [11];
   UCHAR   tempProc [256];

   if (objectType[1] == 'P') {
      if ( *library == '*' ) {
         _SYSPTR pPgm = jx_loadProgram (library, program);
         getLibraryForSysPtr ( pPgm , library);
      }
      pPcml = jx_ProgramMeta ( library , program );
   } else {
      if ( *library == '*' ) {
         _SYSPTR pPgm = jx_loadServiceProgram (library, program);
         getLibraryForSysPtr ( pPgm , library);
      }
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

   buildStructures ( pProgram , pPcml);


   while (pPcmlProgram && 0==strcmp(jx_GetNodeNamePtr(pPcmlProgram),"program")) {
      PUCHAR  procedureName     = parmMetaValue ( pPcmlProgram, "name");
      SHORT   offset = 0;
      PJXNODE pParms = buildParmElements(pPcmlProgram , &offset, pProgram);

      if (objectType[1] == 'P') { // *PGM
         jx_SetIntByName ( pProgram , "buflen", offset , OFF);
         jx_NodeMoveInto ( pProgram , "parms" , pParms);
      } else {
         pProcedure    = jx_NewObject(NULL);
         jx_SetIntByName ( pProcedure , "buflen", offset , OFF);
         jx_NodeMoveInto ( pProcedure , "parms" , pParms);
         strtrimncpy ( tempProc , procedureName , PROC_NAME_MAX);
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
   strtrimncpy (pgm.library   , library , 10);
   strtrimncpy (pgm.program   , program  , 10);
   strtrimncpy (pgm.procedure , "*PGM" , PROC_NAME_MAX );
   pgm.userMethod = jx_loadProgram ( pgm.library, pgm.program);
   pgm.pMetaNode  = jx_ApplicationMetaJson (pgm.library , pgm.program , pgm.procedure );
   pgm.userMethodIsProgram = TRUE;
   pgm.pLib  = jx_GetNode(pgm.pMetaNode , pgm.library);
   pgm.pPgm  = jx_GetNode(pgm.pLib      , pgm.program);
   pgm.pProc = NULL;

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

   pgm.userMethod = jx_loadServiceProgramProc ( pgm.library, pgm.program , pgm.procedure);
   pgm.pMetaNode  = jx_ApplicationMetaJson (pgm.library , pgm.program , pgm.procedure );
   pgm.userMethodIsProgram = FALSE;
   pgm.pLib  = jx_GetNode(pgm.pMetaNode , pgm.library);
   pgm.pPgm  = jx_GetNode(pgm.pLib      , pgm.program);
   pgm.pProc = jx_GetNode(pgm.pPgm      , pgm.procedure);

   pResult = call (&pgm, parms , options);
   jx_NodeDelete( pgm.pMetaNode);
   return pResult;
}
