/* SYSIFCOPT(*IFSIO) TERASPACE(*YES *TSIFC) STGMDL(*INHERIT) */
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
#include <QTQICONV.h>

#include "ostypes.h"
#include "xlate.h"

/* ------------------------------------------------------------- */
PXLATEDESC XlateXdOpenStrict ( int FromCCSID, int ToCCSID, int reportError)
{
   PXLATEDESC pXd = malloc(sizeof(XLATEDESC));
   QtqCode_T To;
   QtqCode_T From;

   pXd->FromCCSID = FromCCSID ;
   pXd->ToCCSID   = ToCCSID;

   memset(&From , 0, sizeof(From));
   From.CCSID = FromCCSID;
   From.cnv_alternative = reportError == 0? 0 : 57;
   From.subs_alternative = 0 ;
   From.shift_alternative = 0;
   From.length_option = 0;
   From.mx_error_option = reportError;

   memset(&To , 0, sizeof(To));
   To.CCSID = ToCCSID;
   To.cnv_alternative = reportError == 0? 0 : 57;
   To.subs_alternative = 0;
   To.shift_alternative = 0;
   To.length_option = 0;
   To.mx_error_option = reportError;

   // Get descriptor
   pXd->Iconv = QtqIconvOpen( &To, &From);
   pXd->Open = (pXd->Iconv.return_value != -1);
   if (! pXd->Open) {
      free (pXd);
      return (NULL); // invalid CCSID
   }
   return (pXd);  // Number of bytes converted
}
/* ------------------------------------------------------------- */
PXLATEDESC XlateXdOpen (int FromCCSID, int ToCCSID)
{
   return XlateXdOpenStrict ( FromCCSID, ToCCSID, 0);
}
/* ------------------------------------------------------------- */
void XlateXdClose  (PXLATEDESC pXd)
{
   if ( pXd == NULL) return;
   iconv_close (pXd->Iconv);
   free (pXd);
}
/* ------------------------------------------------------------- */
ULONG XlateXdBuf(PXLATEDESC pXd, PUCHAR OutBuf, PUCHAR InBuf , ULONG Len)
{
   PUCHAR pOutBuf;
   PUCHAR pInBuf;
   int i;
   size_t OutLen, inbytesleft, outbytesleft;
   size_t before, rc;

   if (Len ==0 ) return 0;

   if (pXd == NULL
   ||  pXd->FromCCSID == pXd->ToCCSID) {
      memcpy(OutBuf, InBuf , Len);
      return Len;
   }

   before = outbytesleft = Len * 4; // Max size of UTF8 expand to 4 times bytes
   inbytesleft  = Len;

   pOutBuf = OutBuf;
   pInBuf  = InBuf;

   // Do Conversion
   rc = iconv (pXd->Iconv, &pInBuf, &inbytesleft, &pOutBuf, &outbytesleft);
   if (rc == -1) return (-1);

   OutLen  = before - outbytesleft;
   return (OutLen);  // Number of bytes converted
}
/* ------------------------------------------------------------- */
VARCHAR XlateXdStr (PXLATEDESC pXd, PVARCHAR In )
{
   VARCHAR Result;
   Result.Length = XlateXdBuf(pXd ,Result.String , In->String , In->Length );
   return (Result);
}
/* ------------------------------------------------------------- */
ULONG XlateBuf(PUCHAR OutBuf, PUCHAR InBuf , ULONG Len, int FromCCSID, int ToCCSID)
{
   PXLATEDESC pXd;
   ULONG OutLen;

   if (Len ==0 ) return 0;

   if (FromCCSID == ToCCSID) {
      memcpy(OutBuf, InBuf , Len);
      return Len;
   }

   pXd = XlateXdOpen (FromCCSID, ToCCSID);
   if  (!pXd) return -1;

   OutLen = XlateXdBuf(pXd, OutBuf, InBuf , Len);
   XlateXdClose  (pXd);

   return (OutLen);  // Number of bytes converted
}
/* ------------------------------------------------------------- */
VARCHAR XlateStr (PVARCHAR In ,  int FromCCSID, int ToCCSID)
{
   VARCHAR Result;

   Result.Length = XlateBuf(Result.String , In->String , In->Length , FromCCSID, ToCCSID);
   return (Result);
}
/* ------------------------------------------------------------- */
PUCHAR Xlatestr (PUCHAR out, PUCHAR in, int FromCCSID, int ToCCSID)
{
   int len = XlateBuf(out, in , strlen(in)  , FromCCSID, ToCCSID);
   out[len] = 0;
   return out;
}
/* ------------------------------------------------------------- */
PUCHAR XlateFromAnyAscii2ebcdic (PUCHAR outStr, PUCHAR inStr)
{
  PXLATEDESC pXd;
  int inLen = strlen (inStr);
  int xLen;
  int isCCSID;
  PUCHAR temp;

  // First guess the input ccssid by converting it to unicode...
  pXd =  XlateXdOpen(1208 , 1200 );
  temp   = malloc(inLen  *2);  // Unicode requires double size
  xLen = XlateXdBuf(pXd , temp   , inStr , inLen  );
  XlateXdClose(pXd);
  free(temp);
  isCCSID = (xLen == -1) ? 1252 : 1208;

  // next convet to current job ccsid
  pXd =  XlateXdOpen(isCCSID, 0 );
  xLen = XlateXdBuf(pXd , outStr , inStr , inLen  );
  XlateXdClose(pXd);
  outStr[xLen] = '\0';
  return outStr;
}
/* ------------------------------------------------------------- */
LONG  XlateXdSprintf (PXLATEDESC pxd, PUCHAR out, PUCHAR Ctlstr,...)
{
   va_list arg_ptr;
   UCHAR   temp1[65535];
   LONG    len1, len2;
   SHORT   l,i;

   // Build a temp string with the formated data
   va_start(arg_ptr, Ctlstr);
   len1 = vsprintf(temp1, Ctlstr, arg_ptr);
   va_end(arg_ptr);

   len2 = XlateXdBuf(pxd , out , temp1  , len1);
   return len2;
}
/* ------------------------------------------------------------- */
iconv_t OpenXlateDescriptor (int FromCcsid, int ToCcsid, int reportError)
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
   toccsid.mx_error_option = reportError;

   memset(&fromccsid , 0, sizeof(fromccsid));
   fromccsid.CCSID = FromCcsid;
   fromccsid.cnv_alternative = 0;
   fromccsid.subs_alternative = 0;
   fromccsid.shift_alternative = 0;
   fromccsid.length_option = 0;
   fromccsid.mx_error_option = reportError;

   tocode = &toccsid;
   fromcode = &fromccsid;
   cd = QtqIconvOpen( tocode, fromcode);
   return cd;
}
/* ------------------------------------------------------------- */
iconv_t OpenXlate (int FromCcsid, int ToCcsid)
{
   return OpenXlateDescriptor (FromCcsid, ToCcsid, 0);
}
/* ------------------------------------------------------------- *\
   Single byte charset (SBCS) can not carrie all unicode. And in
   that case we escape with the \uXXXX unicode notation used in JSON.

   If invalid char sequence is encounted in the UTF-8 data stream
   it will default to latin-1 (windows 1252)

   note: output is assumed to be som kind of EBCDIC for the unicode escape. 

   note the bitshifting below. It is based on (omiting the bit test after the first byte)

   first code point  Last code point  Byte 1   Byte 2   Byte 3   Byte 4
   ----------------  ---------------  -------- -------- -------- --------
   U+0000            U+007F           0xxxxxxx
   U+0080            U+07FF           110xxxxx 10xxxxxx
   U+0800            U+FFFF           1110xxxx 10xxxxxx 10xxxxxx
   U+10000           U+10FFFF         11110xxx 10xxxxxx 10xxxxxx 10xxxxxx

\* ------------------------------------------------------------- */
LONG XlateUtf8ToSbcs (PUCHAR outBuf , PUCHAR inBuf , LONG inBufLen , int toCcsid)
{
   LONG   inBufPos;
   PUCHAR pOutBuf = outBuf;
   LONG   outBufLen =0;
   size_t outLen, inBytesLeft, outBytesLeft, before;
   int    rc;
   LONG   i;
   UCHAR  tempOut [4];
   PUCHAR pTempOut;
   UCHAR  sbcsArr [256];
   UCHAR  hex [] = "0123456789ABCDEF";
   BOOL   found;

   typedef struct {
      SHORT  len;
      UCHAR  charSequence[4];
      UCHAR  sbscChar;
   } CHARSEQ , * PCHARSEQ;

   CHARSEQ charSeq [256];
   PCHARSEQ pCharSeq;
   int charSeqIx = 0;

   iconv_t utf8toSbcs    = OpenXlateDescriptor (toCcsid , 1208, 0);
   iconv_t utf8toUnicode = OpenXlateDescriptor (1208, 13488, 0);
   iconv_t defaultSbcs   = OpenXlateDescriptor (1252, toCcsid, 0);

   // first find which chars is supported in this SBCS CCSID
   // Find the UTF-8 represenation of each char:
   memset (sbcsArr , 0 , sizeof(sbcsArr));
   for (i=0; i < 256; i++) {
      UCHAR  c = i;
      PUCHAR pC = &c; // Will be modified by iconv
      inBytesLeft = 1;

      pTempOut = tempOut;
      outBytesLeft = sizeof(tempOut);

      rc = iconv (utf8toSbcs, &pC, &inBytesLeft, &pTempOut, &outBytesLeft);
      // When just one but is converted we can use simple table conversion and the character is supported
      if ( outBytesLeft == sizeof(tempOut) - 1) {
         sbcsArr [tempOut[0]] = c;
      } else {
         pCharSeq = &charSeq[charSeqIx++];
         pCharSeq->sbscChar  = c;
         pCharSeq->len =  sizeof(tempOut) - outBytesLeft;
         memcpy (pCharSeq->charSequence , tempOut , sizeof(tempOut) - outBytesLeft);
      }
   }

   // Now do the conversion
   for (inBufPos=0; inBufPos<inBufLen; inBufPos++) {
      int j;
      PUCHAR pInBuf = &inBuf [inBufPos];
      PUCHAR pC;
      UCHAR  c = *pInBuf;

      // NULL's will also be in the array, so we need to test hard for that:
      if (c =='\0') {
         *(pOutBuf++) = '\0';
         continue;
      }

      if (sbcsArr[c] != '\0') {
         *(pOutBuf++) = sbcsArr[c];
         continue;
      }

      // Is the multibyte sequence supported by the destinatin charset as SBCS ?
      found = false;
      for (j=0; j < charSeqIx ; j++) {
         pCharSeq = &charSeq[j];
         if (memcmp (pInBuf , pCharSeq->charSequence, pCharSeq->len) == 0) {
            found = true;
            break; // found !!
         }
      }

      // When found - store it and bump to next - that might be more than one byte
      if (found) {
         *(pOutBuf++) = pCharSeq->sbscChar;
         inBufPos += pCharSeq->len - 1;
         continue;
      }

      // otherwise do the encoding: Find number of in bytes: 1,2,3 or 4:
      if ((c & 0x80)== 0x00) { // One byte
         inBytesLeft = 1;
      } else if ((c & 0xe0) == 0xc0) { // Two bytes
         inBytesLeft = 2;
      } else if ((c & 0xe0) == 0xe0) { // Three bytes
         inBytesLeft = 3;
      } else if ((c & 0xf8) == 0xf8) { // Four bytes
         inBytesLeft = 4;
      } else { // Invalid char - default to win-1252
         inBytesLeft = 1;
         pC = pInBuf; // Will be modified by iconv
         outBytesLeft = 1;
         rc = iconv (defaultSbcs, &pInBuf, &inBytesLeft, &pOutBuf, &outBytesLeft);
         continue;
      }
      inBufPos += inBytesLeft - 1; // Need to set it now before it is changed by iconv;
      pC = pInBuf; // Will be modified by iconv
      pTempOut = tempOut;
      outBytesLeft = sizeof(tempOut);
      rc = iconv (utf8toUnicode, &pC, &inBytesLeft, &pTempOut, &outBytesLeft);
      if (rc != 0) {
         inBufPos -= inBytesLeft - 1; // Reset the faulty length assumed
         inBytesLeft = 1;
         pC = pInBuf; // Will be modified by iconv
         outBytesLeft = 1;
         rc = iconv (defaultSbcs, &pC, &inBytesLeft, &pOutBuf, &outBytesLeft);
         continue;
      }
      *(pOutBuf++) = '\\';
      *(pOutBuf++) = 'u';
      for (j=0; j< sizeof(tempOut) - outBytesLeft; j++) {
         *(pOutBuf++) = hex[(tempOut[j] & 0xf0) >> 4];
         *(pOutBuf++) = hex[(tempOut[j] & 0x0f)];
      }
   }
   // Clean up;
   iconv_close (utf8toSbcs);
   iconv_close (utf8toUnicode);
   iconv_close (defaultSbcs);

   // terminate so it can be used as a C-string
   *(pOutBuf) = '\0';
   return pOutBuf - outBuf;

}
