#ifndef XLATE_H
#define XLATE_H
#include <iconv.h>
#include <QTQICONV.h>

VARCHAR    XlateStr (PVARCHAR In ,  LONG FromCCSID, LONG ToCCSID);
PUCHAR     Xlatestr (PUCHAR out, PUCHAR in , LONG FromCCSID, LONG ToCCSID);

// Using iconv_t
iconv_t    XlateOpen (LONG FromCCSID, LONG ToCCSID, BOOL reportError);
LONG       XlateBuffer (iconv_t cd, PUCHAR out , PUCHAR in , LONG inLen ) ;
PUCHAR     XlateString (iconv_t cd, PUCHAR out , PUCHAR in );
PUCHAR     XlateBuffer2str (iconv_t cd, PUCHAR out , PUCHAR in , LONG inLen );
VOID       XlateClode(iconv_t cd);




#endif
