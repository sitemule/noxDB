/* SYSIFCOPT(*IFSIO) TERASPACE(*YES *TSIFC) STGMDL(*SNGLVL) */
/* ------------------------------------------------------------- *
 * Company . . . : System & Method A/S                           *
 * Design  . . . : Niels Liisberg                                *
 * Function  . . : NOX - JSON serializer                         *
 *                                                               *
 * By     Date     Task    Description                           *
 * NL     02.06.03 0000000 New program                           *
 * ------------------------------------------------------------- */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h>
#include <iconv.h>


#include <sys/stat.h>
#include "ostypes.h"
#include "sndpgmmsg.h"
#include "trycatch.h"
#include "rtvsysval.h"
#include "parms.h"
#include "utl100.h"
#include "mem001.h"
#include "varchar.h"
#include "streamer.h"
#include "jsonxml.h"


extern int   OutputCcsid;

LONG serializer_flush(PSTREAM pStream);

// ----------------------------------------------------------------------------
PSTREAM serializer_new(ULONG size)
{
    PSTREAM pStream = memAlloc(sizeof(STREAM));
    memset( pStream , 0,   sizeof(STREAM));
    pStream->buffer = memAlloc(size);
    pStream->pos = pStream->buffer;
    pStream->size = size;
    pStream->end = pStream->pos + size;
    return pStream;
}
PSTREAM serializer_newExistingMem(PUCHAR buf, ULONG size)
{
    PSTREAM pStream = memAlloc(sizeof(STREAM));
    memset( pStream , 0,   sizeof(STREAM));
    pStream->buffer = buf;
    pStream->pos = pStream->buffer;
    pStream->size = size;
    pStream->end = pStream->pos + size;
    return pStream;
}
// ----------------------------------------------------------------------------
void serializer_delete(PSTREAM pStream)
{
    serializer_flush(pStream);
    memFree (&pStream->buffer);
    free (pStream);
}
// ----------------------------------------------------------------------------
LONG serializer_write(PSTREAM pStream, PUCHAR buf , ULONG len)
{
	PJWRITE pjWrite = pStream->handle;
	PUCHAR input = buf;
	size_t inbytesleft  = len;
	PUCHAR output = pStream->pos;
	size_t outbytesleft = pStream->end - pStream->pos;
	size_t rc = iconv ( pjWrite->iconv , &input , &inbytesleft, &output , &outbytesleft);
    LONG outlen  =  (pStream->end - pStream->pos) - outbytesleft;
    pStream->pos += outlen;
    return outlen;
}
// ----------------------------------------------------------------------------
LONG serializer_writeBin(PSTREAM pStream, PUCHAR buf , ULONG len)
{
    memcpy ( pStream->pos , buf , len);
    pStream->pos += len;
    return len;
}
// ----------------------------------------------------------------------------
LONG serializer_flush(PSTREAM pStream)
{
    int len = pStream->pos - pStream->buffer;
    if  ( len > 0) {
       pStream->writer(pStream, pStream->buffer , len);
       pStream->pos = pStream->buffer;
    }
    return len;
}
// ----------------------------------------------------------------------------
LONG serializer_putc(PSTREAM pStream, UCHAR c)
{
    return serializer_write(pStream , &c , 1);
}
// ----------------------------------------------------------------------------
LONG serializer_printf (PSTREAM pStream , const char * ctlstr, ...)
{
   va_list arg_ptr;
   UCHAR   buf[65535];
   LONG    len;

   // Build a temp string with the formated data
   va_start(arg_ptr, ctlstr);
   len = vsprintf(buf, ctlstr, arg_ptr);
   va_end(arg_ptr);
   return  serializer_write (pStream , buf, len );
}
// ----------------------------------------------------------------------------
LONG serializer_puts  (PSTREAM pStream , PUCHAR s)
{
   LONG len = strlen(s);
   return  serializer_write (pStream , s , len );
}

// TODO write binary - stream writer has no binary option now
// TODO Have to optimize this - keep the iconv open
static void putUtf8forUnicode (PSTREAM pStream, PUCHAR hexStr)
{
   UCHAR binmem[2];
   UCHAR outUtf8 [10];
   iconv_t unicodeToUtf8 = XlateOpenDescriptor (13488 , 1208, 0);

   hex2BinMem (binmem , hexStr , 4);
   LONG len = XlateBuffer (unicodeToUtf8, outUtf8 , binmem , 2 );
   serializer_writeBin(pStream, outUtf8 , len);
   iconv_close (unicodeToUtf8);
}
static void putUnicode (PSTREAM pStream, PUCHAR hexStr)
{
   UCHAR binmem[2];
   hex2BinMem (binmem , hexStr , 4);
   serializer_writeBin (pStream , binmem , 2);
}
/* ---------------------------------------------------------------------------
	--------------------------------------------------------------------------- */
static void   jx_EncodeJsonStream (PSTREAM pStream , PUCHAR in)
{
	PJWRITE pJw = pStream->handle;

	while (*in) {
		UCHAR c =  *in;
		if (c == '\n' ||  c == '\r' || c == '\t' || c == '\"' ) {
			serializer_putc(pStream,pJw->backSlash);
			switch (c) {
				case '\n': c = 'n' ; break ;
				case '\r': c = 'r' ; break ;
				case '\t': c = 't' ; break ;
				case '\"': c = '"' ; break ;
			}
			serializer_putc(pStream,c);
			in++;
		}
		else if  (c  == pJw->backSlash) {
			// Dont double escape unicode escape sequence
			// no need for testing the length - zero termination will catch that
			if (in[1] == 'u'
				&& isxdigit(in[2]) && isxdigit(in[3])
				&& isxdigit(in[4]) && isxdigit(in[5])) {
				// if target is unicode or UTF-8 we can write that converted:
				if (pJw->iconv.cd[1] == 1208) {
					putUtf8forUnicode(pStream,&in[2]);
					in += 6;
				} else if (pJw->iconv.cd[1] == 13488) {
					putUnicode(pStream,&in[2]);
					in += 6;
				} else {
					serializer_putc(pStream,pJw->backSlash);
					in++;
				}
				// otherwise do noting to NOT double escape unicode escape sequence

			} else {
				// Escape the backSlash
				serializer_putc(pStream,pJw->backSlash);
				serializer_putc(pStream,pJw->backSlash);
				in++;
			}
		}
		else if  (c  < ' ') {
			serializer_putc(pStream, ' '); // Blank for printable
			in++;
		} else {
			serializer_putc(pStream,c);
			in++;
		}
	}
}
/* --------------------------------------------------------------------------- */
static void indent (PSTREAM pStream , int indent)
{
	int i;
	PJWRITE pjWrite = pStream->handle;
	if (pjWrite->doTrim) return;

	//if(!pjWrite->wasHere) {
	//   pjWrite->wasHere = true;
	//} else {
		serializer_putc(pStream, '\n');
	//}
	for(i=0;i<indent; i++) {
		serializer_putc(pStream, '\t');
	}
}
/* --------------------------------------------------------------------------- */
void checkParentRelation(PJXNODE pNode , PJXNODE pParent)
{
	 if (pNode->pNodeParent != pParent) {
		try {
			joblog("Invalid parent relation %s , %s for %s",
				pNode->pNodeParent->Name,
				pParent->Name,
				pNode->Name
			);
		}
		catch (NULL) ;
	 }
}
/* --------------------------------------------------------------------------- */
static void  jsonStreamPrintObject  (PJXNODE pParent, PSTREAM pStream, SHORT level)
{
	PJXNODE pNode;
	PJWRITE pJw = pStream->handle;
	SHORT nextLevel = level +1;

	// indent (pStream ,level);
	serializer_putc (pStream, pJw->curBeg);
	for (pNode = pParent->pNodeChildHead ; pNode ; pNode=pNode->pNodeSibling) {
		indent (pStream ,nextLevel);
		serializer_printf (pStream, "%c%s%c:",pJw->quote, pNode->Name, pJw->quote);
		checkParentRelation(pNode , pParent);
		jsonStreamPrintNode (pNode , pStream, nextLevel);
		if (pNode->pNodeSibling) serializer_putc  (pStream, ',' );
	}
	indent (pStream , level);
	serializer_putc (pStream, pJw->curEnd);
}
/* --------------------------------------------------------------------------- */
static void  jsonStreamPrintArray (PJXNODE pParent, PSTREAM pStream, SHORT level)
{
	PJXNODE pNode;
	PJWRITE pJw = pStream->handle;
	SHORT nextLevel = level +1;

	// indent (pStream ,level);
	serializer_putc (pStream, pJw->braBeg);

	indent (pStream ,nextLevel);
	for (pNode = pParent->pNodeChildHead ; pNode ; pNode=pNode->pNodeSibling) {
		// indent (pStream ,nextLevel);
		checkParentRelation(pNode , pParent);
		jsonStreamPrintNode (pNode , pStream, nextLevel);
		if (pNode->pNodeSibling) serializer_putc  (pStream, ',' );
	}
	indent (pStream , level);
	serializer_putc (pStream, pJw->braEnd);
}
/* --------------------------------------------------------------------------- */
static void jsonStreamPrintValue   (PJXNODE pNode, PSTREAM pStream)
{
	PJWRITE pJw = pStream->handle;
	// Has value?
	if (pNode->Value && pNode->Value[0] > '\0') {
		if (pNode->isLiteral) {
			serializer_puts (pStream, pNode->Value);
		} else {
			serializer_putc(pStream , pJw->quote);
			jx_EncodeJsonStream(pStream ,pNode->Value);
			serializer_putc(pStream , pJw->quote);
		}
	// Else it is some kind of null: Strings are "". Literals will return "null"
	} else {
		if (pNode->isLiteral) {
			serializer_puts (pStream, "null");
		} else {
			serializer_printf (pStream, "%c%c", pJw->quote, pJw->quote);
		}
	}
}
/* -- Experimental for issue90 ----------------------------------------------- */
/* Transcode - analyse what node type it might be                              */
/* XML Elements - if no children then a value else an object object            */
/* --------------------------------------------------------------------------- */
static void jsonStreamPrintTranscode (PJXNODE pNode, PSTREAM pStream, SHORT level)
{
	if (pNode->pNodeChildHead) {
		jsonStreamPrintObject  (pNode, pStream, level);
	} else {
		jsonStreamPrintValue   (pNode, pStream);
	}
}
/* --------------------------------------------------------------------------- */
/* Invalid node types a just jeft out                                          */
/* --------------------------------------------------------------------------- */
static void  jsonStreamPrintNode (PJXNODE pNode, PSTREAM pStream, SHORT level)
{
	switch (pNode->type) {
		case OBJECT:
			jsonStreamPrintObject  (pNode, pStream, level);
			break;

		case ARRAY:
			jsonStreamPrintArray   (pNode, pStream, level);
			break;

		case VALUE:
		case POINTER_VALUE:
			jsonStreamPrintValue   (pNode, pStream);
			break;

		case NOXDB_SUBGRAPH:
			jsonStreamPrintNode   ((PJXNODE) pNode->Value, pStream, level);
			break;

		default:
			jsonStreamPrintTranscode (pNode, pStream, level);
	 }
}
/* --------------------------------------------------------------------------- */
void  jx_AsJsonStream (PJXNODE pNode, PSTREAM pStream)
{
	if (pNode == NULL) {
		serializer_puts (pStream, "null");
	} else {

		// Issue #87
		// Backwards support form older streamer implementation that dont set control chars
		PJWRITE pJw = pStream->handle;
		if ( pJw->braBeg == '\0' ) {
			#pragma convert(1252)
			XlateBufferQ(&pJw->braBeg , "[]{}\\\"" , 6, 1252 ,0 );
			#pragma convert(0)
		}

		jsonStreamPrintNode (pNode, pStream, 0);
	}
}
// ----------------------------------------------------------------------------
static LONG jx_memWriter  (PSTREAM p , PUCHAR buf , ULONG len)
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
static LONG jx_fileWriter  (PSTREAM pStream , PUCHAR buf , ULONG len)
{
	PJWRITE pjWrite = pStream->handle;
	LONG rc = fwrite (pStream->buffer  , 1 , len , pjWrite->outFile);
	return rc;
}
/* ---------------------------------------------------------------------------
	 --------------------------------------------------------------------------- */
LONG jx_AsJsonTextMem (PJXNODE pNode, PUCHAR buf , ULONG maxLenP)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	PSTREAM  pStream;
	LONG     len;
	PJWRITE  pjWrite;


	if (pNode == NULL) return 0;
	if (pNode->signature != NODESIG) {
		strcpy (buf, (PUCHAR) pNode);
		return strlen(buf);
	}

	pStream = serializer_newExistingMem  (buf, maxLenP);
	pStream->writer  = jx_memWriter;
	pStream->handle = pjWrite = jx_newWriter();
	pjWrite->buf = buf;
	pjWrite->doTrim = true;
	pjWrite->maxSize =   pParms->OpDescList == NULL
					|| (pParms->OpDescList && pParms->OpDescList->NbrOfParms >= 3) ? maxLenP : MEMMAX;
	pjWrite->iconv  = XlateOpenDescriptor(0 , 0 , false);
	jx_AsJsonStream (pNode , pStream);
	len = pStream->pos - pStream->buffer;
	serializer_putc   (pStream,'\0');
	serializer_delete (pStream);
	iconv_close(pjWrite->iconv);
	jx_deleteWriter(pjWrite);

	return  len;

}
/* ---------------------------------------------------------------------------
	 --------------------------------------------------------------------------- */
void jx_AsJsonText16M ( PLVARCHAR result , PJXNODE pNode)
{
	result->Length = jx_AsJsonTextMem (pNode, result->String , sizeof(LVARCHAR)-4);
}
/* ---------------------------------------------------------------------------
	 --------------------------------------------------------------------------- */
static void  jx_AsJsonStreamRunner   (PSTREAM pStream)
{
	PJXNODE  pNode = pStream->context;
	jx_AsJsonStream (pNode , pStream);
}
/* ---------------------------------------------------------------------------
	 --------------------------------------------------------------------------- */
PSTREAM jx_Stream  (PJXNODE pNode)
{
	 PSTREAM  pStream;
	 LONG     len;
	 PJWRITE  pjWrite;

	 pStream = serializer_new (0);
	 pStream->handle = pjWrite = jx_newWriter();
	 pjWrite->doTrim  = true;
	 pjWrite->maxSize = MEMMAX;
	 pStream->runner  = jx_AsJsonStreamRunner;
	 pStream->context = pNode;
	 return  pStream;
}

/* ---------------------------------------------------------------------------
	 --------------------------------------------------------------------------- */
VARCHAR jx_AsJsonText (PJXNODE pNode)
{
	 VARCHAR  res;
	 res.Length = jx_AsJsonTextMem ( pNode ,  res.String, sizeof(res.String));
	 return res;
}
/* ---------------------------------------------------------------------------
	 --------------------------------------------------------------------------- */

PJWRITE jx_newWriter ()
{
	PJWRITE pjWrite = malloc (sizeof(JWRITE));
	memset(pjWrite , 0 , sizeof(JWRITE) - sizeof(pjWrite->filler));
	#pragma convert(1252)
	XlateBufferQ(&pjWrite->braBeg , "[]{}\\\"" , 6, 1252 ,0 ); ;
	#pragma convert(0)
	return pjWrite;
}
/* ---------------------------------------------------------------------------
	 --------------------------------------------------------------------------- */
void jx_deleteWriter (PJWRITE  pjWrite)
{
	free(pjWrite);
}
/* ---------------------------------------------------------------------------
	 --------------------------------------------------------------------------- */
void jx_WriteJsonStmf (PJXNODE pNode, PUCHAR FileName, int Ccsid, LGL trimOut, PJXNODE options)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	PSTREAM pStream;
	PJWRITE pjWrite;
	UCHAR   mode[32];
	UCHAR  sigUtf8[]  =  {0xef , 0xbb , 0xbf , 0x00};
	UCHAR  sigUtf16[] =  {0xff , 0xfe , 0x00};

	// Hack for quick fix no bom , just set ccsid negative
	BOOL   makeBomCode  = Ccsid > 0;
	Ccsid = Ccsid < 0  ? - Ccsid : Ccsid;



	if (pNode == NULL) return;

	pjWrite = jx_newWriter();

	pStream = serializer_new (12000000);
	pStream->writer = jx_fileWriter;

	sprintf(mode , "wb,o_ccsid=%d", Ccsid);
	unlink  ( strTrim(FileName)); // Just to reset the CCSID which will not change if file exists
	pjWrite->outFile  = fopen ( strTrim(FileName) , mode );
	if (pjWrite->outFile == NULL) {
		jx_deleteWriter(pjWrite);
		return;
	}

	pStream->handle = pjWrite;

	pjWrite->doTrim = (pParms->OpDescList && pParms->OpDescList->NbrOfParms >= 4 && trimOut == OFF) ? FALSE : TRUE;
	pjWrite->iconv  = XlateOpenDescriptor(OutputCcsid , Ccsid , false);

	if (makeBomCode) {
		switch(Ccsid) {
			case 1208 :
				fputs (sigUtf8, pjWrite->outFile );
				break;
			case 1200 :
				fputs (sigUtf16, pjWrite->outFile );
				break;
		}
	}

	// Any ascii will use basic ascii chars for building the document
	if (Ccsid = 1208 || Ccsid== 1252) {
		#pragma convert(1252)
		XlateBufferQ(&pjWrite->braBeg , "[]{}\\\"" , 6, 1252 ,0 ); ;
		#pragma convert(0)
	}

	jx_AsJsonStream (pNode , pStream);

	serializer_delete (pStream);
	fclose(pjWrite->outFile);
	iconv_close(pjWrite->iconv);
	jx_deleteWriter(pjWrite);
}
