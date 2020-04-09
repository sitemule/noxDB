// CMD:CRTCMOD 
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
// #include "rtvsysval.h"

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
BOOL RtvXlateTbl  (PUCHAR e2a , PUCHAR a2e , int AsciiCcsid, int EbcdicCcsid)
{

   PUCHAR pe2a = e2a;
   PUCHAR pa2e = a2e;
   QtqCode_T * tocode;
   QtqCode_T * fromcode;
   QtqCode_T ascii;
   QtqCode_T ebcdic;
   UCHAR  tbl[256];
   PUCHAR ptbl;
   iconv_t cd;
   int i;
   size_t inbytesleft, outbytesleft;

   for (i=0;i<256;i++) {
      tbl[i] = i;
   }
   memset(&ebcdic , 0, sizeof(ebcdic));
   ebcdic.CCSID = EbcdicCcsid;
   ebcdic.cnv_alternative = 0 ;
   ebcdic.subs_alternative = 0 ;
   ebcdic.shift_alternative = 0;
   ebcdic.length_option = 0;
   ebcdic.mx_error_option = 0;

   memset(&ascii , 0, sizeof(ascii));
   ascii.CCSID = AsciiCcsid;
   ascii.cnv_alternative = 0;
   ascii.subs_alternative = 0;
   ascii.shift_alternative = 0;
   ascii.length_option = 0;
   ascii.mx_error_option = 0;

   inbytesleft = 256;
   outbytesleft = 256;
   fromcode = &ebcdic;
   tocode = &ascii;
   ptbl = tbl;
   cd = QtqIconvOpen( tocode, fromcode);
   iconv (cd, &ptbl, &inbytesleft, &pe2a, &outbytesleft);
   iconv_close (cd);

   if (ChkUniqueTbl(e2a)) {
      for(i=0;i<256; i++) {
         a2e[e2a[i]] = i;
      }
   } else {
     inbytesleft = 256;
     outbytesleft = 256;
     fromcode = &ascii;
     tocode =  &ebcdic;
     ptbl = tbl;
     cd = QtqIconvOpen( tocode, fromcode);
     iconv (cd, &ptbl, &inbytesleft, &pa2e, &outbytesleft);
     iconv_close (cd);
     if (ChkUniqueTbl(a2e)) {
        for(i=0;i<256; i++) {
           e2a[a2e[i]] = i;
        }
     }
  }
  return (cd.return_value == -1);
}
/* ------------------------------------------------------------- */
iconv_t OpenXlate (int FromCcsid, int ToCcsid)
{

   QtqCode_T * tocode;
   QtqCode_T * fromcode;
   QtqCode_T fromccsid;
   QtqCode_T toccsid;
   iconv_t cd;
   int i;

   memset(&toccsid , 0, sizeof(toccsid));
   toccsid.CCSID = ToCcsid;
   toccsid.cnv_alternative = 0;
   toccsid.subs_alternative = 0 ;
   toccsid.shift_alternative = 0;
   toccsid.length_option = 0;
   toccsid.mx_error_option = 0;

   memset(&fromccsid , 0, sizeof(fromccsid));
   fromccsid.CCSID = FromCcsid;
   fromccsid.cnv_alternative = 0;
   fromccsid.subs_alternative = 0;
   fromccsid.shift_alternative = 0;
   fromccsid.length_option = 0;
   fromccsid.mx_error_option = 0;

   tocode = &toccsid;
   fromcode = &fromccsid;
   cd = QtqIconvOpen( tocode, fromcode);
   return cd;
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
  RtvXlateTbl  (e2a , a2e , 1252 , 277);
  printf (ChkUniqueTbl(e2a) ? "\nUnique" : "\nNot Unique");
  printf (ChkUniqueTbl(a2e) ? "\nUnique" : "\nNot Unique");
  RtvXlateTbl  (e2a , a2e , 1252 , 1252);
  printf (ChkUniqueTbl(e2a) ? "\nUnique" : "\nNot Unique");
  printf (ChkUniqueTbl(a2e) ? "\nUnique" : "\nNot Unique");
  RtvXlateTbl  (e2a , a2e , 1252 , 37);
  printf (ChkUniqueTbl(e2a) ? "\nUnique" : "\nNot Unique");
  printf (ChkUniqueTbl(a2e) ? "\nUnique" : "\nNot Unique");
  RtvXlateTbl  (e2a , a2e , 1252 , 850);
  printf (ChkUniqueTbl(e2a) ? "\nUnique" : "\nNot Unique");
  printf (ChkUniqueTbl(a2e) ? "\nUnique" : "\nNot Unique");
  */

}
#endif
