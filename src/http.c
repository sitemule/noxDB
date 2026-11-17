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
     FILE * f;
     int l;
     LONG fileSize;
     PUCHAR p;
     f = fopen(file , options);
     if (f == NULL) return NULL;
     fseek(f, 0L, SEEK_END);
     fileSize = ftell(f);
     if (fileSize <= 0) {
        fclose(f);
        return NULL;
     }
     fseek(f, 0L, SEEK_SET);
     // The file size is in bytes; room for all of them and the terminator
     p = memAlloc(fileSize + 1);
     l = fread(p, 1 , fileSize , f);
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
   Split them into words the way the shell would and pass each word quoted -
   so the words reach curl, but nothing in them is run by the shell:
   - words are separated by blanks, tabs and line breaks
   - '...' is taken as it is
   - "..." too, except that a backslash before " or a backslash is removed
   - outside quotes a backslash makes the next character an ordinary one
   No $NAME, $( ), ` ` or ~ expansion. "bs" is the job CCSID's backslash
   (a variant character). Note: they are still curl options - an
   application must not build them from untrusted input.
   --------------------------------------------------------------------------- */
static BOOL isShellBlank (UCHAR c)
{
   return (c == ' ' || c == '\t' || c == '\n' || c == '\r');
}
static PUCHAR putShellOptions (PUCHAR p, PUCHAR opt, UCHAR bs)
{
   for (;;) {
      UCHAR quote = 0;
      for (; isShellBlank(*opt) ; opt++);
      if (*opt == '\0') break;
      *(p++) = ' ';
      *(p++) = '\'';
      for (; *opt ; opt++) {
         if (quote == '\'') {
            if (*opt == quote) {
               quote = 0;
            } else {
               p = putShellChar (p , *opt);
            }
         } else if (quote == '"') {
            if (*opt == quote) {
               quote = 0;
            } else if (*opt == bs && (opt[1] == '"' || opt[1] == bs)) {
               p = putShellChar (p , *(++opt));
            } else {
               p = putShellChar (p , *opt);
            }
         } else if (*opt == bs) {
            if (opt[1] == '\0') break;     // a backslash at the end: nothing
            p = putShellChar (p , *(++opt));
         } else if (*opt == '\'' || *opt == '"') {
            quote = *opt;
         } else if (isShellBlank(*opt)) {
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
PJXNODE jx_httpRequest (PUCHAR url, PJXNODE pNode, PUCHAR options , PUCHAR format)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PUCHAR  cmd;
   PUCHAR  p;
   UCHAR   temp1[256];
   UCHAR   temp2[256];
   UCHAR   error[256];
   PJXNODE pRes;
   UCHAR   at;
   UCHAR   bs;
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
	XlateBufferQ(&at  , "@" , 1, 1252 ,0 ); ;
	XlateBufferQ(&bs  , "\\" , 1, 1252 ,0 ); // and of a backslash
	#pragma convert(0)


   if ( pParms->OpDescList->NbrOfParms < 2 )  pNode = NULL;
   if ( pParms->OpDescList->NbrOfParms < 3 || options == NULL) options = "";

   // fixed text, three file names and every quoted character up to 5 bytes
   cmd = memAlloc (2048 + 3 * sizeof(temp1) + 5 * (strlen(url) + strlen(options)));
   p = cmd;

   // Temporary names for input, output and error stream files
   tmpnam(temp1);
   tmpnam(temp2);
   tmpnam(error);

   // Build the cur command, note: ignore sertificate error due to IBM i implementation
   // -q (first): no .curlrc - the profile's curl defaults must not change the request
   p += sprintf( p , "curl -q -s -k -o %s", temp2);

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
      // Default to post in not given in options
      if (strstr(options, "-X ") == NULL) {
         p += sprintf( p , " -X POST ");
      }
      p += sprintf( p , " --data %c%s " , at , temp1);
   }

   // "Content-type" and "Accept" defaults can be overwritten by the "options" if given,
   switch (dataFormat) {
      case FMT_JSON:
         p += sprintf( p ,  " %s %s ",
            (stristr(options, "-H 'Content-Type:") == NULL) ? "-H 'Content-Type: application/json' " :"",
            (stristr(options, "-H 'Accept:") == NULL) ? "-H 'Accept: application/json' ":""
         );
         break;
      case FMT_XML:
         p += sprintf( p ,  " %s %s ",
            (stristr(options, "-H 'Content-Type:") == NULL) ? "-H 'Content-Type: application/soap+xml' " :"",
            (stristr(options, "-H 'Accept:") == NULL) ? "-H 'Accept: application/soap+xml,application/xml' ":""
         );
         break;
      case FMT_TEXT:
         // NOP!!
         break;
   }

   p = putShellOptions (p , options, bs);
   // --url: the url is never taken as a curl option, even if it starts with -
   p += sprintf( p ,  " --url ");
   p = putShellQuoted (p , url);
   p += sprintf( p ,  " 2>%s;", error);
   p += sprintf( p , "setccsid 1208 %s" , temp2);

   shell (cmd);
   memFree (&cmd);

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
