/* SYSIFCOPT(*IFSIO) TERASPACE(*YES *TSIFC) STGMDL(*SNGLVL)      */
/* SYSIFCOPT(*IFSIO) TERASPACE(*YES *TSIFC) STGMDL(*SNGLVL)      */
/* COMPILEOPT('OUTPUT(*PRINT) OPTION(*EXPMAC *SHOWINC)')         */
/* Program . . . : JXM002                                        */
/* Design  . . . : Niels Liisberg                                */
/* Function  . . : SQL database I/O                              */
/*                                                               */
/*  SQLCLI documentation:


https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_73/cli/rzadphdapi.htm?lang=da
                                                                */
/* By     Date       PTF     Description                         */
/* NL     21.10.2006         New program                         */
/* NL     16.10.2014         Added to JSONXML library            */
/* ------------------------------------------------------------- */

#include <unistd.h>
#include <wchar.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <decimal.h>
#include <stdarg.h>
#include <ctype.h>
#include "ostypes.h"
#include "xlate.h"
#include "varchar.h"
#include "MinMax.h"
#include "parms.h"
#include "utl100.h"
#include "jsonxml.h"
#include "mem001.h"
#include "timestamp.h"

#define IS_NULL -1

// Globlas: TODO !!! remove to make code reintrant
extern UCHAR jxMessage[512];
extern BOOL  jxError;
extern UCHAR BraBeg;
extern UCHAR CurBeg;
extern UCHAR Dollar;

extern UCHAR jobSlash       ;
extern UCHAR jobBackSlash   ;
extern UCHAR jobMasterspace ;
extern UCHAR jobBraBeg      ;
extern UCHAR jobBraEnd      ;
extern UCHAR jobCurBeg      ;
extern UCHAR jobCurEnd      ;
extern UCHAR jobDollar      ;

static PJXNODE pMemRef= null;

/* ------------------------------------------------------------- */
PJXNODE jx_cvtNodeOffset2Ptr (INT64 offset)
{
   PUCHAR newRef;
   if (offset == 0LL) return null;
   if (pMemRef == null) pMemRef = memAlloc(1);
   newRef = (PUCHAR) pMemRef - offset;
   return (PJXNODE) newRef;
}
/* ------------------------------------------------------------- */
INT64   jx_cvtNodePtr2Offset (PJXNODE pNode) 
{
   INT64 offset;
   if (pNode == null) return 0LL;
   if (pMemRef == null) pMemRef = memAlloc(1);
   offset = (PUCHAR) pMemRef - (PUCHAR) pNode;
   return offset;
}

/* ------------------------------------------------------------- */
// UDTF wrappers 
/* ------------------------------------------------------------- */
VOID  jx_noxGetStr (                                   
   // Input parameters                               
   PINT64  oNode, PUCHAR pProptery, PUCHAR pDefault,           
                                                     
   // Returns:                                       
   PUCHAR result,                                 
                                                     
   // Indicators for inputs                          
   PSHORT isNull1, PSHORT isNull2, PSHORT isNull3,    

   // Indicators for result 
   PSHORT isNullResult,
                                                     
   // Std parameters from UDF - SQL style 
   UCHAR        sqlState [5] ,                            
   PUCHAR       function [517],                            
   PUCHAR       specific [128],                            
   PUCHAR       errorMsg [1000]
)                            
{ 
   PJXNODE pRootNode = jx_cvtNodeOffset2Ptr (*oNode);   
   PJXNODE pNode     = jx_GetNode(pRootNode, pProptery);
   if  ( pNode == null) { 
      if (* isNull3 == IS_NULL) {
         *isNullResult = IS_NULL;
      } else {
         strcpy ( result , pDefault);
      }
   } else if  ( *pNode->Value  == null) {
      *isNullResult = IS_NULL;
   } else {
      strcpy ( result , pNode->Value);
   }
}
/* ------------------------------------------------------------- */
VOID  jx_noxGetNum (                                   
   // Input parameters                               
   PINT64  oNode, PUCHAR pProptery, PFIXEDDEC  pDefault,           
                                                     
   // Returns:                                       
   PFIXEDDEC result,                                 
                                                     
   // Indicators for inputs                          
   PSHORT isNull1, PSHORT isNull2, PSHORT isNull3,    

   // Indicators for result 
   PSHORT isNullResult,
                                                     
   // Std parameters from UDF - SQL style 
   UCHAR        sqlState [5] ,                            
   PUCHAR       function [517],                            
   PUCHAR       specific [128],                            
   PUCHAR       errorMsg [1000]
)                            
{ 
   PJXNODE pRootNode = jx_cvtNodeOffset2Ptr (*oNode);   
   PJXNODE pNode     = jx_GetNode(pRootNode, pProptery);
   if  ( pNode == null) { 
      if (* isNull3 == IS_NULL) {
         *isNullResult = IS_NULL;
      } else {
         *result = *pDefault;
      }
   } else if  ( *pNode->Value  == null) {
      *isNullResult = IS_NULL;
   } else {
      *result = jx_Num (pNode->Value);
   }
}