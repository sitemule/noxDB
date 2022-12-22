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
#include <limits.h>

#include "ostypes.h"
#include "xlate.h"

/* ------------------------------------------------------------- */
iconv_t XlateOpenDescriptor (int FromCcsid, int ToCcsid, int reportError)
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
VARCHAR XlateVarChar (iconv_t iconvCd, PVARCHAR In )
{
   VARCHAR Result;
   Result.Length = XlateBuffer(iconvCd ,Result.String , In->String , In->Length );
   return (Result);
}
/* ------------------------------------------------------------- */
LONG XlateBufferQ(PUCHAR OutBuf, PUCHAR InBuf , ULONG Len, int FromCCSID, int ToCCSID)
{
   iconv_t iconvCd;
   ULONG OutLen;

   if (Len ==0 ) return 0;

   if (FromCCSID == ToCCSID) {
      memcpy(OutBuf, InBuf , Len);
      return Len;
   }

   iconvCd = XlateOpenDescriptor (FromCCSID, ToCCSID , false) ;
   if (iconvCd.return_value == -1) return -1;


   OutLen = XlateBuffer (iconvCd, OutBuf, InBuf , Len);
   iconv_close (iconvCd);

   return (OutLen);  // Number of bytes converted
}
/* ------------------------------------------------------------- */
VARCHAR XlateVarCharQ (PVARCHAR In ,  int FromCCSID, int ToCCSID)
{
   VARCHAR Result;

   Result.Length = XlateBufferQ(Result.String , In->String , In->Length , FromCCSID, ToCCSID);
   return (Result);
}
/* ------------------------------------------------------------- */
PUCHAR XlateStringQ (PUCHAR out, PUCHAR in, int FromCCSID, int ToCCSID)
{
   int len = XlateBufferQ(out, in , strlen(in)  , FromCCSID, ToCCSID);
   out[len] = 0;
   return out;
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

   iconv_t utf8toSbcs    = XlateOpenDescriptor (toCcsid , 1208, 0);
   iconv_t utf8toUnicode = XlateOpenDescriptor (1208, 13488, 0);
   iconv_t defaultSbcs   = XlateOpenDescriptor (1252, toCcsid, 0);

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
/* ------------------------------------------------------------- */
BOOL XlateGetStaticConversionTables  (PUCHAR e2a , PUCHAR a2e , int AsciiCcsid , int EbcdicCcsid)
{

   UCHAR  tbl[256];
   iconv_t cd;
   int i;
   LONG len;
   BOOL error = false;

   for (i=0;i<256;i++) {
      tbl[i] = i;
   }

   cd = XlateOpenDescriptor ( AsciiCcsid, EbcdicCcsid, FALSE);
   if (cd.return_value == -1) {
      EbcdicCcsid = 277; // Fallback if jobccsid = 65535 and for backwards compatibility, noxDb was originally build in ccsid 277 
      cd = XlateOpenDescriptor ( AsciiCcsid, EbcdicCcsid, FALSE);
   }
   if (cd.return_value == -1) {
      error = true;
   }

   len = XlateBuffer (cd, a2e , tbl, 256);
   iconv_close (cd);

   if (len == -1) {
      return true;
   } 

   cd = XlateOpenDescriptor ( EbcdicCcsid , AsciiCcsid, FALSE);
   if (cd.return_value == -1) {
      EbcdicCcsid = 277; // Fallback if jobccsid = 65535 and for backwards compatibility, noxDb was originally build in ccsid 277 
      cd = XlateOpenDescriptor ( EbcdicCcsid , AsciiCcsid, FALSE);
   }
   if (cd.return_value == -1) {
      error = true;
   }
   len = XlateBuffer (cd, e2a , tbl, 256);

   if (len == -1) {
      return true;
   } 

   iconv_close (cd);

   return (error);
}

