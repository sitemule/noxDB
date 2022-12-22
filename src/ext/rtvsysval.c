/* SYSIFCOPT(*IFSIO) TERASPACE(*YES *TSIFC) STGMDL(*INHERIT) */
//#define TESTMAIN
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>
#include <qwcrsval.h>
#include <qlgrtvdc.h>
#include <iconv.h>
#include <QTQICONV.h>
#include <ctype.h>
#include "ostypes.h"
#include "apierr.h"
#include "rtvsysval.h"

/* ------------------------------------------------------------- */
PUCHAR RtvSysVal(PUCHAR sysvalvalue, PUCHAR sysvalname)
{
   typedef _Packed struct {
     LONG numrtn;
     LONG offset;
     UCHAR payload[4096];
   } RCV, *PRCV;
   RCV rcv;
   Qwc_Rsval_Sys_Value_Table_t * prcvval;
   PUCHAR pvalue;

   APIERR apierr = {sizeof(APIERR),0,"",0,""};
   int i;
   for (i=0;i<10; i++) {
     sysvalname[i] = toupper(sysvalname[i]);
   }

   QWCRSVAL(&rcv , sizeof(rcv) , 1, sysvalname  , &apierr);
   if (apierr.avail > 0) {
     strcpy (sysvalvalue, "");
     return (sysvalvalue);
   }
   prcvval = (Qwc_Rsval_Sys_Value_Table_t *)  ((PUCHAR) &rcv  + rcv.offset);
   pvalue = (PUCHAR) prcvval + sizeof(*prcvval);

   if (prcvval->Type_Data == 'B') {
      sprintf(sysvalvalue, "%ld" , * (PLONG) pvalue );
   } else if (prcvval->Type_Data == 'C') {
   // left trim
      while (*pvalue == ' ' &&  prcvval->Length_Data > 0) {
         pvalue ++;
         prcvval->Length_Data --;
      }
      strncpy(sysvalvalue , pvalue , prcvval->Length_Data);
      sysvalvalue[prcvval->Length_Data] = '\0';
   } else {
     strcpy (sysvalvalue, "");
     return (sysvalvalue);
   }
   return (sysvalvalue);
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
  iconv_t cd = XlateOpenDescriptor (1208 , 0 , false);
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