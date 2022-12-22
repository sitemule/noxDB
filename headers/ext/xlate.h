#ifndef XLATE_H
#define XLATE_H
#include <iconv.h>
#include <QTQICONV.h>

LONG       XlateBuffer (iconv_t cd, PUCHAR out , PUCHAR in , LONG inLen );
LONG       XlateBufferQ (PUCHAR OutBuf, PUCHAR InBuf , ULONG Len, int FromCCSID, int ToCCSID);
VARCHAR    XlateString (iconv_t iconvCd, PVARCHAR In );
PUCHAR     XlateStringQ (PUCHAR out, PUCHAR in, int FromCCSID, int ToCCSID);
VARCHAR    XlateVarCharQ (PVARCHAR In ,  int FromCCSID, int ToCCSID);
VARCHAR    XlateVarChar (iconv_t iconvCd, PVARCHAR In );
iconv_t    XlateOpenDescriptor (int FromCcsid, int ToCcsid, int reportError);
LONG       XlateUtf8ToSbcs (PUCHAR outBuf , PUCHAR inBuf , LONG inBufLen , int toCcsid);
BOOL       XlateGetStaticConversionTables  (PUCHAR e2a , PUCHAR a2e , int AsciiCcsid , int EbcdicCcsid);




#endif
