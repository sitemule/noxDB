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
	JWRITE   jWrite;
	PJWRITE  pjWrite = &jWrite;
	memset(pjWrite , 0 , sizeof(jWrite));

	pStream = stream_new (4096);
	pStream->handle  = pjWrite;
	pjWrite->doTrim  = true;
	pjWrite->maxSize = MEMMAX;

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
	PJWRITE pjWrite = p->handle;
	ULONG newLen =  pjWrite->bufLen + len;
	if ( newLen  > pjWrite->maxSize) {
		ULONG restlen = pjWrite->maxSize - pjWrite->bufLen;
		memcpy ( pjWrite->buf +  pjWrite->bufLen , buf , restlen  );
		pjWrite->bufLen = pjWrite->maxSize;
		return pjWrite->bufLen;
	}
	memcpy ( pjWrite->buf +  pjWrite->bufLen , buf , len);
	pjWrite->bufLen += len;
	return pjWrite->bufLen;
}
// ----------------------------------------------------------------------------
LONG nox_fileWriter  (PSTREAM p , PUCHAR buf , ULONG len)
{
	PJWRITE pjWrite = p->handle;
	LONG rc = fwrite (buf, 1, len , pjWrite->outFile);
	return rc;
}


