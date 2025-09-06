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
static void  copyNodeIntoBuffer (PUCHAR pParmBuffer ,PJXPARMMETA pParentMeta , PJXPARMMETA pMeta, PNOXNODE pParmValueNode );


// -------------------------------------------------------------
void getLibraryForSysPtr (_SYSPTR proc, UCHAR * lib)
{
   _MPTR_Template_T op;
   op.Obj_Ptr.Template_Size = sizeof(op);
   matptr (&op, proc);
   memcpy (lib , &op.Obj_Ptr.Library_ID.Name , 10);
}

/* ------------------------------------------------------------- */
_SYSPTR nox_loadServiceProgram (PUCHAR lib , PUCHAR srvPgm)
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
_SYSPTR nox_loadProc (_SYSPTR srvPgm ,  PUCHAR procName)
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
_SYSPTR nox_loadServiceProgramProc (PUCHAR lib , PUCHAR srvPgm, PUCHAR procName)
{
    _SYSPTR pgm = nox_loadServiceProgram (lib , srvPgm);
    return nox_loadProc (pgm, procName);
}
/* ------------------------------------------------------------- */
_SYSPTR nox_loadProgram (PUCHAR lib , PUCHAR pgm)
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
#pragma conver(1252)
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
#pragma conver(0)
/* ------------------------------------------------------------- */
#pragma conver(1252)
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
#pragma conver(0)
/* ------------------------------------------------------------- */
#pragma conver(1252)
static PUCHAR fmtTime ( PUCHAR pOut, PUCHAR pIn )
{
   substr  (pOut , pIn , 8);
   pOut[2] = pOut[5] = '.';
   return pOut;
}
#pragma conver(0)
/* ------------------------------------------------------------- */
#pragma conver(1252)
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
#pragma conver(0)
/* ------------------------------------------------------------- */
static PUCHAR parmMetaValue (PNOXNODE pNode , PUCHAR key)
{
   PUCHAR value = nox_GetAttrValuePtr ( nox_AttributeLookup (  pNode, key));
   if (value) {
      return value;
   } else {
      return "";
   }
}
/* ------------------------------------------------------------- */
static int  parmMetaValueInt (PNOXNODE pNode , PUCHAR key, int dftvalue)
{
   PUCHAR value = nox_GetAttrValuePtr ( nox_AttributeLookup (  pNode, key));
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
#pragma conver(1252)
static PJXPARMMETA getParmDefinition( PNOXNODE pNode)
{
   return (PJXPARMMETA) nox_GetNodeAttrValuePtr  (pNode , "def" , NULL);
}
#pragma conver(0)
/* ------------------------------------------------------------- */
#pragma conver(1252)
static void copyValueIntoBuffer(PUCHAR pBuf, PJXPARMMETA pMethodParm , PUCHAR  pValue )
{

   switch (pMethodParm->dType) {
      case NOX_DTYPE_CHAR: {
         // Boolean Hack for backwards compability (PCML-V7)
         if (pMethodParm->length == 1 && (0 == strcmp(pValue, "false") || 0 == strcmp(pValue, "true"))) {
            *(PUCHAR) pBuf = (*pValue == 'f') ? '0' : '1';
         } else {
            padncpy ( pBuf, pValue , pMethodParm->length);
         }
         break;
      }
      case NOX_DTYPE_VARCHAR: {
         ULONG actlen = min(strlen (pValue), pMethodParm->length);
         if (pMethodParm->precision == 4) {
            *(PULONG)  pBuf = actlen;
         } else {
            *(PUSHORT) pBuf = actlen;
         }
         memcpy ( pBuf + pMethodParm->precision, pValue , actlen); // include the zero term
         break;
      }

      case NOX_DTYPE_INT: {
         str2integerMem ( pBuf  , pValue , pMethodParm->length, pMethodParm->precision);
         break;
      }
      case NOX_DTYPE_BYTE: {
         *(PUCHAR) pBuf = atoi (pValue);
         break;
      }
      case NOX_DTYPE_PACKED: {
         str2packedMem ( pBuf  , pValue , pMethodParm->length, pMethodParm->precision);
         break;
      }
      case NOX_DTYPE_ZONED: {
         str2zonedMem ( pBuf , pValue , pMethodParm->length, pMethodParm->precision);
         break;
      }
      case NOX_DTYPE_DATE: {
         convertDate  ( pBuf , pValue , pMethodParm->format);
         break;
      }
      case NOX_DTYPE_TIME: {
         memcpy ( pBuf , "00.00.00", 8);
         memcpy ( pBuf , pValue , min(strlen(pValue), pMethodParm->length));
         break;
      }
      case NOX_DTYPE_TIME_STAMP: {
         memcpy ( pBuf , "0001-01-01-00.00.00.000000000", pMethodParm->length);
         memcpy ( pBuf , pValue , min(strlen(pValue), pMethodParm->length));
         break;
      }
      case NOX_DTYPE_BOOL: {
         *(PUCHAR) pBuf = (*pValue == '\0' || *pValue == '0' || *pValue == 'f') ? '0' : '1';
         break;
      }
      case NOX_DTYPE_UNKNOWN: {
         break;
      }
   }
}
#pragma conver(0)
// ---------------------------------------------------------------------------------------
#pragma conver(1252)
static void  copyNodeValueIntoBuffer (PUCHAR pParmBuffer, PJXPARMMETA pDef, PNOXNODE pValueNode)
{
   PUCHAR pValue  = nox_GetValuePtr   (pValueNode , pDef->name , "");
   copyValueIntoBuffer (pParmBuffer, pDef,  pValue );
}
#pragma conver(0)
// ---------------------------------------------------------------------------------------
// name suffix is ___ then it is Anonymous Array
#pragma conver(1252)
static BOOL isAnonymousArray (PUCHAR name) {
   int l = strlen(name);
   return (l > 3 && 0==memcmp(name + l -3 ,"___", 3 ));
}
#pragma conver(0)
// ---------------------------------------------------------------------------------------
static void  copyNodeIntoBuffer (PUCHAR pParmBuffer , PJXPARMMETA pParentMeta , PJXPARMMETA pMeta ,  PNOXNODE pParmValueNode )
{

   if (pMeta->dim > 0 ) {
      PNOXNODE pArray =  isAnonymousArray (pMeta->name) ? pParmValueNode :nox_GetNode   (pParmValueNode , pMeta->name);
      PNOXNODE pArrayElement = nox_GetNodeChild (pArray);
      if (pMeta->pStructure) {
         PNOXNODE pStructObj = nox_GetNodeChild (pMeta->pStructure);
         PJXPARMMETA pDef = getParmDefinition (pStructObj);
         for (int i=0; i < pMeta->dim ; i++) {
            copyNodeIntoBuffer(pParmBuffer, pMeta , pDef ,  pArrayElement);
            pParmBuffer += pMeta->size;
            pArrayElement = nox_GetNodeNext(pArrayElement);
         }
      } else {
         for (int i=0; i < pMeta->dim ; i++) {
            PUCHAR pValue  = nox_GetNodeValuePtr  (pArrayElement , "");
            copyValueIntoBuffer(pParmBuffer, pMeta ,  pValue );
            pParmBuffer += pMeta->size;
            pArrayElement = nox_GetNodeNext(pArrayElement);
         }
      }
   } else if (pMeta->pStructure) {
      PNOXNODE pValueNode = nox_GetNode ( pParmValueNode , pMeta->name);
      PNOXNODE pMetaElements = nox_GetNodeChild (pMeta->pStructure);
      while (pMetaElements) {
         PJXPARMMETA pDef = getParmDefinition (pMetaElements);
         if (pDef->pStructure) {
            copyNodeIntoBuffer (pParmBuffer, pMeta, pDef ,   pValueNode);
         } else {
            copyNodeValueIntoBuffer ( pParmBuffer, pDef, pValueNode);
         }
         pParmBuffer += pDef->size;
         pMetaElements = nox_GetNodeNext(pMetaElements);
      }
   // Since the parent has the definition, and each values comes as an object in an array:
   } else if (pParentMeta && pParentMeta->dim > 0) {
      PNOXNODE pMetaElements = nox_GetNodeChild(pParentMeta->pStructure);
      while (pMetaElements) {
         PJXPARMMETA pDef = getParmDefinition (pMetaElements);
         if (pDef->pStructure || pDef->dim > 0 ) {
            copyNodeIntoBuffer (pParmBuffer, pMeta, pDef ,pParmValueNode);
         } else {
            copyNodeValueIntoBuffer ( pParmBuffer, pDef, pParmValueNode);
         }
         pParmBuffer += pDef->size;
         pMetaElements = nox_GetNodeNext(pMetaElements);
      }
   } else {
      copyNodeValueIntoBuffer ( pParmBuffer, pMeta, pParmValueNode);
   }
}
// ---------------------------------------------------------------------------------------
#pragma conver(1252)
static int buildArgBufferArray (PJXMETHOD pMethod, PNOXNODE pParms, PVOID argArray [256] , PUCHAR * ppArgBuffer)
{

   int args = 0;
   ULONG   bufTotlen;
   PUCHAR  pParmBuffer;
   PNOXNODE pInterface, pParmObj;

   pInterface = (pMethod->pProc == NULL) ? pMethod->pPgm : pMethod->pProc;
   bufTotlen =  nox_GetValueInt  (pInterface , "buflen" , 0) ;

   pParmBuffer = memAlloc (bufTotlen);
   memset ( pParmBuffer , '\0',  bufTotlen);
   *ppArgBuffer = pParmBuffer;

   pParmObj = nox_GetNodeChild(nox_GetNode ( pInterface , "parms"));
   while (pParmObj) {
      PJXPARMMETA pMeta = getParmDefinition (pParmObj);
      PUCHAR pBuf = pParmBuffer + pMeta->offset;
      argArray [args++] = pBuf;
      copyNodeIntoBuffer (pBuf, NULL , pMeta ,  pParms);
      pParmObj = nox_GetNodeNext(pParmObj);
   }
   return args;
}
#pragma conver(0)
// ---------------------------------------------------------------------------------------
static PNOXNODE newReturnNode (PJXPARMMETA pMethodParm, PUCHAR pParmBuffer )
{

   UCHAR data [32000]; // TODO - dynamic size

   switch (pMethodParm->dType) {
      case NOX_DTYPE_STRUCTURE: {
         break;
      }
      case NOX_DTYPE_CHAR: {
         strrighttrimncpy(data ,pParmBuffer , pMethodParm->length );
         break;
      }
      case NOX_DTYPE_VARCHAR: {
         int actlen =  (pMethodParm->precision == 4) ? *(PULONG) pParmBuffer : *(PUSHORT) pParmBuffer ;
         substr (data  , pParmBuffer + pMethodParm->precision ,actlen);
         break;
      }
      case NOX_DTYPE_BYTE: {
         USHORT i = *(PUCHAR) pParmBuffer;
         sprintf ( data , "%hd" , *pParmBuffer);
         break;
      }
      case NOX_DTYPE_INT: {
         BOOL isSigned = (pMethodParm->precision % 2 != 0) ? TRUE : FALSE;
         fmtInteger (data , pParmBuffer , pMethodParm->length , isSigned );
         break;
      }
      case NOX_DTYPE_PACKED: {
         fmtPacked(data  , pParmBuffer , pMethodParm->length  , pMethodParm->precision , '.');
         break;
      }
      case NOX_DTYPE_ZONED: {
         fmtZoned (data  , pParmBuffer , pMethodParm->length  , pMethodParm->precision, '.');
         break;
      }
      case NOX_DTYPE_DATE: {
         fmtDate  ( data , pParmBuffer , pMethodParm->format);
         break;
      }
      case NOX_DTYPE_TIME: {
         fmtTime  ( data , pParmBuffer);
         break;
      }
      case NOX_DTYPE_TIME_STAMP: {
         substr  ( data  ,  pParmBuffer , pMethodParm->length);
         break;
      }
      case NOX_DTYPE_BOOL: {
         strcpy ( data , (*pParmBuffer == '1') ? "true" : "false");
         break;
      }
      case NOX_DTYPE_UNKNOWN: {
         break;
      }
   }
   return nox_NewNode(pMethodParm->name , data , pMethodParm->graphDataType );

}
/* ------------------------------------------------------------- */
static void  setReturnObject (PNOXNODE pReturnObject, PNOXNODE pParmObj , PUCHAR pParmBuffer, BOOL isArray )
{
   PJXPARMMETA pMethodParm = getParmDefinition (pParmObj);

   if (pMethodParm->dim > 0 && isArray == FALSE) {
      if (isAnonymousArray(pMethodParm->name)) {
         if (pMethodParm->pStructure) {
            PNOXNODE pStructObj = nox_GetNodeChild(pMethodParm->pStructure);
            for (int i = 0 ; i< pMethodParm->dim ; i++) {
               setReturnObject ( pReturnObject  , pStructObj , pParmBuffer, TRUE);
               pParmBuffer += pMethodParm->size;
            }
         } else {
            for (int i = 0 ; i< pMethodParm->dim ; i++) {
               nox_NodeInsertChildTail  ( pReturnObject , newReturnNode (pMethodParm, pParmBuffer));
               pParmBuffer += pMethodParm->size;
            }
         }
      } else {
         PNOXNODE pReturnArray = nox_NewArray(NULL);
         nox_NodeRename (pReturnArray , pMethodParm->name);
         if (pMethodParm->pStructure) {
            PNOXNODE pStructObj = nox_GetNodeChild(pMethodParm->pStructure);
            for (int i = 0 ; i< pMethodParm->dim ; i++) {
               setReturnObject ( pReturnArray  , pStructObj , pParmBuffer, TRUE);
               pParmBuffer += pMethodParm->size;
            }
         } else {
            for (int i = 0 ; i< pMethodParm->dim ; i++) {
               nox_NodeInsertChildTail  ( pReturnArray , newReturnNode (pMethodParm, pParmBuffer));
               pParmBuffer += pMethodParm->size;
            }
         }
         nox_NodeInsertChildTail (pReturnObject , pReturnArray );
      }
   } else if (isArray) {
      PNOXNODE pReturnStruct = isAnonymousArray(pMethodParm->name) ? nox_NewArray(NULL) : nox_NewObject(NULL);
      for (; pParmObj ; pParmObj = nox_GetNodeNext(pParmObj)) {
         PJXPARMMETA pStructParm = getParmDefinition (pParmObj);
         setReturnObject ( pReturnStruct , pParmObj, pParmBuffer + pStructParm->offset, FALSE);
      }
      nox_NodeInsertChildTail (pReturnObject , pReturnStruct );
   } else if (pMethodParm->dType == NOX_DTYPE_STRUCTURE) {
      PNOXNODE pStructObj = nox_GetNodeChild(pMethodParm->pStructure);
      PNOXNODE pReturnStruct = isAnonymousArray(pMethodParm->name) ? nox_NewArray(NULL) : nox_NewObject(NULL);
      nox_NodeRename (pReturnStruct , pMethodParm->name);
      for (; pStructObj ; pStructObj = nox_GetNodeNext(pStructObj)) {
         PJXPARMMETA pStructParm = getParmDefinition (pStructObj);
         setReturnObject ( pReturnStruct , pStructObj, pParmBuffer + pStructParm->offset, FALSE);
      }
      nox_NodeInsertChildTail (pReturnObject , pReturnStruct );
   } else {
      nox_NodeInsertChildTail (pReturnObject , newReturnNode (pMethodParm,  pParmBuffer));
   }
}
/* ------------------------------------------------------------- */
static PNOXNODE buildReturnObject (PJXMETHOD  pMethod, PNOXNODE pParms, PVOID argArray [256], int args)
{
   PNOXNODE pReturnObject = NULL ;
   PNOXNODE pInterface = (pMethod->pProc == NULL) ? pMethod->pPgm : pMethod->pProc;
#pragma convert(1252)
   PNOXNODE pParmObj = nox_GetNodeChild(nox_GetNode ( pInterface , "parms"));
#pragma convert(0)
   for (int argIx= 0; pParmObj ;  argIx++, pParmObj = nox_GetNodeNext(pParmObj)) {
      PJXPARMMETA pMethodParm = getParmDefinition (pParmObj);
      if (pMethodParm->use == 'B') { // BOTH .. TODO in enum
         if (pReturnObject == NULL) {
            pReturnObject = isAnonymousArray(pMethodParm->name) ? nox_NewArray(NULL) : nox_NewObject(NULL);
         }
         setReturnObject (pReturnObject , pParmObj,  argArray [argIx], FALSE);
      }
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
static PNOXNODE  call    (PJXMETHOD pMethod , PNOXNODE parms, ULONG options)
{
   PNOXNODE pReturnObject;
   PNOXNODE pParms;
   BOOL    freeAfter;
   PUCHAR  pArgBuffer;
   PVOID   argArray[256];

   if ((parms != NULL)
   &&  (parms->signature != NODESIG)) {
      pParms  = nox_ParseString ((PUCHAR) parms, "" );
      freeAfter = TRUE;
   } else {
      pParms  = parms;
      freeAfter = FALSE;
   }

   int args = buildArgBufferArray ( pMethod, pParms, argArray, &pArgBuffer);

   if ( pMethod->userMethodIsProgram) {
      nox_callPgm ( pMethod->userMethod , argArray , args );
   } else {
      nox_callProc (pMethod->userMethod , argArray , args);
   }

   pReturnObject = buildReturnObject (pMethod, pParms, argArray, args);

   memFree (&pArgBuffer);

   if (freeAfter) {
      nox_NodeDelete (pParms);
   }

   return pReturnObject;
}

/* --------------------------------------------------------------------------- *\
    Get the pcml from the program
\* --------------------------------------------------------------------------- */
PNOXNODE  nox_ProgramMeta ( PUCHAR library , PUCHAR Program)
{
   Qbn_Interface_Entry_t * pet;
   Qbn_PGII0100_t * ppgi;
   UCHAR buffer [100000];
   long long err = 0;
   long i;
   PNOXNODE pPcml;
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
   pPcml  = nox_ParseString(pcml, "");

   // would yield QTEMP - where it is build
   // if (*library == '*') {
   //    memcpy ( library , pet->Module_Library, 10);
   // }

   return  pPcml;
}
/* --------------------------------------------------------------------------- *\
    Get the pcml from the program
\* --------------------------------------------------------------------------- */
PNOXNODE  nox_ProcedureMeta ( PUCHAR library , PUCHAR Program , PUCHAR Procedure)
{
   Qbn_Interface_Entry_t * pet;
   Qbn_PGII0100_t * ppgi;
   UCHAR buffer [100000];
   long long err = 0;
   long i;
   PNOXNODE pPcml;
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
      pPcml  = nox_ParseString(pcml, "");

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
//  --------------------------------------------------------------------------- 
#pragma convert(1252)
NOX_DTYPE convertDataType (PUCHAR type)
{
   if (type == NULL) {
      return NOX_DTYPE_UNKNOWN;
   } else if (0 == strcmp(type , "char")) {
      return NOX_DTYPE_CHAR;
   } else if (0 == strcmp(type , "packed")) {
      return NOX_DTYPE_PACKED;
   } else if (0 == strcmp(type , "zoned")) {
      return NOX_DTYPE_ZONED;
   } else if (0 == strcmp(type , "varchar")) {
      return NOX_DTYPE_VARCHAR;
   } else if (0 == strcmp(type , "date")) {
      return NOX_DTYPE_DATE;
   } else if (0 == strcmp(type , "time")) {
      return NOX_DTYPE_TIME;
   } else if (0 == strcmp(type , "timestamp")) {
      return NOX_DTYPE_TIME_STAMP;
   } else if (0 == strcmp(type , "int")) {
      return NOX_DTYPE_INT;
   } else if (0 == strcmp(type , "byte")) {
      return NOX_DTYPE_BYTE;
   } else if (0 == strcmp(type , "struct")) {
      return NOX_DTYPE_STRUCTURE;
   } else {
      return NOX_DTYPE_UNKNOWN;
   }
}
#pragma convert(0)
/* --------------------------------------------------------------------------- *\
   Recursivly run through each node
\* --------------------------------------------------------------------------- */
#pragma convert(1252)
static LONG getTotalStructSize(PNOXNODE pStructure) {
   LONG totalSize = 0 ;
   for (PNOXNODE pElements = nox_GetNodeChild ( pStructure ) ; pElements ; pElements =  nox_GetNodeNext  (pElements )) {
      PJXPARMMETA pMeta = (PJXPARMMETA) nox_GetNodeAttrValuePtr ( pElements, "def" , NULL);
      if  (pMeta) {  // TODO !!! need it allways !!
         if  (pMeta->pStructure) {
            totalSize += getTotalStructSize (pElements);
         }
         totalSize += (pMeta->dim > 0) ? pMeta->size * pMeta->dim : pMeta->size;
      }
   }
   return totalSize;
}
#pragma convert(0)
/* --------------------------------------------------------------------------- *\
   Create a new method parameter object
\* --------------------------------------------------------------------------- */
#pragma convert(1252)
PJXPARMMETA newMethodParm ( PNOXNODE pParmMeta)
{
   PUCHAR p;
   PJXPARMMETA pMethodParm  = memAlloc (sizeof(JXPARMMETA));
   memset (pMethodParm , 0, sizeof(JXPARMMETA));
   strcpy(pMethodParm->name , parmMetaValue ( pParmMeta, "name"));
   //  TODO !! Cater for PCML version before 7.0
   // if (0 == strcmp("struct" ,nox_GetNodeNamePtr (pParmMeta))) {
   //   pMethodParm->dType = NOX_DTYPE_STRUCTURE;
   //} else {
   if (*parmMetaValue ( pParmMeta, "boolean") == 't') { // short for "true"
      pMethodParm->dType  = NOX_DTYPE_BOOL;
   } else {
      pMethodParm->dType  = convertDataType(parmMetaValue ( pParmMeta, "type"));
   }
   pMethodParm->use       = (0 == strcmp(parmMetaValue ( pParmMeta, "usage") , "inputoutput")) ? 'B' : 'I';
   pMethodParm->length    = parmMetaValueInt ( pParmMeta, "length", 0);
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
#pragma convert(0)
// ----------------------------------------------------------------------------------------
#pragma convert(1252)
PNOXNODE buildMethodParmObject ( PJXPARMMETA pMethodParm)
{
   PNOXNODE  pParmObject = nox_NewObject (NULL);

   // The internal binary definition structure pointer saved in the graph
   nox_SetNodeAttrValuePtr(pParmObject  , "def" , (PUCHAR) pMethodParm);

   if (pMethodParm->pStructure) {
      pMethodParm->length = pMethodParm->size =  getTotalStructSize (pMethodParm->pStructure);
      // No !! Structure size for array is done at top level:
      // if (pMethodParm->dim > 0) {
      //    pMethodParm->size *= pMethodParm->dim;
      // }
      nox_SetValueByName(pParmObject  , "name"  , pMethodParm->name   , VALUE);
      nox_SetIntByName  (pParmObject  , "offset", pMethodParm->offset , OFF);
      nox_SetIntByName  (pParmObject  , "size"  , pMethodParm->size , OFF);
      if (pMethodParm->dim > 0) {
         nox_SetIntByName  (pParmObject  , "dim" ,  pMethodParm->dim, OFF);
      }
      nox_SetValueByName(pParmObject  , "struct" , (PUCHAR) pMethodParm->pStructure  , NOXDB_SUBGRAPH);
   } else {
      nox_SetValueByName(pParmObject  , "name"  , pMethodParm->name   , VALUE);
      nox_SetCharByName (pParmObject  , "type"  , pMethodParm->dType  , OFF);
      nox_SetCharByName (pParmObject  , "use"   , pMethodParm->use    , OFF);
      nox_SetIntByName  (pParmObject  , "offset", pMethodParm->offset , OFF);
      nox_SetIntByName  (pParmObject  , "size"  , pMethodParm->size , OFF);
      nox_SetIntByName  (pParmObject  , "length", pMethodParm->length , OFF);
      nox_SetIntByName  (pParmObject  , "prec" ,  pMethodParm->precision, OFF);
      if (*pMethodParm->format) {
         nox_SetValueByName(pParmObject  , "format", pMethodParm->format   , VALUE);
      }
      if (pMethodParm->separatorChar) {
         nox_SetCharByName (pParmObject  , "separator",  pMethodParm->separatorChar , VALUE);
      }
      if (pMethodParm->dim > 0) {
         nox_SetIntByName  (pParmObject  , "dim" ,  pMethodParm->dim, OFF);
      }
   }

   return pParmObject;
}
#pragma convert(0)
// ----------------------------------------------------------------------------------------
#pragma convert(1252)
static PNOXNODE buildParmElements(PNOXNODE pPcmlProgram, PNOXNODE pStructs, PLONG offset, PLONG size, PNOXNODE pProgram)
{

   PNOXNODE pParms    = nox_NewArray (NULL);
   PNOXNODE pParmMeta = nox_GetNode  (pPcmlProgram , "data");
   while (pParmMeta) {
      PNOXNODE     pParm;
      PJXPARMMETA pMethodParm = newMethodParm ( pParmMeta);

      switch ( pMethodParm->dType) {

         case NOX_DTYPE_STRUCTURE: {
            // Is it a varchar
            PNOXNODE pChild1 = nox_GetNodeChild ( pParmMeta);
            PNOXNODE pChild2 = nox_GetNodeNext  ( pChild1 );

            // PCML prior to V6 for VARCHAR
            if ((pChild1 && pChild2)
            && ( 0 == strcmp (parmMetaValue ( pChild1, "name") ,"length")
            &&   0 == strcmp (parmMetaValue ( pChild2, "name") ,"string"))) {
               pMethodParm->dType = NOX_DTYPE_VARCHAR;
               pMethodParm->precision = parmMetaValueInt ( pChild1, "length", 2);
               pMethodParm->size = parmMetaValueInt ( pParmMeta, "outputsize", 0);
               pMethodParm->length = pMethodParm->size - pMethodParm->precision;
            } else {
               PUCHAR nodeName ;
               nodeName =  parmMetaValue ( pParmMeta , "struct");
               pMethodParm->pStructure  = nox_GetNode  (pStructs , nodeName);
            }
            break;
         }
         case NOX_DTYPE_CHAR:{
            pMethodParm->graphDataType = VALUE;
            break;
         }
         case NOX_DTYPE_VARCHAR: {
            pMethodParm->graphDataType = VALUE;
            if (pMethodParm->precision == 0) {
               pMethodParm->precision = 2;
            }
            pMethodParm->size = pMethodParm->precision + pMethodParm->length;
            break;
         }
         case NOX_DTYPE_INT:
         case NOX_DTYPE_BYTE:
         case NOX_DTYPE_BOOL:
         case NOX_DTYPE_ZONED: {
            pMethodParm->graphDataType = LITERAL;
            break;
         }
         case NOX_DTYPE_PACKED: {
            pMethodParm->graphDataType = LITERAL;
            pMethodParm->size = pMethodParm->length / 2 + 1;
            break;
         }
         case NOX_DTYPE_DATE:  {
            strcpy ( pMethodParm->format , parmMetaValue ( pParmMeta, "dateformat"));
            pMethodParm->graphDataType = VALUE;
            pMethodParm->separatorChar = convertSeperator(
               parmMetaValue ( pParmMeta, "dateseparator")
            );
            pMethodParm->length = pMethodParm->size  = 10 ; // TODO More?
            break;
         }

         case NOX_DTYPE_TIME:  {
            strcpy ( pMethodParm->format , parmMetaValue ( pParmMeta, "timeformat"));
            pMethodParm->graphDataType = VALUE;
            pMethodParm->separatorChar = convertSeperator(
               parmMetaValue ( pParmMeta, "timeseparator")
            );
            pMethodParm->length = pMethodParm->size = 8 ;
            break;
         }
         case NOX_DTYPE_TIME_STAMP: {
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

      // Setup for next iteration
      LONG totSize = pMethodParm->dim > 0 ? pMethodParm->size * pMethodParm->dim : pMethodParm->size;
      *offset += totSize;
      *size   += totSize;


      nox_ArrayPush ( pParms , pParm , FALSE);

      pParmMeta = nox_GetNodeNext(pParmMeta);
   }
   return pParms;
}
#pragma convert(0)

/* --------------------------------------------------------------------------- *\
   Load all complex (if any) datatypes and make a __structs__ node
\* --------------------------------------------------------------------------- */
#pragma convert(1252)
static void buildStructures ( PNOXNODE pProgram , PNOXNODE pPcml)
{
   PNOXNODE pPcmlStruct = nox_GetNode  (pPcml , "/pcml/struct");
   if (pPcmlStruct) {

      PNOXNODE pStructs  = nox_NewObject(NULL);

      while ( pPcmlStruct && 0==strcmp(nox_GetNodeNamePtr(pPcmlStruct),"struct")) {
         PUCHAR  structureName = parmMetaValue ( pPcmlStruct, "name");
         LONG   offset = 0;
         LONG   size   = 0;
         PNOXNODE pElements = buildParmElements(pPcmlStruct , pStructs , &offset, &size, pProgram);
         nox_SetNodeAttrValueInt (pElements , "size", size);
         nox_NodeMoveInto (pStructs, structureName, pElements );
         pPcmlStruct = nox_GetNodeNext(pPcmlStruct);
      }
      nox_NodeMoveInto (pProgram, "__structs__", pStructs );
   }
}
#pragma convert(0)
/* --------------------------------------------------------------------------- *\
   Load all program/procedure entry points
\* --------------------------------------------------------------------------- */
#pragma convert(1252)
static void buildParameters ( PNOXNODE pProgram , PNOXNODE pPcml , BOOL isProgram )
{

   PNOXNODE pPcmlProgram = nox_GetNode (pPcml , "/pcml/program");
   PNOXNODE pStructs     = nox_GetNode (pProgram ,  "__structs__");

   while (pPcmlProgram && 0==strcmp(nox_GetNodeNamePtr(pPcmlProgram),"program")) {
      LONG    offset = 0;
      LONG    size   = 0;
      PNOXNODE pParms = buildParmElements(pPcmlProgram , pStructs , &offset, &size, pProgram);

      if (isProgram ) { // *PGM
         nox_SetIntByName ( pProgram , "buflen" , size  , OFF);
         nox_NodeMoveInto ( pProgram , "parms" , pParms);
      } else {
         UCHAR tempProc [PROC_NAME_MAX];
         PNOXNODE pProcedure    = nox_NewObject(NULL);
         PUCHAR  procedureName  = parmMetaValue ( pPcmlProgram, "name");
         nox_SetIntByName ( pProcedure , "buflen" , size , OFF);
         nox_NodeMoveInto ( pProcedure , "parms"  , pParms);
         strtrimncpy ( tempProc , procedureName , PROC_NAME_MAX);
         nox_NodeMoveInto ( pProgram , tempProc, pProcedure);
      }

      pPcmlProgram = nox_GetNodeNext(pPcmlProgram);

   }
}
#pragma convert(0)
/* --------------------------------------------------------------------------- *\
   Convert pcml to uniform json used for both programs and service programs
\* --------------------------------------------------------------------------- */
PNOXNODE  nox_ApplicationMeta ( PUCHAR library , PUCHAR program , PUCHAR objectType)
{
   PNOXNODE pPcml;
   UCHAR   tempPgm [11];
   UCHAR   tempLib [11];
   BOOL    isProgram = objectType[1] == 'P';

   if (isProgram) {
      if ( *library == '*' ) {
         _SYSPTR pPgm = nox_loadProgram (library, program);
         getLibraryForSysPtr ( pPgm , library);
      }
      pPcml = nox_ProgramMeta ( library , program );
   } else {
      if ( *library == '*' ) {
         _SYSPTR pPgm = nox_loadServiceProgram (library, program);
         getLibraryForSysPtr ( pPgm , library);
      }
      pPcml = nox_ProcedureMeta ( library , program , "*ALL");
   }

   if (pPcml == NULL ) return NULL;

   // TODO : for now return null, but let a object with out PCML make a default graph for caching
   #pragma convert(1252)
   PNOXNODE pPcmlProgram = nox_GetNode  (pPcml , "/pcml/program");
   #pragma convert(0)
   if (pPcmlProgram == NULL) {
      nox_NodeDelete (pPcml);
      return NULL;
   }

   PNOXNODE pResultObject = nox_NewObject(NULL);
   PNOXNODE pLib          = nox_NewObject(NULL);
   PNOXNODE pObjectType   = nox_NewObject(NULL);
   PNOXNODE pProgram      = nox_NewObject(NULL);

   buildStructures ( pProgram , pPcml);
   buildParameters ( pProgram , pPcml , isProgram);


   strtrimncpy ( tempPgm  , program , 10);
   strtrimncpy ( tempLib  , library , 10);
   nox_NodeMoveInto ( pObjectType   , tempPgm , pProgram);
   #pragma convert(1252)
   nox_NodeMoveInto ( pLib          , isProgram ? "program" : "service" , pObjectType);
   #pragma convert(0)
   nox_NodeMoveInto ( pResultObject , tempLib , pLib);
   nox_NodeDelete (pPcml);


   return pResultObject;

}


/* --------------------------------------------------------------------------- *\
    Handler :
\* --------------------------------------------------------------------------- */
PNOXNODE  nox_CallProgram (PUCHAR library , PUCHAR program, PNOXNODE parmsP, ULONG optionsP)
{

   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PNOXNODE parms   = (pParms->OpDescList->NbrOfParms >= 3 ) ? parmsP : NULL;
   ULONG   options = (pParms->OpDescList->NbrOfParms >= 4 ) ? optionsP : 0;
   JXMETHOD pgm;

   memset ( &pgm , 0 , sizeof(pgm));
   strtrimncpy (pgm.library   , library , 10);
   strtrimncpy (pgm.program   , program  , 10);
   strtrimncpy (pgm.procedure , "*PGM" , PROC_NAME_MAX );
   pgm.userMethod = nox_loadProgram ( pgm.library, pgm.program);
   pgm.pMetaNode  = nox_ApplicationMeta (pgm.library , pgm.program , pgm.procedure );
   pgm.userMethodIsProgram = TRUE;
   pgm.pLib  = nox_GetNode(pgm.pMetaNode , pgm.library);
   #pragma convert(1252)
   pgm.pPgm  = nox_GetNode(nox_GetNode(pgm.pLib , "program") , pgm.program);
   #pragma convert(0)
   pgm.pProc = NULL;

   PNOXNODE pResult = call (&pgm, parms , options);
   nox_NodeDelete( pgm.pMetaNode );
   return pResult;
}
/* --------------------------------------------------------------------------- *\
    Handler :
\* --------------------------------------------------------------------------- */
PNOXNODE  nox_CallProcedure (PUCHAR library, PUCHAR srvPgm, PUCHAR procedure, PNOXNODE parmsP, ULONG optionsP)
{

   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PNOXNODE parms   = (pParms->OpDescList->NbrOfParms >= 4 ) ? parmsP : NULL;
   ULONG   options = (pParms->OpDescList->NbrOfParms >= 5 ) ? optionsP : 0;
   JXMETHOD pgm;

   memset ( &pgm , 0 , sizeof(pgm));
   strtrimncpy (pgm.library   , library , 10);
   strtrimncpy (pgm.program   , srvPgm , 10);
   strtrimncpy (pgm.procedure , procedure , PROC_NAME_MAX );

   pgm.userMethod = nox_loadServiceProgramProc ( pgm.library, pgm.program , pgm.procedure);
   pgm.pMetaNode  = nox_ApplicationMeta (pgm.library , pgm.program , pgm.procedure );
   pgm.userMethodIsProgram = FALSE;
   pgm.pLib  = nox_GetNode(pgm.pMetaNode , pgm.library);
   #pragma convert(1252)
   pgm.pPgm  = nox_GetNode(nox_GetNode(pgm.pLib , "service") , pgm.program);
   #pragma convert(0)
   pgm.pProc = nox_GetNode(pgm.pPgm      , pgm.procedure);

   PNOXNODE pResult = call (&pgm, parms , options);
   nox_NodeDelete( pgm.pMetaNode);
   return pResult;
}
