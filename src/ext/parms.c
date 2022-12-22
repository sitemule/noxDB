/* SYSIFCOPT(*IFSIO) TERASPACE(*YES *TSIFC) STGMDL(*INHERIT) */
//#define TESTMAIN
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>
#include <limits.h>
#include <qwcrsval.h>
#include <qlgrtvdc.h>
#include <ctype.h>
#include "ostypes.h"
#include "apierr.h"
#include "xlate.h"
#include "rtvsysval.h"

/* ------------------------------------------------------------- */
int RtvDftCCSID (void)
{
   APIERR apierr = {sizeof(APIERR),0,"",0,""};
   UCHAR  LanguageID [4];
   int    ccsid=0;
   RtvSysVal (LanguageID, "QLANGID   ");
   QLGRTVDC (&ccsid ,LanguageID , &apierr);
   return ccsid;
}
/* ------------------------------------------------------------- */
/* Not used; but can be put into to the debug flow               */
/* ------------------------------------------------------------- */
BOOL ChkUniqueTbl(PUCHAR tbl)
{
   int i, j;
   for (i=0;i<256;i++) {
     for (j=0;j<256;j++) {
       if (tbl[i] == tbl[j] && i != j) {
          return FALSE; // Not unique
       }
     }
   }
   return TRUE;
}
 

/* ------------------------------------------------------------- */
#ifdef TESTMAIN
void main(void) {
  UCHAR buf [256];
  UCHAR a2e [256];
  UCHAR e2a [256];
  size_t  l1 , l2;
  UCHAR buf1[10] , buf2[10];
  PUCHAR p1, p2;
  iconv_t cd = OpenXlate (1208 , 0 );
  p1 = buf1; p2 = buf2;
  l1 = 3 ;  l2 =10;
  #pragma convert(1252)
  buf1[0] = 'a';
  buf1[1] = 'Æ';
  buf1[2] = 'b';
  #pragma convert(0)
  iconv (cd, &p1 , &l1 , &p2 , &l2);
  iconv_close (cd);

  /*
  printf("\n%s", RtvSysVal(buf, "QTIME     " ));
  printf("\n%s", RtvSysVal(buf, "QDAY      " ));
  printf("\n%s", RtvSysVal(buf, "QYEAR     " ));
  printf("\n%s", RtvSysVal(buf, "QDAYOFWEEK" ));
  printf("\n%s%s", RtvSysVal(buf, "QDAYOFWEEK" ),  RtvSysVal(buf, "QDAYOFWEEK" ));
  printf("\nDefault CCSID: %ld" , RtvDftCCSID());
  printf("\n");
  XlateGetStaticConversionTables  (e2a , a2e , 1252 , 277);
  printf (ChkUniqueTbl(e2a) ? "\nUnique" : "\nNot Unique");
  printf (ChkUniqueTbl(a2e) ? "\nUnique" : "\nNot Unique");
  XlateGetStaticConversionTables  (e2a , a2e , 1252 , 1252);
  printf (ChkUniqueTbl(e2a) ? "\nUnique" : "\nNot Unique");
  printf (ChkUniqueTbl(a2e) ? "\nUnique" : "\nNot Unique");
  XlateGetStaticConversionTables  (e2a , a2e , 1252 , 37);
  printf (ChkUniqueTbl(e2a) ? "\nUnique" : "\nNot Unique");
  printf (ChkUniqueTbl(a2e) ? "\nUnique" : "\nNot Unique");
  XlateGetStaticConversionTables  (e2a , a2e , 1252 , 850);
  printf (ChkUniqueTbl(e2a) ? "\nUnique" : "\nNot Unique");
  printf (ChkUniqueTbl(a2e) ? "\nUnique" : "\nNot Unique");
  */

}
#endif
