// CMD:CRTCMOD 
/* ------------------------------------------------------------- *
 * Company . . . : System & Method A/S                           *
 * Design  . . . : Niels Liisberg                                *
 * Function  . . : NOX - main service program API exports        *
 *                                                               *
 * By     Date     Task    Description                           *
 * NL     02.06.03 0000000 New program                           *
 * NL     27.02.08 0000510 Allow also no namespace for *:tag     *
 * NL     27.02.08 0000510 nox_NodeCopy                           *
 * NL     13.05.08 0000577 nox_NodeAdd / WriteNote                *
 * NL     13.05.08 0000577 Support for refference location       *
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
#include "parms.h"
// #include "rtvsysval.h"
#include "strUtil.h"
#include "memUtil.h"
#include "streamer.h"
#include "noxdb2.h"


// --------------------------------------------------------------------------- 
// CSV Helpers
// --------------------------------------------------------------------------- 
void csvReplaceDecpoint ( PUCHAR out , PUCHAR in , UCHAR decpoint)
{
	for(;*in; in++) {
		*out++ = (*in == '.') ? decpoint: *in;
	}
	*out = '\0';
}
// --------------------------------------------------------------------------- 
void csvStringEscape (PUCHAR out, PUCHAR in)
{

	*out++ = '"';
	while(*in) {
		if (*in == '"') *out++ = '"';
		*out++ = *in++;
	}
	*out++ = '"';
	*out = '\0';
}
// --------------------------------------------------------------------------- 
void nox_WriteCsvStmf (PNOXNODE pNode, PUCHAR FileName, int Ccsid, LGL trimOut, PNOXNODE options)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	JWRITE jWrite;
	PJWRITE pjWrite = &jWrite;
	UCHAR  mode[32];
	UCHAR  sigUtf8[]  =  {0xef , 0xbb , 0xbf , 0x00};
	UCHAR  sigUtf16[] =  {0xff , 0xfe , 0x00};
	UCHAR  CrLf []= {0x0d, 0x0a , 0x00};
	UCHAR  wTemp[100000];
	UCHAR  temp [32766];
	UCHAR  comma    = ';';
	UCHAR  decpoint = '.';
	BOOL   headers  = false;

	if (pNode == NULL) return;
	memset(pjWrite , 0 , sizeof(jWrite));

	sprintf(mode , "wb,codepage=%d", Ccsid);
	pjWrite->outFile  = fopen ( strTrim(FileName) , mode );
	if (pjWrite->outFile == NULL) return;

	if (pParms->OpDescList == NULL || pParms->OpDescList->NbrOfParms >= 5) {
		PNOXNODE  pOptions  = nox_ParseString((PUCHAR) options ); // When already a object: simply returns that
		comma    = *nox_GetValuePtr    (pOptions , "delimiter" , &comma );
		decpoint = *nox_GetValuePtr    (pOptions , "decPoint"  , &decpoint );
		headers  = (ON == nox_IsTrue   (pOptions , "headers"));
		if (pOptions != options) nox_Close(&pOptions); // It was already a josn object , then don't close
	}

	pjWrite->buf    = wTemp;
	pjWrite->iconv  = XlateOpen(1208 , Ccsid );

	switch(Ccsid) {
		case 1208 :
			fputs (sigUtf8 , pjWrite->outFile);
			break;
		case 1200 :
			fputs (sigUtf16 , pjWrite->outFile);
			break;
	}

	if ( pNode == NULL || pNode->pNodeChildHead  == NULL) return;

	// Arrays - need first child;
	pNode = pNode->pNodeChildHead;

	// Need the headers as first row;
	if (headers) {
		PNOXNODE pHead  = pNode->pNodeChildHead;
		while (pHead) {
			csvStringEscape (temp , pHead->Name);
			iconvWrite(pjWrite->outFile ,&pjWrite->iconv, temp, FALSE);
			pHead  = pHead->pNodeSibling;
			if (pHead) iconvPutc(pjWrite->outFile , &pjWrite->iconv, comma);
		}
		// newline
		fwrite (CrLf , 1 , 2 , pjWrite->outFile);
	}

	while (pNode) {

		PNOXNODE pCol  = pNode->pNodeChildHead;

		while (pCol) {

			if (pCol->Value) {

				if (pCol->isLiteral) {
					if (decpoint == '.') {
						iconvWrite(pjWrite->outFile ,&pjWrite->iconv, pCol->Value, FALSE);
					} else {
						csvReplaceDecpoint (temp , pCol->Value , decpoint);
						iconvWrite(pjWrite->outFile ,&pjWrite->iconv, temp, FALSE);
					}
				} else {
					csvStringEscape (temp , pCol->Value);
					iconvWrite(pjWrite->outFile ,&pjWrite->iconv, temp, FALSE);
				}
			}
			pCol  = pCol->pNodeSibling;
			if ( pCol) iconvPutc(pjWrite->outFile , &pjWrite->iconv, comma);
		}
		// newline
		fwrite (CrLf , 1 , 2 , pjWrite->outFile);
		pNode = pNode->pNodeSibling;

	}

	fclose(pjWrite->outFile);
	iconv_close(pjWrite->iconv);
}
