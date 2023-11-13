/* SYSIFCOPT(*IFSIO) TERASPACE(*YES *TSIFC)   STGMDL(*SNGLVL) */
/* ------------------------------------------------------------- */
/* SYSIFCOPT(*IFSIO) OPTION(*EXPMAC *SHOWINC)                    */
/* Program . . . : CALLSRVPGM                                    */
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


/* ------------------------------------------------------------- */
_SYSPTR loadServiceProgram (PUCHAR Lib , PUCHAR SrvPgm)
{
   UCHAR SrvPgm_  [11];
   UCHAR Lib_     [11];
   _SYSPTR pgm;

   sprintf(SrvPgm_ , "%-10.10s" , SrvPgm);
   sprintf(Lib_    , "%-10.10s" , Lib);

   try {
      pgm = rslvsp(WLI_SRVPGM , SrvPgm_  , Lib_  , _AUTH_OBJ_MGMT);
   }
   catch (NULL) {
      pgm = NULL;
   }
   return pgm;
}
/* ------------------------------------------------------------- */
_SYSPTR loadProc (_SYSPTR srvpgm ,  PUCHAR procName)
{
   _SYSPTR proc;
   int type;
   APIERR  apierr;
   UINT64 Mark;
   int expNo = 0;
   int expLen = 0;
   int i;
   int acinfolen;
   Qle_ABP_Info_t acinfo;
   Qus_EC_t       ec;

   if (srvpgm == NULL) return NULL;

   ec.Bytes_Provided = sizeof(ec);
   apierr.size = sizeof(apierr);
   acinfolen = sizeof(acinfo);
   QleActBndPgmLong(&srvpgm, &Mark , &acinfo , &acinfolen , &ec);
   proc = QleGetExpLong(&Mark , &expNo  , &expLen , procName , &proc , &type , &ec);
   return(proc);
}
/* ------------------------------------------------------------- */
_SYSPTR loadServiceProgramProc (PUCHAR Lib , PUCHAR SrvPgm, PUCHAR procName , LGL cache)
{
    _SYSPTR pgm = loadServiceProgram (Lib , SrvPgm);
    return loadProc (pgm, procName);
}
/* ------------------------------------------------------------- */
_SYSPTR loadProgram (PUCHAR Lib , PUCHAR Pgm)
{
   UCHAR Pgm_  [11];
   UCHAR Lib_  [11];
   _SYSPTR pgm;

   sprintf(Pgm_ , "%-10.10s" , Pgm);
   sprintf(Lib_ , "%-10.10s" , Lib);

   try {
      pgm = rslvsp(WLI_PGM , Pgm_  , Lib_  , _AUTH_OBJ_MGMT);
   }
   catch (NULL) {
      pgm = NULL;
   }
   return pgm;
}
/* --------------------------------------------------------------------------- *\
   parse PCML:
   <pcml version="7.0">
      <program name="HELLOPGM" path="/QSYS.LIB/ILEASTIC.LIB/HELLOPGM.PGM">
         <data name="NAME" type="char" length="10" usage="input" />
         <data name="TEXT" type="char" length="200" usage="inputoutput" />
          <data name="AGE" type="packed" length="5" precision="0" usage="inputoutput"/>
      </program>
   </pcml>
\* --------------------------------------------------------------------------- */

/* --------------------------------------------------------------------------- *\
    Call the plain program resolved by the system pointer:
\* --------------------------------------------------------------------------- */
static PJXNODE  call    (PJXMETHOD pMethod , PJXNODE parms, ULONG options)
{
   PJXNODE pParm = jx_GetNode  (pMethod->pPcml , "/pcml/program/data") ;
   PJXNODE pOutParm = pParm;
   PJXNODE pReturnObject;
   PJXNODE pParms;
   BOOL    freeAfter;
   UCHAR   parmbuffer [32000];
   PUCHAR  pParmBuffer = parmbuffer;
   SHORT   parmIx = 0;
   PVOID   argArray[256];
   SHORT   parmNum;

   if ((parms != NULL)
   &&  (parms->signature != NODESIG)) {
      pParms  = jx_ParseString ((PUCHAR) parms, "" );
      freeAfter = TRUE;
   } else {
      pParms  = parms;
      freeAfter = FALSE;
   }

   while ( pParm) {
      PUCHAR name   = jx_GetAttrValuePtr ( jx_AttributeLookup ( pParm, "NAME"));
      PUCHAR type   = jx_GetAttrValuePtr ( jx_AttributeLookup ( pParm, "TYPE"));
      PUCHAR length = jx_GetAttrValuePtr ( jx_AttributeLookup ( pParm, "LENGTH"));
      PUCHAR usage  = jx_GetAttrValuePtr ( jx_AttributeLookup ( pParm, "USAGE"));
      int len = length ? atoi(length) : 0;
      int dtaLen, bufLen;
      PUCHAR pValue =  jx_GetNodeValuePtr(jx_GetNode  (pParms ,name),"") ;
      argArray [parmIx++] = pParmBuffer;

      if ( 0 == strcmp ( type, "char")) {
         padncpy ( pParmBuffer , pValue , len);
         pParmBuffer[len] = '\0'; // terminate for now
         bufLen = len+ 1 ; // room for zero term
      } else if ( 0 == strcmp ( type, "packed")) {
         SHORT  precision = atoi(jx_GetAttrValuePtr ( jx_AttributeLookup ( pParm, "PRECISION")));
         str2packedMem ( pParmBuffer , pValue , len , precision);
         pParmBuffer += (len + 1) / 2;
      }
      pParmBuffer += bufLen;

      pParm = jx_GetNodeNext(pParm);
   }

   _CALLPGMV ( &pMethod->userMethod , argArray , parmIx );

   pReturnObject = jx_NewObject(NULL);
   parmIx= 0;
   while ( pOutParm) {
      PUCHAR name   = jx_GetAttrValuePtr ( jx_AttributeLookup ( pOutParm, "NAME"));
      PUCHAR type   = jx_GetAttrValuePtr ( jx_AttributeLookup ( pOutParm, "TYPE"));
      PUCHAR length = jx_GetAttrValuePtr ( jx_AttributeLookup ( pOutParm, "LENGTH"));
      PUCHAR usage  = jx_GetAttrValuePtr ( jx_AttributeLookup ( pOutParm, "USAGE"));
      int len = length ? atoi(length) : 0;
      UCHAR temp [256];
      UCHAR data [256];
      PUCHAR pData;

      pParmBuffer = argArray [parmIx++];

      if (0==strcmp(usage , "inputoutput")) {
         if ( 0 == strcmp ( type, "char")) {
            pData = righttrimlen(pParmBuffer , len );
         } else if ( 0 == strcmp ( type, "packed")) {
            SHORT  precision = atoi(jx_GetAttrValuePtr ( jx_AttributeLookup ( pParm, "PRECISION")));
            pData = fmtPacked(data  , pParmBuffer , len  , precision, '.');
         }
         jx_SetStrByName (pReturnObject , str2lower (temp, name ) , pData);
      }
      pOutParm = jx_GetNodeNext(pOutParm);
   }

   if (freeAfter) {
      jx_NodeDelete (pParms);
   }

   return pReturnObject;
}

/* --------------------------------------------------------------------------- *\
    Get the pcml from the program
\* --------------------------------------------------------------------------- */
PJXNODE  jx_ProgramMeta ( PUCHAR Library , PUCHAR Program)
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
   memcpy ( libpgm +10  , Library , 10 );

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
   for (i=0;i< ppgi->Number_Entries; i++ ) {
      pcml = buffer + pet->Offset_Interface_Info;
      pcml [pet->Interface_Info_Length_Ret] = '\0';
      pPcml  = jx_ParseString(pcml, "");
      return  pPcml;
      // TODO !! pOpenAPI->ccsid = pet->Interface_Info_CCSID;
      /*

      printf ("Module : %10.10s \n" ,  pet->Module_Name);
      printf ("Library: %10.10s \n" ,  pet->Module_Library);
      printf ("ccsid  : %d \n" ,  pet->Interface_Info_CCSID);
      printf ("pcml   : %s \n" ,  pcml);
      */
      pet = (Qbn_Interface_Entry_t *) ((char *) pet + pet->Offset_Next_Entry);
   }
   return NULL;
}
/* --------------------------------------------------------------------------- *\
    Handleer :
\* --------------------------------------------------------------------------- */
PJXNODE  jx_CallProgram (PUCHAR library , PUCHAR program, PJXNODE parmsP, ULONG optionsP)
{

   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   JXMETHOD pgm;
   PJXNODE pResult;

   PJXNODE parms   = (pParms->OpDescList->NbrOfParms >= 3 ) ? parmsP : NULL;
   ULONG   options = (pParms->OpDescList->NbrOfParms >= 4 ) ? optionsP : 0;

   pgm.pPcml = jx_ProgramMeta(library , program);
   pgm.userMethodIsProgram = TRUE;
   pgm.userMethod = loadProgram ( library, program);
   pResult = call (&pgm, parms , options);
   jx_NodeDelete( pgm.pPcml);
   return pResult;
}
