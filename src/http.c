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
PUCHAR loadText (PUCHAR file)
{
     PUCHAR p = malloc(32000);
     FILE * f;
     int l;
     f = fopen(file , "r");
     l = fread(p, 1 , 32000 , f);
     fclose(f);
     if (l<= 0) {
        free(p);
        return(NULL);
     }
     p[l] = '\0';
     return p;
}
// ---------------------------------------------------------------------------
void qsh (PUCHAR cmd)
{
   VOID RUNQSH  (PUCHAR cmd);
   UCHAR cmdP [4097];
   padncpy ( cmdP , cmd , 4096);
   RUNQSH  (cmd);
}
/* ---------------------------------------------------------------------------
   get a resource on the net
   --------------------------------------------------------------------------- */
PJXNODE jx_httpRequest (PUCHAR url, PJXNODE pNode, PUCHAR options)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   UCHAR   cmd [4097];
   PUCHAR  p = cmd;
   UCHAR   temp1[256];
   UCHAR   temp2[256];
   UCHAR   error[256];
   PJXNODE pRes;
   UCHAR   at;

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
       jx_WriteJsonStmf (pNode , temp1 , -1208, ON ,NULL);
       p += sprintf( p , " -X POST --data %c%s " , at , temp1);
   }
   p += sprintf( p ,  " %s ",
      "-H 'Content-Type: application/json' "
      "-H 'Accept: application/json' "
   );
   if (options) {
       p += sprintf( p , " %s "  , options);
   }
   p += sprintf( p ,  " %s 2>%s;",  url , error);
   p += sprintf( p , "setccsid 1208 %s" , temp2);
   qsh (cmd);

   p =  loadText(error);
   if (p != NULL) {
      pRes = jx_NewObject(NULL);
      jx_SetValueByName(pRes , "success"  , "false" , LITERAL);
      jx_SetValueByName(pRes , "reason" , p , VALUE );
      free(p);
   } else {
      pRes = jx_ParseFile (temp2 , NULL);
   }
   unlink (temp1);
   unlink (temp2);
   unlink (error);
   return pRes;
}
