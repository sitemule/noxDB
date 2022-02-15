/* SYSIFCOPT(*IFSIO) TERASPACE(*YES *TSIFC) STGMDL(*SNGLVL) */
/* ------------------------------------------------------------- *
 * Company . . . : System & Method A/S                           *
 * Design  . . . : Niels Liisberg                                *
 * Function  . . : http handler                                  *
 * ------------------------------------------------------------- */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h>
#include <leod.h>
#include <decimal.h>
#include <wchar.h>
#include <qp2shell2.h>

// #include <errno.h>

#include <sys/stat.h>
#include "ostypes.h"
#include "xlate.h"
#include "jsonxml.h"
#include "parms.h"
#include "utl100.h"
#include "mem001.h"
#include "varchar.h"

// ---------------------------------------------------------------------------
PUCHAR loadText (PUCHAR file, PUCHAR options)
{
     PUCHAR p = memAlloc(1048576);
     FILE * f;
     int l;
     f = fopen(file , options);
     l = fread(p, 1 , 1048576 , f);
     fclose(f);
     if (l<= 0) {
        memFree(&p);
        return(NULL);
     }
     p[l] = '\0';
     return p;
}
// ---------------------------------------------------------------------------
void saveText (PUCHAR file , PUCHAR data)
{
     FILE * f;
     int l;
     f = fopen(file , "wt,o_ccsid=1208");
     l = fwrite (data, 1 , strlen(data) , f);
     fclose(f);
}
/* ---------------------------------------------------------------------------
   Run a schell script 
   --------------------------------------------------------------------------- */
void shell (PUCHAR cmd)
{
   QP2SHELL2  ("/QOpenSys/usr/bin/sh" , "-c" , cmd);
}
/* ---------------------------------------------------------------------------
   get a resource on the net
   --------------------------------------------------------------------------- */
PJXNODE jx_httpRequest (PUCHAR url, PJXNODE pNode, PUCHAR options , PUCHAR format)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   UCHAR   cmd [4097];
   PUCHAR  p = cmd;
   UCHAR   temp1[256];
   UCHAR   temp2[256];
   UCHAR   error[256];
   PJXNODE pRes;
   UCHAR   at;
   DATAFORMAT dataFormat = FMT_JSON;

   if (pParms->OpDescList->NbrOfParms >= 4) {
      if  (stricmp (format , "XML") == 0) {
         dataFormat = FMT_XML;
      } 
      else if  (stricmp (format , "TEXT") == 0) {
         dataFormat = FMT_TEXT;
      }
   }


   // Need a runtime version of the @ char
   #pragma convert(1252)
	XlateBuf(&at  , "@" , 1, 1252 ,0 ); ;
	#pragma convert(0)


   if ( pParms->OpDescList->NbrOfParms < 2 )  pNode = NULL;
   if ( pParms->OpDescList->NbrOfParms < 3 )  options = NULL;

   tmpnam(temp1);
   tmpnam(temp2);
   tmpnam(error);

   p += sprintf( p , "curl -s -k -o %s", temp2);
   
   if (pNode) {
      // The negative causes it not to produce BOM code
      switch (dataFormat) {
         case FMT_JSON:
            jx_WriteJsonStmf (pNode , temp1 , -1208, ON ,NULL);
            break;
         case FMT_XML:
            jx_WriteXmlStmf (pNode , temp1 , -1208, ON ,NULL);
            break;
         case FMT_TEXT:
            saveText (temp1 , (PUCHAR) pNode);
            break;
      }
      p += sprintf( p , " -X POST --data %c%s " , at , temp1);
   }

   switch (dataFormat) {
      case FMT_JSON:
         p += sprintf( p ,  " %s ",
            "-H 'Content-Type: application/json' "
            "-H 'Accept: application/json' "
         );
         break;
      case FMT_XML:
         p += sprintf( p ,  " %s ",
            "-H 'Content-Type: application/soap+xml' "
            "-H 'Accept: application/soap+xml' "
         );
         break;
      case FMT_TEXT:
         // NOP!!
         break;
   }

   if (options) {
       p += sprintf( p , " %s "  , options);
   }
   p += sprintf( p ,  " %s 2>%s;",  url , error);
   p += sprintf( p , "setccsid 1208 %s" , temp2);
   shell (cmd);

   p =  loadText(error,"rb");
   if (p != NULL) {
      pRes = jx_NewObject(NULL);
      jx_SetValueByName(pRes , "success"  , "false" , LITERAL);
      jx_SetValueByName(pRes , "reason" , p , VALUE );
      memFree(&p);
   } else {
      if (dataFormat == FMT_JSON
      ||  dataFormat == FMT_XML) {
         pRes = jx_ParseFile (temp2 , NULL);
      } else {
         pRes = (PJXNODE) loadText(temp2,"r,o_ccsid=0");
      }
   }
   unlink (temp1);
   unlink (temp2);
   unlink (error);
   return pRes;
}
