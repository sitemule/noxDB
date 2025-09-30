// CMD:CRTCMOD
/* ------------------------------------------------------------- */
/* SYSIFCOPT(*IFSIO) OPTION(*EXPMAC *SHOWINC) */
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include "ostypes.h"
#include "varchar.h"
#include "sndpgmmsg.h"
#include "apierr.h"
#include "e2aa2e.h"
#include "Xlate.h"

void sndpgmmsg(PUCHAR Msgid,PUCHAR Msgf, PUCHAR Type ,PUCHAR Msgdta, ... )
{
   ULONG apierr = 0;
   va_list arg_ptr;
   char temp[4096];
   char msgkey [10];
   long stackcount=1;
   int  len;

   va_start(arg_ptr,  Msgdta);
   len = vsprintf(temp, Msgdta , arg_ptr);
   va_end(arg_ptr);

   QMHSNDPM (Msgid, Msgf, temp , len , Type , "sndpgmmsg           " ,
             stackcount, msgkey , &apierr);

}
void joblog (PUCHAR text , ... )
{
   ULONG apierr = 0;
   va_list arg_ptr;
   char temp[4096];
   char msgkey [10];
   long stackcount=1;
   int  len;

   va_start(arg_ptr,  text);
   len = vsprintf(temp, text, arg_ptr);
   va_end(arg_ptr);

   QMHSNDPM (
      "CPF9898",
      QCPFMSG ,
      temp ,
      len ,
      INFO ,
      "joblog       " ,
      stackcount,
      msgkey ,
      &apierr
   );
}
// To avoid conversion error, we temporary use static ascii to 277, then to job
void nox_JoblogVC(PLVARCHAR text)
{
   UCHAR temp [1024];
   stra2e (temp  , plvc2str(text));
   Xlatestr (temp, temp, 277, 0);
   joblog  ( "%s" , temp);
}


