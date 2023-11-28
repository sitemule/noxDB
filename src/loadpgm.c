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

//typedef _SYSPTR (*ILEPROC)(void * , ...);

typedef _SYSPTR (*ILEPROC)(PVOID, ...);
typedef _SYSPTR (*ILEPROC0)();
void callProc ( _SYSPTR proc , void * args [256] , SHORT parms);

/* ------------------------------------------------------------- */
_SYSPTR loadServiceProgram (PUCHAR lib , PUCHAR srvPgm)
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
_SYSPTR loadProc (_SYSPTR srvPgm ,  PUCHAR procName)
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
_SYSPTR loadServiceProgramProc (PUCHAR lib , PUCHAR srvPgm, PUCHAR procName)
{
    _SYSPTR pgm = loadServiceProgram (lib , srvPgm);
    return loadProc (pgm, procName);
}
/* ------------------------------------------------------------- */
_SYSPTR loadProgram (PUCHAR lib , PUCHAR pgm)
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
/* --------------------------------------------------------------------------- *\
   parse PCML:
   <pcml version="7.0">
      <program name="HELLOPGM" path="/QSYS.lIB/ILEASTIC.lIB/HELLOPGM.PGM">
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
   PJXNODE pInParm  = pParm;
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

   for (pInParm = pParm; pInParm ;  pInParm = jx_GetNodeNext(pInParm) ) {
      PUCHAR name   = jx_GetAttrValuePtr ( jx_AttributeLookup ( pInParm, "NAME"));
      PUCHAR type   = jx_GetAttrValuePtr ( jx_AttributeLookup ( pInParm, "TYPE"));
      PUCHAR length = jx_GetAttrValuePtr ( jx_AttributeLookup ( pInParm, "LENGTH"));
      PUCHAR usage  = jx_GetAttrValuePtr ( jx_AttributeLookup ( pInParm, "USAGE"));
      int len = length ? atoi(length) : 0;
      int dtaLen, bufLen;
      PUCHAR pValue =  jx_GetNodeValuePtr(jx_GetNode  (pParms ,name),"") ;
      argArray [parmIx++] = pParmBuffer;

      if ( 0 == strcmp ( type, "char")) {
         padncpy ( pParmBuffer , pValue , len);
         pParmBuffer[len] = '\0'; // terminate for now
         bufLen = len+ 1 ; // room for zero term
      } else if ( 0 == strcmp ( type, "packed")) {
         SHORT  precision = atoi(jx_GetAttrValuePtr ( jx_AttributeLookup ( pInParm, "PRECISION")));
         str2packedMem ( pParmBuffer , pValue , len , precision);
         pParmBuffer += (len + 1) / 2;
      }
      pParmBuffer += bufLen;
   }

   if ( pMethod->userMethodIsProgram) {
      _CALLPGMV ( &pMethod->userMethod , argArray , parmIx );
   } else {
      callProc (pMethod->userMethod , argArray , parmIx);
   }

   pReturnObject = jx_NewObject(NULL);
   parmIx= 0;
   for (pOutParm = pParm; pOutParm ;  pOutParm = jx_GetNodeNext(pOutParm) ) {
      PUCHAR name   = jx_GetAttrValuePtr ( jx_AttributeLookup ( pOutParm, "NAME"));
      PUCHAR type   = jx_GetAttrValuePtr ( jx_AttributeLookup ( pOutParm, "TYPE"));
      PUCHAR length = jx_GetAttrValuePtr ( jx_AttributeLookup ( pOutParm, "LENGTH"));
      PUCHAR usage  = jx_GetAttrValuePtr ( jx_AttributeLookup ( pOutParm, "USAGE"));
      int len = length ? atoi(length) : 0;
      UCHAR temp [256];
      UCHAR data [256];
      PUCHAR pData;


      if (0==strcmp(usage , "inputoutput")) {
         pParmBuffer = argArray [parmIx++];
         if ( 0 == strcmp ( type, "char")) {
            pData = righttrimlen(pParmBuffer , len );
         } else if ( 0 == strcmp ( type, "packed")) {
            SHORT  precision = atoi(jx_GetAttrValuePtr ( jx_AttributeLookup ( pParm, "PRECISION")));
            pData = fmtPacked(data  , pParmBuffer , len  , precision, '.');
         }
         jx_SetStrByName (pReturnObject , str2lower (temp, name ) , pData);
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

   pgm.pPcml = jx_ProgramMeta(library , program);
   pgm.userMethodIsProgram = TRUE;
   pgm.userMethod = loadProgram ( library, program);
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

   pgm.pPcml = jx_ProcedureMeta(library , srvPgm , procedure );
   pgm.userMethodIsProgram = FALSE;
   pgm.userMethod = loadServiceProgramProc ( library, srvPgm , procedure);
   pResult = call (&pgm, parms , options);
   jx_NodeDelete( pgm.pPcml);
   return pResult;
}
/* ------------------------------------------------------------- */
void callProc ( _SYSPTR proc , void *  p[64] , SHORT parms)
{
   PVOID pv =  proc;
   ILEPROC ileproc = pv;
   switch(parms) {
   case  0 : {
      ILEPROC0 ileproc = pv;
      ileproc();
      break;
   }
   case  1 : ileproc(p[0]);
             break;
   case  2 : ileproc(p[0] ,p[1]);
             break;
   case  3 : ileproc(p[0] ,p[1] ,p[2]);
             break;
   case  4 : ileproc(p[0] ,p[1] ,p[2] ,p[3]);
             break;
   case  5 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4]);
             break;
   case  6 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5]);
             break;
   case  7 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6]);
             break;
   case  8 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7]);
             break;
   case  9 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] );
             break;
   case 10 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9]);
             break;
   case 11 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10]);
             break;
   case 12 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11]);
             break;
   case 13 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12]);
             break;
   case 14 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13]);
             break;
   case 15 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14]);
             break;
   case 16 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15]);
             break;
   case 17 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16]);
             break;
   case 18 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17]);
             break;
   case 19 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18]);
             break;
   case 20 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19]);
             break;
   case 21 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20]);
             break;
   case 22 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21]);
             break;
   case 23 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22]);
             break;
   case 24 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23]);
             break;
   case 25 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24]);
             break;
   case 26 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25]);
             break;
   case 27 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26]);
             break;
   case 28 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27]);
             break;
   case 29 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28]);
             break;
   case 30 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29]);
             break;
   case 31 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30]);
             break;
   case 32 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31]);
             break;
   case 33 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32]);
             break;
   case 34 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33]);
             break;
   case 35 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34]);
             break;
   case 36 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35]);
             break;
   case 37 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36]);
             break;
   case 38 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36],p[37]);
             break;
   case 39 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36],p[37],p[38]);
             break;
   case 40 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36],p[37],p[38],p[39]);
             break;
   case 41 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36],p[37],p[38],p[39],
                  p[40]);
             break;
   case 42 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36],p[37],p[38],p[39],
                  p[40],p[41]);
             break;
   case 43 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36],p[37],p[38],p[39],
                  p[40],p[41],p[42]);
             break;
   case 44 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36],p[37],p[38],p[39],
                  p[40],p[41],p[42],p[43]);
             break;
   case 45 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36],p[37],p[38],p[39],
                  p[40],p[41],p[42],p[43],p[44]);
             break;
   case 46 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36],p[37],p[38],p[39],
                  p[40],p[41],p[42],p[43],p[44],p[45]);
             break;
   case 47 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36],p[37],p[38],p[39],
                  p[40],p[41],p[42],p[43],p[44],p[45],p[46]);
             break;
   case 48 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36],p[37],p[38],p[39],
                  p[40],p[41],p[42],p[43],p[44],p[45],p[46],p[47]);
             break;
   case 49 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36],p[37],p[38],p[39],
                  p[40],p[41],p[42],p[43],p[44],p[45],p[46],p[47],p[48]);
             break;
   case 50 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36],p[37],p[38],p[39],
                  p[40],p[41],p[42],p[43],p[44],p[45],p[46],p[47],p[48],p[49]);
             break;
   case 51 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36],p[37],p[38],p[39],
                  p[40],p[41],p[42],p[43],p[44],p[45],p[46],p[47],p[48],p[49],
                  p[50]);
             break;
   case 52 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36],p[37],p[38],p[39],
                  p[40],p[41],p[42],p[43],p[44],p[45],p[46],p[47],p[48],p[49],
                  p[50],p[51]);
             break;
   case 53 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36],p[37],p[38],p[39],
                  p[40],p[41],p[42],p[43],p[44],p[45],p[46],p[47],p[48],p[49],
                  p[50],p[51],p[52]);
             break;
   case 54 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36],p[37],p[38],p[39],
                  p[40],p[41],p[42],p[43],p[44],p[45],p[46],p[47],p[48],p[49],
                  p[50],p[51],p[52],p[53]);
             break;
   case 55 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36],p[37],p[38],p[39],
                  p[40],p[41],p[42],p[43],p[44],p[45],p[46],p[47],p[48],p[49],
                  p[50],p[51],p[52],p[53],p[54]);
             break;
   case 56 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36],p[37],p[38],p[39],
                  p[40],p[41],p[42],p[43],p[44],p[45],p[46],p[47],p[48],p[49],
                  p[50],p[51],p[52],p[53],p[54],p[55]);
             break;
   case 57 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36],p[37],p[38],p[39],
                  p[40],p[41],p[42],p[43],p[44],p[45],p[46],p[47],p[48],p[49],
                  p[50],p[51],p[52],p[53],p[54],p[55],p[56]);
             break;
   case 58 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36],p[37],p[38],p[39],
                  p[40],p[41],p[42],p[43],p[44],p[45],p[46],p[47],p[48],p[49],
                  p[50],p[51],p[52],p[53],p[54],p[55],p[56],p[57]);
             break;
   case 59 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36],p[37],p[38],p[39],
                  p[40],p[41],p[42],p[43],p[44],p[45],p[46],p[47],p[48],p[49],
                  p[50],p[51],p[52],p[53],p[54],p[55],p[56],p[57],p[58]);
             break;
   case 60 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36],p[37],p[38],p[39],
                  p[40],p[41],p[42],p[43],p[44],p[45],p[46],p[47],p[48],p[49],
                  p[50],p[51],p[52],p[53],p[54],p[55],p[56],p[57],p[58],p[59]);
             break;
   case 61 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36],p[37],p[38],p[39],
                  p[40],p[41],p[42],p[43],p[44],p[45],p[46],p[47],p[48],p[49],
                  p[50],p[51],p[52],p[53],p[54],p[55],p[56],p[57],p[58],p[59],
                  p[60]);
             break;
   case 62 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36],p[37],p[38],p[39],
                  p[40],p[41],p[42],p[43],p[44],p[45],p[46],p[47],p[48],p[49],
                  p[50],p[51],p[52],p[53],p[54],p[55],p[56],p[57],p[58],p[59],
                  p[60],p[61]);
             break;
   case 63 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36],p[37],p[38],p[39],
                  p[40],p[41],p[42],p[43],p[44],p[45],p[46],p[47],p[48],p[49],
                  p[50],p[51],p[52],p[53],p[54],p[55],p[56],p[57],p[58],p[59],
                  p[60],p[61],p[62]);
             break;
   case 64 : ileproc(p[0] ,p[1] ,p[2] ,p[3] ,p[4] ,p[5] ,p[6] ,p[7] ,p[8] ,p[9] ,
                  p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],p[18],p[19],
                  p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],
                  p[30],p[31],p[32],p[33],p[34],p[35],p[36],p[37],p[38],p[39],
                  p[40],p[41],p[42],p[43],p[44],p[45],p[46],p[47],p[48],p[49],
                  p[50],p[51],p[52],p[53],p[54],p[55],p[56],p[57],p[58],p[59],
                  p[60],p[61],p[62],p[63]);
             break;
   }
}
