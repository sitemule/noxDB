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

#include <sys/stat.h>
#include "ostypes.h"
#include "varchar.h"
#include "xlate.h"
#include "parms.h"
#include "memUtil.h"
#include "strUtil.h"
#define NOX_BUILD
#include "noxDbUtf8.h"

extern  iconv_t xlate_1208_to_job;

// ---------------------------------------------------------------------------
PUCHAR loadText (PUCHAR file, PUCHAR options)
{
   FILE* f;
   int l;
   f = fopen(file , options);
   fseek(f, 0L, SEEK_END);
   int fileSize = ftell(f);
   if (fileSize <= 0) {
      fclose(f);
      return NULL;
   }
   PUCHAR p = memAlloc(fileSize + 1);
   fseek(f, 0L, SEEK_SET);
   l = fread(p, 1 , fileSize , f);
   fclose(f);
   p[l] = '\0';
   return p;
}
// ---------------------------------------------------------------------------
PLVARCHAR loadVC (PUCHAR file)
{
   FILE* f;
   int l;

   f = fopen(file , "rb");
   fseek(f, 0L, SEEK_END);
   int fileSize = ftell(f);
   if (fileSize <= 0) {
      fclose(f);
      return NULL;
   }

   PUCHAR p = memAlloc(fileSize);
   PLVARCHAR ret = (PLVARCHAR) (p - sizeof(ULONG));

   fseek(f, 0L, SEEK_SET);
   l = fread(p, 1 , fileSize , f);
   fclose(f);
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
   The curl command runs through "sh -c": every argument we put on that
   command line is single quoted, so the shell sees no $( ) ` ; | & < > or
   blanks in it. A ' in the text becomes '"'"' (end quote, a quoted ', quote).
   --------------------------------------------------------------------------- */
static PUCHAR putShellChar (PUCHAR p, UCHAR c)
{
   if (c == '\'') {
      memcpy (p , "'\"'\"'" , 5);
      return p + 5;
   }
   *p = c;
   return p + 1;
}
static PUCHAR putShellQuoted (PUCHAR p, PUCHAR s)
{
   *(p++) = '\'';
   for (; *s ; s++) p = putShellChar (p , *s);
   *(p++) = '\'';
   *(p++) = ' ';
   return p;
}
/* ---------------------------------------------------------------------------
   "options" are curl options, i.e.: -H 'Authorization: Bearer x' -X PUT
   Split them into words the way the shell would (blanks, '...' and "...")
   and pass each word quoted - so the words reach curl, but nothing in them
   is run by the shell. Note: they are still curl options - an application
   must not build them from untrusted input.
   --------------------------------------------------------------------------- */
static PUCHAR putShellOptions (PUCHAR p, PUCHAR opt)
{
   for (;;) {
      UCHAR quote = 0;
      for (; *opt == ' ' ; opt++);
      if (*opt == '\0') break;
      *(p++) = ' ';
      *(p++) = '\'';
      for (; *opt ; opt++) {
         if (quote) {
            if (*opt == quote) {
               quote = 0;
            } else {
               p = putShellChar (p , *opt);
            }
         } else if (*opt == '\'' || *opt == '"') {
            quote = *opt;
         } else if (*opt == ' ') {
            break;
         } else {
            p = putShellChar (p , *opt);
         }
      }
      *(p++) = '\'';
      *(p++) = ' ';
   }
   return p;
}
/* ---------------------------------------------------------------------------
   get a resource on the net
   --------------------------------------------------------------------------- */
PNOXNODE nox_httpRequest (PLVARCHAR urlP, PNOXNODE pNode, PUCHAR  options, PUCHAR format)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PUCHAR  cmd;
   PUCHAR  p;
   UCHAR   temp1[256];
   UCHAR   temp2[256];
   UCHAR   error[256];
   UCHAR   at [2];
   PUCHAR  url;
   PNOXNODE  pRes;

   NOX_DATAFORMAT dataFormat = NOX_FMT_JSON;

   if (pParms->OpDescList->NbrOfParms >= 4) {
      if  (stricmp (format , "XML") == 0) {
         dataFormat = NOX_FMT_XML;
      }
      else if  (stricmp (format , "TEXT") == 0) {
         dataFormat = NOX_FMT_TEXT;
      }
   }

   if ( pParms->OpDescList->NbrOfParms < 2 )  pNode = NULL;
   if ( pParms->OpDescList->NbrOfParms < 3 || options == NULL) options = "";

   // Setup parameters - buffers sized from the input
   // (UTF-8 to the job CCSID: at most 3 bytes out for each byte in)
   url = memAlloc (urlP->Length * 3 + 1);
   XlateString (xlate_1208_to_job , url  , plvc2str (urlP) );
   // fixed text, three file names and every quoted character up to 5 bytes
   cmd = memAlloc (2048 + 3 * sizeof(temp1) + 5 * (strlen(url) + strlen(options)));
   p = cmd;

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

      if (pNode->signature != NOX_NODESIG) {
         saveVC  (temp1 , (PLVARCHAR) pNode);
      } else if (dataFormat == NOX_FMT_JSON) {
         nox_WriteJsonStmf (pNode , temp1 , -1208, ON ,NULL);
      } else if ( dataFormat == NOX_FMT_XML) {
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
      case NOX_FMT_JSON:
         p += sprintf( p ,  " %s %s ",
            (strIstr(options, "-H 'Content-Type:") == NULL) ? "-H 'Content-Type: application/json' " :"",
            (strIstr(options, "-H 'Accept:") == NULL) ? "-H 'Accept: application/json' ":""
         );
         break;
      case NOX_FMT_XML:
         p += sprintf( p ,  " %s %s ",
            (strIstr(options, "-H 'Content-Type:") == NULL) ? "-H 'Content-Type: application/soap+xml' " :"",
            (strIstr(options, "-H 'Accept:") == NULL) ? "-H 'Accept: application/soap+xml,application/xml' ":""
         );
         break;
      case NOX_FMT_TEXT:
         // NOP!!
         break;
   }

   p = putShellOptions (p , options);
   // --url: the url is never taken as a curl option, even if it starts with -
   p += sprintf( p ,  " --url ");
   p = putShellQuoted (p , url);
   p += sprintf( p ,  " --stderr %s;", error);
   p += sprintf( p , "setccsid 1208 %s" , temp2);

   // Run the script
   sh (cmd);
   memFree (&cmd);
   memFree (&url);

   // Process the response:
   p =  loadText(error,"rb");
   if (p != NULL) {
      pRes = nox_NewObject();
      #pragma convert(1252)
      nox_SetValueByName(pRes , "success"  , "false" , NOX_LITERAL);
      nox_SetValueByName(pRes , "reason" , p , NOX_VALUE );
      #pragma convert(0)
      memFree(&p);
   } else {
      if (dataFormat == NOX_FMT_JSON
      ||  dataFormat == NOX_FMT_XML) {
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

