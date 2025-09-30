// CMD:CRTCMOD
/* ------------------------------------------------------------- */
/* Program . . . : System column name sqlio                      */
/* Design  . . . : Niels Liisberg                                */
/* Function  . . : SQL database I/O                              */
/*                                                               */
/*  SQLCLI documentation:

https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_73/cli/rzadphdapi.htm?lang=da
                                                                */
/* By     Date       PTF     Description                         */
/* NL     30.09.2025         New program                         */
/* ------------------------------------------------------------- */

#include <unistd.h>
#include <wchar.h>
#include <stdio.h>
#include <stdlib.h>
#include <decimal.h>
#include <recio.h>
#include <errno.h>

#include "ostypes.h"
#include "varchar.h"
#include "e2aa2e.h"
#include "xlate.h"
#include "strutil.h"
#include "noxDbUtf8.h"
#include "sndpgmmsg.h"
// ------------------------------------------------------------------
PUCHAR getSystemColumnName ( PUCHAR sysColumnName, PUCHAR columnText, PUCHAR schema , PUCHAR table , PUCHAR column )
{

   #pragma mapinc("QADBILFI", "QSYS/QADBILFI(*all)" , "both key nullflds", "_P", "RecBuf" , "")
   #include "/QSYS.LIB/QTEMP.LIB/QACYXTRA.FILE/QADBILFI.MBR"
   typedef QDBIFLD_both_t SYSCOLR, * PSYSCOLR;
   typedef QDBIFLD_key_t  SYSCOLK;

   _RIOFB_T * fb;
   SYSCOLR sysColR;
   SYSCOLK sysColK;
   int keylen;
   int i;

   static _RFILE * fSysCol = null;
   if ((fSysCol = _Ropen ("QSYS/QADBILFI" , "rr,nullcap=Y")) == NULL) {
      joblog ( "Not able to open QADBILFI: %s",  strerror(errno)) ;
      return sysColumnName;
   }

   // memset will not work on "volatile" in null maps
   for (i=0; i< fSysCol->null_map_len     ; i ++) { fSysCol->in_null_map[i]= '0';}
   for (i=0; i< fSysCol->null_key_map_len ; i ++) { fSysCol->null_key_map[i]= '0';}

   padncpy  (sysColK.DBILIB , schema , sizeof(sysColK.DBILIB));
   str2vc   (&sysColK.DBILFI , table  );
   keylen = sizeof(sysColK.DBILIB) + sysColK.DBILFI.len;

   // Get format and part info  by table / file name:
   fb = _Rreadk (fSysCol  ,&sysColR , sizeof(SYSCOLR) ,
                 __KEY_EQ | __NULL_KEY_MAP  , &sysColK , keylen);
   if (fb->num_bytes == 0) {
      return NULL;
   }
   // Now have the format and part no
   // now move the format and part into key
   sysColK.DBIFMP = sysColR.DBIFMP;
   memcpy   (sysColK.DBIFMT , sysColR.DBIFMT , sizeof ( sysColK.DBIFMT ));
   str2vc   ((PVAR_CHAR) &sysColK.DBILFL , column );

   // We have the complete key -  get the name for column
   fb = _Rreadk (fSysCol  ,&sysColR , sizeof(SYSCOLR) , __KEY_EQ  , &sysColK , sizeof(SYSCOLK));
   if (fb->num_bytes == 0) {
      return NULL;
   }
   strtrimncpy ( sysColumnName , sysColR.DBIINT , sizeof(sysColR.DBIINT));
   substr ( columnText ,  sysColR.DBITXT.data , sysColR.DBITXT.len);

   return sysColumnName;

}
