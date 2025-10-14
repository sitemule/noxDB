// CMD:CRTCMOD
/* ------------------------------------------------------------- */
/* Program . . . : XLATE                                         */
/* Date  . . . . : 24.04.2008                                    */
/* Design  . . . : Niels Liisberg                                */
/* Function  . . : X-alation using iconv                         */
/*                                                               */
/* By     Date       PTF     Description                         */
/* NL     24.04.2008         New program                         */
/* ------------------------------------------------------------- */
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include <iconv.h>
#include <limits.h>
#include <QTQICONV.h>

#include "ostypes.h"
#include "varchar.h"
#include "xlate.h"


/* ------------------------------------------------------------- */
iconv_t XlateOpen (LONG FromCCSID, LONG ToCCSID , BOOL reportError)
{
   QtqCode_T To;
   QtqCode_T From;

   memset(&From , 0, sizeof(From));
   From.CCSID = FromCCSID;
   From.cnv_alternative = 0 ;
   From.subs_alternative = 0 ;
   From.shift_alternative = 0;
   From.length_option = 0;
   From.mx_error_option = 0;

   memset(&To , 0, sizeof(To));
   To.CCSID = ToCCSID;
   To.cnv_alternative = 0;
   To.subs_alternative = 0;
   To.shift_alternative = 0;
   To.length_option = 0;
   To.mx_error_option = reportError;

   // Get descriptor
   return QtqIconvOpen( &To, &From);
}
/* ------------------------------------------------------------- */
LONG XlateBuffer (iconv_t cd, PUCHAR out , PUCHAR in , LONG inLen )
{
   size_t inbytesleft = inLen;
   size_t outbytesleft =  LONG_MAX;
   PUCHAR pIn = in;
   PUCHAR pOut = out;
   size_t rc = iconv (cd, &pIn, &inbytesleft, &pOut, &outbytesleft);

   return (rc < 0) ? -1: LONG_MAX - outbytesleft;

}
/* ------------------------------------------------------------- */
PUCHAR XlateString (iconv_t cd, PUCHAR out , PUCHAR in )
{
   size_t inbytesleft = strlen(in);
   size_t outbytesleft =  LONG_MAX;
   PUCHAR pIn = in;
   PUCHAR pOut = out;
   size_t rc = iconv (cd, &pIn, &inbytesleft, &pOut, &outbytesleft);
   out [LONG_MAX - outbytesleft] = '\0';
   return out;
}
/* ------------------------------------------------------------- */
PUCHAR XlateBuffer2str (iconv_t cd, PUCHAR out , PUCHAR in , LONG inLen )
{
   size_t inbytesleft = inLen;
   size_t outbytesleft =  LONG_MAX;
   PUCHAR pIn = in;
   PUCHAR pOut = out;
   size_t rc = iconv (cd, &pIn, &inbytesleft, &pOut, &outbytesleft);
   out [LONG_MAX - outbytesleft] = '\0';
   return out;
}

/* ------------------------------------------------------------- */
ULONG XlateBuf(PUCHAR OutBuf, PUCHAR InBuf , ULONG Len, LONG FromCCSID, LONG ToCCSID)
{
   iconv_t iconv;
   ULONG OutLen;

   if (Len ==0 ) return 0;

   if (FromCCSID == ToCCSID) {
      memcpy(OutBuf, InBuf , Len);
      return Len;
   }

   iconv = XlateOpen (FromCCSID, ToCCSID, false);
   if (iconv.return_value == -1) return -1;

   OutLen = XlateBuffer(iconv, OutBuf, InBuf , Len);
   iconv_close (iconv);

   return (OutLen);  // Number of bytes converted
}
/* ------------------------------------------------------------- */
VARCHAR XlateStr (PVARCHAR In ,  LONG FromCCSID, LONG ToCCSID)
{
   VARCHAR Result;

   Result.Length = XlateBuf(Result.String , In->String , In->Length , FromCCSID, ToCCSID);
   return (Result);
}
/* ------------------------------------------------------------- */
PUCHAR Xlatestr (PUCHAR out, PUCHAR in, LONG FromCCSID, LONG ToCCSID)
{
   LONG len = XlateBuf(out, in , strlen(in)  , FromCCSID, ToCCSID);
   out[len] = 0;
   return out;
}
