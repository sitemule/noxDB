#include <iconv.h>
PUCHAR RtvSysVal(PUCHAR sysvalvalue, PUCHAR sysvalname);
int RtvDftCCSID (void);
BOOL ChkUniqueTbl(PUCHAR tbl);
BOOL RtvXlateTbl  (PUCHAR e2a , PUCHAR a2e , int AsciiCcsid, int EbcdicCcsid);
iconv_t OpenXlate (int AsciiCcsid, int EbcdicCcsid);