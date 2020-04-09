// CMD:CRTCMOD 
/* ------------------------------------------------------------- *
 * Company . . . : System & Method A/S                           *
 * Design  . . . : Niels Liisberg                                *
 * Function  . . : XML Parser                                    *
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
#include "noxdb2.h"
#include "parms.h"
// #include "rtvsysval.h"
#include "memUtil.h"
#include "strUtil.h"



// LONG  dbgStep=0;

//__thread BOOL  doTrim;


/* --------------------------------------------------------------------------- */
#pragma convert(1252)
static void nox_XmlDecode (PUCHAR out, PUCHAR in , ULONG inlen)
{
	PUCHAR p = out;
	PUCHAR pEnd = in  + inlen;
	UCHAR  c;

	while (in < pEnd)  {
		c = *(in);
		if (c == AMP) {
			PUCHAR kwd = in+1;
			if       (amemiBeginsWith(kwd ,"lt;"))  { *(p++) = LT  ; in += 4; }
			else if  (amemiBeginsWith(kwd ,"gt;"))  { *(p++) = GT  ; in += 4; }
			else if  (amemiBeginsWith(kwd ,"amp;")) { *(p++) = AMP ; in += 5; }
			else if  (amemiBeginsWith(kwd ,"apos;")){ *(p++) = APOS; in += 6; }
			else if  (amemiBeginsWith(kwd ,"quot;")){ *(p++) = QUOT; in += 6; }
			else if  (in[1] == HASH) {
				int n = 0;
				in += 2; // Skip the '&#'
				if (*in == 'x' || *in == 'X') {   // Hexadecimal representation
					in ++;
					while (*in != ';') {
						n = 16 * n + (hex(*in));
						in ++;
					}
				} else { // Decimal representation
					while (*in >= '0') {
						n = 10 * n + ((*in) - '0');
						in ++;
					}
				}
				if (n<=255) {
					*(p++) = n;
				// Unicode chars ...
				} else {
					int l = XlateBuf(p  , (PUCHAR) &n , 2 , 13488, 1208 );
					if (l==0 || *p <= ' ') { // Invalid char or replacement char ..
						*p = '.';
					}
					p++;
				}
				in ++;
			} else {
				*(p++) = c;
				in++;
			}
		} else {
			*(p++) = c;
			in++;
		}
	}
}
#pragma convert(0)

/* ---------------------------------------------------------------------------
	 --------------------------------------------------------------------------- */
void nox_AppendName (PNOXCOM pJxCom)
{
	PNOXNODE pNode;
	UCHAR c = *pJxCom->pFileBuf;

	if (*pJxCom->pNameIx > sizeof(pJxCom->StartName)) {
		nox_SetMessage( "Name to long at (%d:%d)", pJxCom->LineCount, pJxCom->ColCount);
		pJxCom->State = XML_EXIT_ERROR;
		return;
	}
	//Still a valid name 
	if (c > BLANK
	&&  c != QUOT
	&&  c != APOS
	&&  c != EQ
	&&  c != LT
	&&  c != GT
	&&  c != SLASH) {
		pJxCom->pName[(*pJxCom->pNameIx)++] = c;
		pJxCom->pName[(*pJxCom->pNameIx)]   = '\0';
		return;
	}
	// Name complete .. Add node 
	if (pJxCom->pName == pJxCom->StartName) {
		pJxCom->Level ++;
		pNode = (PNOXNODE) memAllocClear (sizeof(*pNode));

		pNode->signature  = NODESIG;
		pNode->Name = memStrDup (pJxCom->pName);

		pNode->pNodeParent = pJxCom->pNodeWorkRoot;
		if (pNode->pNodeParent->pNodeChildHead == NULL) {
			pNode->pNodeParent->pNodeChildHead = pNode;
			pNode->pNodeParent->pNodeChildTail = pNode;
		} else {
			pNode->Seq = pNode->pNodeParent->pNodeChildTail->Seq + 1; /* Increment Sibline number */
			pNode->pNodeParent->pNodeChildTail->pNodeSibling = pNode;
			pNode->pNodeParent->pNodeChildTail = pNode;
		}
		pNode->pNodeParent->pNodeChildTail = pNode;
	/* Ill be parent for succesive childs  */
		pJxCom->pNodeWorkRoot = pNode;
		pJxCom->StartLine =  pJxCom->LineCount;
		if (*pJxCom->Comment > '\0') {
			pNode->Comment = memStrDup(pJxCom->Comment+2);  // Skip the first <!--
			*pJxCom->Comment = '\0';
		}
	} else {

		if (stricmp(pJxCom->pName , pJxCom->pNodeWorkRoot->Name) != 0) {
			nox_SetMessage( "Invalid end tag </%s> for start tag <%s> at (%d:%d)" ,
				pJxCom->pName , pJxCom->pNodeWorkRoot->Name, pJxCom->LineCount, pJxCom->ColCount);
			pJxCom->State = XML_EXIT_ERROR;
			return;
		}
		pJxCom->pNodeWorkRoot = pJxCom->pNodeWorkRoot->pNodeParent;
		pJxCom->Level--;
	}
	pJxCom->State  = XML_ATTR_NAME;
	pJxCom->DataIx = 0;
	pJxCom->pAttr  = &pNode->pAttrList;
	nox_CheckEnd(pJxCom);
	SkipBlanks(pJxCom);
}
// ---------------------------------------------------------------------------
static void nox_AttrAppendName  (PNOXCOM pJxCom)
{
	PNOXATTR pAttr;
	UCHAR c = *pJxCom->pFileBuf;

/*
	 {
			static int debug ;
			debug ++;
			if (debug == 617) {
				 nox_Dump(pJxCom);
			}
	 }
*/

	// Still a valid name 
	if (c > BLANK
	&&  c != QUOT
	&&  c != APOS
	&&  c != EQ
	&&  c != LT
	&&  c != GT
	&&  c != SLASH) {
		CheckBufSize(pJxCom);
		pJxCom->Data[pJxCom->DataIx++] = c;
		pJxCom->Data[pJxCom->DataIx]   = '\0';
		return;
	}

/* Name complete .. Add node */
	if ( pJxCom->DataIx > 0) {
		pAttr = (PNOXATTR) memAlloc (sizeof(*pAttr));
		memset (pAttr , 0, sizeof(*pAttr));
		pAttr->signature  = NODESIG;
		pAttr->Name = memStrDup (pJxCom->Data);
		* pJxCom->pAttr = pAttr;
	}

	pJxCom->DataIx=0;
	pJxCom->Data[0]='\0';
	pJxCom->State = XML_ATTR_VALUE;
	nox_CheckEnd(pJxCom);
}
// ---------------------------------------------------------------------------
// When hitting that point we have to get rid of the <![CDATA[
// and the copy data until we find the ]]>
// ---------------------------------------------------------------------------
#pragma convert(1252)
void nox_CopyCdata (PNOXCOM pJxCom)
{
	PUCHAR p;

	nox_SkipChars(pJxCom , sizeof("<![CDATA[") -2) ; // omit the zero terminator
	p = nox_GetChar(pJxCom);
	while (! amemiBeginsWith(p , BRABRAGT  ) &&  pJxCom->State != XML_EXIT) {  // the "]]>"
		CheckBufSize(pJxCom);
		pJxCom->Data[pJxCom->DataIx++] = *p;
		p = nox_GetChar(pJxCom);
	}
	nox_SkipChars(pJxCom , sizeof(BRABRAGT) -2) ; // omit the zero terminator
	pJxCom->Data[pJxCom->DataIx]   = '\0';
}
#pragma convert(0)
// ---------------------------------------------------------------------------
#pragma convert(1252)
void nox_AppendData (PNOXCOM pJxCom)
{
	UCHAR lookahead;
	UCHAR c = *pJxCom->pFileBuf;

/* Still a valid name � */
	if (c == LT ) {
	// Check for CDATA stream ... copy until ]]>
		if (amemiBeginsWith(pJxCom->pFileBuf , CDATA )) {   // the "<![CDATA["
			nox_CopyCdata (pJxCom);
			return;
		}
		lookahead = *(pJxCom->pFileBuf+1);
		if (lookahead == EQ
		||  lookahead == GT
		||  lookahead == APOS
		||  lookahead == QUOT) {
			CheckBufSize(pJxCom);
			pJxCom->Data[pJxCom->DataIx++] = c;
			pJxCom->Data[pJxCom->DataIx]   = '\0';
			return;
		}

		if (lookahead == SLASH
		||  lookahead == EXCLMARK
		||  lookahead > BLANK      ) {
			pJxCom->State = XML_DETERMIN_TAG_TYPE;
			if (pJxCom->pName == pJxCom->StartName) {
				if (pJxCom->DataIx > 0) {
					pJxCom->pNodeWorkRoot->Value = memAlloc (pJxCom->DataIx + 1) ;
					nox_XmlDecode( pJxCom->pNodeWorkRoot->Value  , pJxCom->Data , pJxCom->DataIx + 1);
				}
			}
			return;
		} else {
			int debug = 0;
		}
	}
	CheckBufSize(pJxCom);
	pJxCom->Data[pJxCom->DataIx++] = c;
	pJxCom->Data[pJxCom->DataIx]   = '\0';
}
#pragma convert(0)
// ---------------------------------------------------------------------------
static void nox_AttrAppendValue  (PNOXCOM pJxCom)
{
	PNOXATTR pAttr;
	UCHAR c = *pJxCom->pFileBuf;

	// Find wich kind of quote 
	if (pJxCom->fnyt == '\0') {
		if (c <= BLANK) {
			return;
		}
		if (c == APOS || c== QUOT) {
			pJxCom->fnyt = c;
		}
		return;
	}
	// End of value 
	if (c == pJxCom->fnyt) {
		pJxCom->fnyt = '\0';
		if (pJxCom->DataIx > 0) {
			pAttr =  *pJxCom->pAttr;
			if (pAttr==NULL) {
				nox_SetMessage( "Invalid attribute termination at (%d:%d)", pJxCom->LineCount, pJxCom->ColCount);
				pJxCom->State = XML_EXIT_ERROR;
				return;
			}
			pAttr->Value = memAlloc (pJxCom->DataIx + 1) ;
			nox_XmlDecode(pAttr->Value   , pJxCom->Data , pJxCom->DataIx + 1);
		}
		pJxCom->DataIx = 0;
		pJxCom->State = XML_ATTR_NAME;
		pJxCom->pAttr = & ((*pJxCom->pAttr)->pAttrSibling);
		if (pJxCom->StartLine != pJxCom->LineCount) {
			pJxCom->pNodeWorkRoot->newlineInAttrList = TRUE;
		}
		SkipBlanks(pJxCom);
		return;
	}
	// Normal just append to the value
	CheckBufSize(pJxCom);
	pJxCom->Data[pJxCom->DataIx++] = c;
	pJxCom->Data[pJxCom->DataIx]   = '\0';
}
// ---------------------------------------------------------------------------
BOOL nox_ParseXml (PNOXCOM pJxCom)
{
	UCHAR  c;
	PUCHAR p;
	BOOL  debug = FALSE;
	// dbgStep=0;

	for(;;) {
		p = nox_GetChar(pJxCom);
		c = *p;
		switch (pJxCom->State) {
			case XML_FIND_START_TOKEN:
				if (c == LT ) {
					pJxCom->State = XML_DETERMIN_TAG_TYPE;
				}
				break;

			case XML_DETERMIN_TAG_TYPE:

	            #pragma convert(1252)
				if (amemiBeginsWith(p , REMARK  )) {  // the "!--"
					int commentIx =0;
					do {
						p = nox_GetChar(pJxCom);
						if (commentIx < COMMENT_SIZE -1) {
							pJxCom->Comment[commentIx++] = *p;
						}
					} while (! amemiBeginsWith (p , ENDREMARK ) && pJxCom->State != XML_EXIT);  // EndRemark "-->"
		            #pragma convert(0)
					pJxCom->Comment[commentIx-1] = '\0';
					pJxCom->State = XML_FIND_END_TOKEN;
				} else if (amemiBeginsWith(p , DOCTYPE  )) {  // the "!DOCTYPE"
					pJxCom->State = XML_FIND_END_TOKEN;
				} else if (c == QUESTION) {  // the ?
					pJxCom->State = XML_FIND_END_TOKEN;
				} else if (c == SLASH) {   //  the /
					pJxCom->State = XML_BUILD_NAME;
					pJxCom->pNameIx = &pJxCom->EndNameIx;
					pJxCom->pName   = pJxCom->EndName;
					*pJxCom->pNameIx = 0;

				} else {
					pJxCom->State = XML_BUILD_NAME;
					pJxCom->pNameIx = &pJxCom->StartNameIx;
					pJxCom->pName   = pJxCom->StartName;
					*pJxCom->pNameIx = 0;
					nox_AppendName (pJxCom);
				}
				break;

			case XML_BUILD_NAME:
				nox_AppendName (pJxCom);
				break;

			case XML_ATTR_NAME:
				nox_AttrAppendName(pJxCom);
				break;

			case XML_ATTR_VALUE:
				nox_AttrAppendValue(pJxCom);
				break;

			case XML_COLLECT_DATA:
				nox_AppendData (pJxCom);
				break;

			case XML_FIND_END_TOKEN:
				if (c == GT ) {
					pJxCom->State = XML_FIND_START_TOKEN;
				}
				break;

			case XML_EXIT:
				if (debug) {
					nox_Dump(pJxCom->pNodeRoot);
				}
				// printf("\ndbgStep:%d\n" , dbgStep);
				// getchar();

				memFree(&pJxCom->Data);
				if (pJxCom->Level == 0) {
					return false;
				} else {
					pJxCom->State = XML_EXIT_ERROR;
					nox_SetMessage( "Unexpected end of inputstream");
					return true;
				}

			case XML_EXIT_ERROR:
				memFree(&pJxCom->Data);
				return true;
		}
	}
}
// ---------------------------------------------------------------------------
void nox_WriteXmlStmf (PNOXNODE pNode, PUCHAR FileName, int CcsidP, LGL trimOutP , PNOXNODE optionsP)
{
	FILE * f;
	iconv_t Iconv;
	UCHAR mode[32];
	PUCHAR enc;
	PUCHAR sig;
	UCHAR  sigUtf8[]  =  {0xef , 0xbb , 0xbf , 0x00};
	UCHAR  sigUtf16[] =  {0xff , 0xfe , 0x00};
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	PUCHAR  value;
	PUCHAR  dft;
	VARCHAR res;

	int      Ccsid   = pParms->OpDescList->NbrOfParms >= 3 ? CcsidP : 1208; 
	LGL      trimOut = pParms->OpDescList->NbrOfParms >= 4 ? trimOutP: ON; 
	PNOXNODE options = pParms->OpDescList->NbrOfParms >= 5 ? optionsP : NULL;
	

	if (pNode == NULL) return;

	if (pNode->pNodeParent == NULL
	&&  pNode->Name       == NULL) {
		if (pNode->pNodeChildHead != NULL) {
			// TODO!! This root Nodeens empty in some case; the first child is actually the root
			pNode = pNode->pNodeChildHead;
		}
	}
	if (pNode == NULL) return;

	// TODO!! need unlink to replace !!
	sprintf(mode , "wb,codepage=%d", Ccsid);
	f = fopen ( strTrim(FileName) , mode );
	if (f == NULL) return;

	Iconv = XlateOpen (1208 , Ccsid );

	#pragma convert(1252)
	switch(Ccsid) {
		case 1252 :
			enc = "WINDOWS-1252";
			sig = "";
			break;
		case 1208 :
			enc = "UTF-8";
			sig = sigUtf8;
			break;
		case 1200 :
			enc = "UTF-16";
			sig = sigUtf16;
			break;
		case 819  :
			enc = "ISO-8859-1";
			sig = "";
			break;
		default   :
			enc = "windows-1252";
			sig = "";
	}

	fputs (sig , f);
	fputs ("<?xml version=\"1.0\" encoding=\"", f);
	fputs (enc, f);
	fputs ("\" ?>", f);


	#pragma convert(0)
	nox_WriteXmlStmfNodeList (f , &Iconv , pNode);
	fclose(f);
	iconv_close(Iconv);
}
