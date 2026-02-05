// CMD:CRTCMOD
/* ------------------------------------------------------------- *
 * Company . . . : System & Method A/S                           *
 * Design  . . . : Niels Liisberg                                *
 * Function  . . : Provide the streamer to the stream interface  *
 *                                                               *
 * By     Date     Task    Description                           *
 * NL     19.07.22 0000000 Refactor old funtionality             *
 * ------------------------------------------------------------- */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h>
#include <leod.h>
#include <decimal.h>
#include <wchar.h>
// #include <errno.h>

#include <sys/stat.h>
#include "ostypes.h"
#include "varchar.h"
#include "xlate.h"
#define NOX_BUILD
#include "noxDbUtf8.h"
#include "parms.h"
// #include "rtvsysval.h"
#include "memUtil.h"
#include "strUtil.h"


// ----------------------------------------------------------------------------
PSTREAM nox_Stream  (PNOXNODE pNode , ULONG format)
{
   PSTREAM  pStream;
   LONG     len;
   NOXWRITER   noxWriter;
   PNOXWRITER  pNoxWriter = &noxWriter;
   memset(pNoxWriter , 0 , sizeof(noxWriter));

   pStream = stream_new (4096);
   pStream->handle  = pNoxWriter;
   pNoxWriter->doTrim  = true;
   pNoxWriter->maxSize = MEMMAX;

    switch  (format) {
        case NOX_STREAM_JSON :
            pStream->runner  = jsonStreamRunner;
            break;
        case NOX_STREAM_XML  :
            pStream->runner  = xmlStreamRunner;
            break;
       case NOX_STREAM_CSV  :
            pStream->runner  = csvStreamRunner;
            break;
    }


   pStream->context = pNode;
   return  pStream;
}

// ----------------------------------------------------------------------------
LONG nox_memWriter  (PSTREAM p , PUCHAR buf , ULONG len)
{
   PNOXWRITER pNoxWriter = p->handle;
   ULONG newLen =  pNoxWriter->bufLen + len;
   if ( newLen  > pNoxWriter->maxSize) {
      ULONG restlen = pNoxWriter->maxSize - pNoxWriter->bufLen;
      memcpy ( pNoxWriter->buf +  pNoxWriter->bufLen , buf , restlen  );
      pNoxWriter->bufLen = pNoxWriter->maxSize;
      return pNoxWriter->bufLen;
   }
   memcpy ( pNoxWriter->buf +  pNoxWriter->bufLen , buf , len);
   pNoxWriter->bufLen += len;
   return pNoxWriter->bufLen;
}
// ----------------------------------------------------------------------------
LONG nox_fileWriter  (PSTREAM p , PUCHAR buf , ULONG len)
{
   PNOXWRITER pNoxWriter = p->handle;
   LONG rc = fwrite (buf, 1, len , pNoxWriter->outFile);
   return rc;
}


