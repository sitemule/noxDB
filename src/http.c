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

// #include <errno.h>

#include <sys/stat.h>
#include "ostypes.h"
#include "varchar.h"
#include "xlate.h"
#include "parms.h"
#include "memUtil.h"
#include "noxDbUtf8.h"

// ---------------------------------------------------------------------------
PUCHAR loadText (PUCHAR file)
{
     PUCHAR p = malloc(320000);
     FILE * f;
     int l;
     f = fopen(file , "rb");
     l = fread(p, 1 , 320000 , f);
     fclose(f);
     if (l<= 0) {
        free(p);
        return(NULL);
     }
     p[l] = '\0';
     return p;
}
// ---------------------------------------------------------------------------
void sh (PUCHAR cmd)
{
   QP2SHELL  ("/QOpenSys/usr/bin/sh", "-c" , cmd);
}
/* ---------------------------------------------------------------------------
   get a resource on the net
   --------------------------------------------------------------------------- */
PNOXNODE nox_httpRequest (PLVARCHAR urlP, PNOXNODE pNode, PLVARCHAR optionsP)
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
   UCHAR options [8000];

   // Setup parameters:
   Xlatestr (url  , plvc2str (urlP) , 1208 , 0);

   if ( pParms->OpDescList->NbrOfParms < 2 )  pNode = NULL;

   if ( pParms->OpDescList->NbrOfParms < 3 ) {
      options [0] = '\0';
   } else {
      Xlatestr (options , plvc2str(optionsP) , 1208 , 0);
   }

   // Get the job version of a @
   #pragma convert(1252)
   Xlatestr (at , "@" , 1252 , 0);
   #pragma convert(0)

   // Build workfile names:
   tmpnam(temp1);
   tmpnam(temp2);
   tmpnam(error);

   // buiild the script / curl command
   p += sprintf( p , "touch -c 1208 %s;" , temp2);
   p += sprintf( p , "/QOpenSys/pkgs/bin/curl -k --silent --show-error -o %s", temp2);

   if (pNode) {
      // The positive value causes it to not produce BOM code
      nox_WriteJsonStmf (pNode , temp1 , 1208, ON ,NULL);
      p += sprintf( p , " -X POST --data-binary %s%s " , at, temp1);
   }
   p += sprintf( p ,  " %s ",
      "-H 'Content-Type: application/json; charset=utf-8' "
      "-H 'Accept: application/json' "
   );
   if (options) {
      p += sprintf( p , " %s "  , options);
   }
   p += sprintf( p ,  " %s --stderr %s;",  url , error);
   p += sprintf( p , "setccsid 1208 %s" , temp2);

   // Run the script
   sh (cmd);

   // Process the response:
   p =  loadText(error);
   if (p != NULL) {
      pRes = nox_NewObject();
      #pragma convert(1252)
      nox_SetValueByName(pRes , "success"  , "false" , LITERAL);
      nox_SetValueByName(pRes , "reason" , p , VALUE );
      #pragma convert(0)
      free(p);
   } else {
      pRes = nox_ParseFile (temp2);
      if (pRes == NULL) {
         pRes = nox_NewObject();
         p =  loadText(temp2);
         #pragma convert(1252)
         nox_SetValueByName(pRes , "success"  , "true" , LITERAL);
         nox_SetValueByName(pRes , "data" , p , VALUE );
         #pragma convert(0)
         free(p);
      }
   }
   // Clean up
   unlink (temp1);
   unlink (temp2);
   unlink (error);
   return pRes;
}

