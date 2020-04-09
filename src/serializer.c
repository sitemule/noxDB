// CMD:CRTCMOD 
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
#include <sys/stat.h>

#include "ostypes.h"
#include "varchar.h"
#include "sndpgmmsg.h"
#include "trycatch.h"
// #include "rtvsysval.h"
#include "parms.h"
#include "memUtil.h"
#include "streamer.h"
#include "noxdb2.h"


// -----------------------------------------------------------------
#pragma convert(1252)
static void   nox_EncodeJsonStream (PSTREAM p , PUCHAR in)
{

	while (*in) {
		UCHAR c =  *in;
		if (c == '\n' ||  c == '\r' || c == '\t' || c == '\"' ) {
			stream_putc(p,BACKSLASH);
			switch (c) {
				case '\n': c = 'n' ; break ;
				case '\r': c = 'r' ; break ;
				case '\t': c = 't' ; break ;
				case '\"': c = '"' ; break ;
			}
		}
		else if  (c  == BACKSLASH) {
			if (in[1] != 'u') {  // Dont double escape unicode escape sequence
				stream_putc(p,BACKSLASH);
			}
		}
		else if  (c  < ' ') {
			c = ' ';
		}
		stream_putc(p,c);
		in++;
	}
}
#pragma convert(0)
// -----------------------------------------------------------------
#pragma convert(1252)
static PUCHAR nox_EncodeJson (PUCHAR out , PUCHAR in)
{
	PUCHAR ret = out;
	while (*in) {
		UCHAR c =  *in;
		if (c == '\n' ||  c == '\r' || c == '\t' || c == '\"' ) {
			*(out++) = BACKSLASH;
		}
		else if  (c  == BACKSLASH) {
			if (in[1] != 'u') {  // Dont double escape unicode escape sequence
				*(out++) = BACKSLASH;
			}
		}
		else if  (c  < ' ') {
			c = ' ';
		}
		*(out++) = c;
		in++;
	}
	*(out++) = '\0';
	return ret;
}
#pragma convert(0)
// -----------------------------------------------------------------
#pragma convert(1252)
static void indent (PSTREAM pStream , int indent)
{
	int i;
	PJWRITE pjWrite = pStream->handle;
	if (pjWrite->doTrim) return;

	//if(!pjWrite->wasHere) {
	//   pjWrite->wasHere = true;
	//} else {
		stream_putc(pStream, '\n');
	//}
	for(i=0;i<indent; i++) {
		stream_putc(pStream, '\t');
	}
}
#pragma convert(0)
// -----------------------------------------------------------------
void checkParentRelation(PNOXNODE pNode , PNOXNODE pParent)
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
static void  jsonStreamPrintObject  (PNOXNODE pParent, PSTREAM pStream, SHORT level)
{
	PNOXNODE pNode;
	SHORT nextLevel = level +1;

	// indent (pStream ,level);
	stream_putc (pStream, CURBEG);
	for (pNode = pParent->pNodeChildHead ; pNode ; pNode=pNode->pNodeSibling) {
		indent (pStream ,nextLevel);
		stream_putc(pStream, QUOT);
		stream_puts(pStream, pNode->Name);
		stream_putc(pStream, QUOT);
		stream_putc(pStream, COLON);
		checkParentRelation(pNode , pParent);
		jsonStreamPrintNode (pNode , pStream, nextLevel);
		if (pNode->pNodeSibling) stream_putc  (pStream, COMMA );
	}
	indent (pStream , level);
	stream_putc (pStream, CUREND);
}
/* --------------------------------------------------------------------------- */
static void  jsonStreamPrintArray (PNOXNODE pParent, PSTREAM pStream, SHORT level)
{
	 PNOXNODE pNode;
	 SHORT nextLevel = level +1;

	 // indent (pStream ,level);
	 stream_putc (pStream, BRABEG);
	 indent (pStream ,nextLevel);
	 for (pNode = pParent->pNodeChildHead ; pNode ; pNode=pNode->pNodeSibling) {
		// indent (pStream ,nextLevel);
		checkParentRelation(pNode , pParent);
		jsonStreamPrintNode (pNode , pStream, nextLevel);
		if (pNode->pNodeSibling) stream_putc  (pStream, COMMA );
	 }
	 indent (pStream , level);
	 stream_putc (pStream, BRAEND);
}
/* --------------------------------------------------------------------------- */
#pragma convert(1252)
static void jsonStreamPrintValue   (PNOXNODE pNode, PSTREAM pStream)
{
	// Has value?
	if (pNode->Value && pNode->Value[0] > '\0') {
		if (pNode->isLiteral) {
			stream_puts (pStream, pNode->Value);
		} else {
			stream_putc(pStream , QUOT);
			nox_EncodeJsonStream(pStream ,pNode->Value);
			stream_putc(pStream , QUOT);
		}
	// Else it is some kind of null: Strings are "". Literals will return "null"
	} else {
		if (pNode->isLiteral) {
			stream_puts (pStream, NULLSTR);
		} else {
			stream_putc(pStream , QUOT);
			stream_putc(pStream , QUOT);
		}
	}
}
#pragma convert(0)
/* --------------------------------------------------------------------------- */
/* Invalid node types a just jeft out                                          */
/* --------------------------------------------------------------------------- */
static void  jsonStreamPrintNode (PNOXNODE pNode, PSTREAM pStream, SHORT level)
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
	 }
}
/* --------------------------------------------------------------------------- */
#pragma convert(1252)
void  nox_AsJsonStream (PNOXNODE pNode, PSTREAM pStream)
{
	if (pNode == NULL) {
		stream_puts (pStream, NULLSTR);
	} else {
		jsonStreamPrintNode (pNode, pStream, 0);
	}
}
#pragma convert(0)
// ----------------------------------------------------------------------------
static LONG nox_memWriter  (PSTREAM p , PUCHAR buf , ULONG len)
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
/*
static LONG nox_fileWriter  (PSTREAM p , PUCHAR buf , ULONG len)
{
	PJWRITE pjWrite = p->handle;
	int outlen = 4 * len;
	size_t inbytesleft, outbytesleft, rc;
	PUCHAR temp , input , output ;

	input = buf;
	inbytesleft  = len;

	output = temp = malloc   (outlen);
	outbytesleft = outlen;

	rc = iconv ( pjWrite->iconv , &input , &inbytesleft, &output , &outbytesleft);
	outlen = output - temp;
	fwrite (temp  , 1 , outlen , pjWrite->outFile);
	free (temp);
	return rc;
}
*/
// ----------------------------------------------------------------------------
static LONG nox_fileWriter  (PSTREAM p , PUCHAR buf , ULONG len)
{
	PJWRITE pjWrite = p->handle;
	LONG rc = fwrite (buf, 1, len , pjWrite->outFile);
	return rc;
}
// ----------------------------------------------------------------------------
LONG nox_AsJsonTextMem (PNOXNODE pNode, PUCHAR buf , ULONG maxLenP)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	PSTREAM  pStream;
	LONG     len;
	JWRITE   jWrite;
	PJWRITE  pjWrite = &jWrite;
	memset(pjWrite , 0 , sizeof(jWrite));

	if (pNode == NULL) return 0;
	if (pNode->signature != NODESIG) {
		strcpy (buf, (PUCHAR) pNode);
		return strlen(buf);
	}

	pStream = stream_new (4096);
	pStream->writer  = nox_memWriter;
	pStream->handle = pjWrite;
	pjWrite->buf = buf;
	pjWrite->doTrim = true;
	pjWrite->maxSize =   pParms->OpDescList == NULL
		|| (pParms->OpDescList && pParms->OpDescList->NbrOfParms >= 3) ? maxLenP : MEMMAX;

	nox_AsJsonStream (pNode , pStream);
	len = pStream->totalSize;
	stream_putc   (pStream,'\0');
	stream_delete (pStream);
	return  len;

}
// ----------------------------------------------------------------------------
static void  nox_AsJsonStreamRunner   (PSTREAM pStream)
{
	PNOXNODE  pNode = pStream->context;
	nox_AsJsonStream (pNode , pStream);
}
// ----------------------------------------------------------------------------
PSTREAM nox_Stream  (PNOXNODE pNode)
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
	pStream->runner  = nox_AsJsonStreamRunner;
	pStream->context = pNode;
	return  pStream;
}
// ----------------------------------------------------------------------------
VOID nox_AsJsonText (PLVARCHAR res, PNOXNODE pNode)
{
	res->Length = nox_AsJsonTextMem ( pNode ,  res->String, sizeof(res->String));
}
/* ---------------------------------------------------------------------------
	 --------------------------------------------------------------------------- */
void nox_WriteJsonStmf (PNOXNODE pNode, PUCHAR FileName, int Ccsid, LGL trimOut, PNOXNODE options)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	PSTREAM pStream;
	JWRITE  jWrite;
	PJWRITE pjWrite= &jWrite;
	UCHAR   mode[32];
	UCHAR  sigUtf8[]  =  {0xef , 0xbb , 0xbf , 0x00};
	UCHAR  sigUtf16[] =  {0xff , 0xfe , 0x00};

	// Negative values trigger bom codes
	BOOL   makeBomCode  = Ccsid < 0;
	Ccsid = Ccsid < 0  ? - Ccsid : Ccsid;

	memset(pjWrite , 0 , sizeof(jWrite));

	if (pNode == NULL) return;

	pStream = stream_new (4096);
	pStream->handle = pjWrite;
	pStream->writer = nox_fileWriter;

	sprintf(mode , "wb,o_ccsid=%d", Ccsid);
	unlink  ( strTrim(FileName)); // Just to reset the CCSID which will not change if file exists
	pjWrite->outFile  = fopen ( strTrim(FileName) , mode );
	if (pjWrite->outFile == NULL) return;

	pjWrite->doTrim = (pParms->OpDescList && pParms->OpDescList->NbrOfParms >= 4 && trimOut == OFF) ? FALSE : TRUE;
	pjWrite->iconv  = XlateOpen(1208, Ccsid);

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

	nox_AsJsonStream (pNode , pStream);

	stream_delete (pStream);
	fclose(pjWrite->outFile);
	iconv_close(pjWrite->iconv);
}
