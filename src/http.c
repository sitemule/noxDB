// CMD:CRTCMOD
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
#include <qp2shell.h>
#include <unistd.h>
#include <iconv.h>


// #include <errno.h>

#include <sys/stat.h>
#include "ostypes.h"
#include "varchar.h"
#include "xlate.h"
#include "parms.h"
#include "memUtil.h"
#include "strUtil.h"
#include "noxDbUtf8.h"

extern  iconv_t xlate_1208_to_job;

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
PLVARCHAR loadVC (PUCHAR file)
{

     FILE* f = fopen(file , "rb");
     fseek(f, 0L, SEEK_END);
     int fileSize = ftell(f);
     PUCHAR p = memAlloc(fileSize);
     PLVARCHAR ret = (PLVARCHAR) (p - sizeof(ULONG));

     fseek(f, 0L, SEEK_SET);
     int l = fread(p, 1 , fileSize , f);
     fclose(f);
     if (l<= 0) {
        memFree(&p);
        return(NULL);
     }
     return ret; // memAlloc has the length just before the payload
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
// ---------------------------------------------------------------------------
void saveVC  (PUCHAR file , PLVARCHAR data)
{
     FILE * f;
     int l;
     f = fopen(file , "wb,o_ccsid=1208");
     l = fwrite (data->String, 1 , data->Length , f);
     fclose(f);
}
// ---------------------------------------------------------------------------
void sh (PUCHAR cmd)
{
   QP2SHELL  ("/QOpenSys/usr/bin/sh", "-c" , cmd);
}
/* ---------------------------------------------------------------------------
   get a resource on the net
   --------------------------------------------------------------------------- */
PNOXNODE nox_httpRequest (PLVARCHAR urlP, PNOXNODE pNode, PUCHAR  options, PUCHAR format)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   UCHAR   cmd [8000];
   PUCHAR  p = cmd;
   UCHAR   temp1[256];
   UCHAR   temp2[256];
   UCHAR   error[256];
   UCHAR   at [2];
   UCHAR   url  [8000];
   PNOXNODE  pRes;

   DATAFORMAT dataFormat = FMT_JSON;

   if (pParms->OpDescList->NbrOfParms >= 4) {
      if  (stricmp (format , "XML") == 0) {
         dataFormat = FMT_XML;
      }
      else if  (stricmp (format , "TEXT") == 0) {
         dataFormat = FMT_TEXT;
      }
   }

   // Setup parameters:
   XlateString (xlate_1208_to_job , url  , plvc2str (urlP) );

   if ( pParms->OpDescList->NbrOfParms < 2 )  pNode = NULL;
   if ( pParms->OpDescList->NbrOfParms < 3 || options == NULL) options = "";

   // Get the job version of a @
   #pragma convert(1252)
   XlateString (xlate_1208_to_job , at , "@" );
   #pragma convert(0)

   // Build workfile names:
   tmpnam(temp1);
   tmpnam(temp2);
   tmpnam(error);

   // buiild the script / curl command
   p += sprintf( p , "touch -c 1208 %s;" , temp2);
   p += sprintf( p , "/QOpenSys/pkgs/bin/curl -k --silent --show-error -o %s", temp2);

   if (pNode) {

      if (pNode->signature != NODESIG) {
         saveVC  (temp1 , (PLVARCHAR) pNode);
      } else if (dataFormat == FMT_JSON) {
         nox_WriteJsonStmf (pNode , temp1 , -1208, ON ,NULL);
      } else if ( dataFormat == FMT_XML) {
         nox_WriteXmlStmf (pNode , temp1 , -1208, ON ,NULL);
      }
      // Default to post in not given in options
      if (strstr(options, "-X ") == NULL) {
         p += sprintf( p , " -X POST ");
      }
      p += sprintf( p , " --data %s%s " , at , temp1);
   }

   // "Content-type" and "Accept" defaults can be overwritten by the "options" if given,
   switch (dataFormat) {
      case FMT_JSON:
         p += sprintf( p ,  " %s %s ",
            (strIstr(options, "-H 'Content-Type:") == NULL) ? "-H 'Content-Type: application/json' " :"",
            (strIstr(options, "-H 'Accept:") == NULL) ? "-H 'Accept: application/json' ":""
         );
         break;
      case FMT_XML:
         p += sprintf( p ,  " %s %s ",
            (strIstr(options, "-H 'Content-Type:") == NULL) ? "-H 'Content-Type: application/soap+xml' " :"",
            (strIstr(options, "-H 'Accept:") == NULL) ? "-H 'Accept: application/soap+xml,application/xml' ":""
         );
         break;
      case FMT_TEXT:
         // NOP!!
         break;
   }

   if (options) {
      p += sprintf( p , " %s "  , options);
   }
   p += sprintf( p ,  " %s --stderr %s;",  url , error);
   p += sprintf( p , "setccsid 1208 %s" , temp2);

   // Run the script
   sh (cmd);

   // Process the response:
   p =  loadText(error,"rb");
   if (p != NULL) {
      pRes = nox_NewObject();
      #pragma convert(1252)
      nox_SetValueByName(pRes , "success"  , "false" , LITERAL);
      nox_SetValueByName(pRes , "reason" , p , VALUE );
      #pragma convert(0)
      free(p);
   } else {
      if (dataFormat == FMT_JSON
      ||  dataFormat == FMT_XML) {
         pRes = nox_ParseFile (temp2 );
      } else {
         pRes = (PNOXNODE) loadVC(temp2);
      }
   }
   // Clean up
   unlink (temp1);
   unlink (temp2);
   unlink (error);
   return pRes;
}

