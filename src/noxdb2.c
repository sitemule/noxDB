// CMD:CRTCMOD 
/* -------------------------------------------------------------
 * Company . . . : System & Method A/S                          
 * Design  . . . : Niels Liisberg                               
 * Function  . . : NOX - main service program API exports       
 *                                                              
 * By     Date     Task    Description                          
 * ------ -------- ------- -------------------------------------
 * NL     02.06.03 0000000 New program                          
 * NL     27.02.08 0000510 Allow also no namespace for *:tag    
 * NL     27.02.08 0000510 nox_NodeCopy                         
 * NL     13.05.08 0000577 nox_NodeAdd / WriteNote              
 * NL     13.05.08 0000577 Support for refference location      
 * NL     01.06.18 0001000 noxdb2 version 2 implementation
 * 
 * 
 * Note differences from noxDB version 1
 * 1: The obect graph is all UTF-8
 * 2: Output is by default witout BOM codes
 * 3: Input and output values are default 1M in size 
 * ------------------------------------------------------------- */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h>
#include <leod.h>
#include <decimal.h>
#include <wchar.h>
#include <errno.h>

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
#include "e2aa2e.h"

// Global thread vars
__thread UCHAR jxMessage[512];
__thread BOOL  jxError = false;

//  BOOL  skipBlanks = TRUE;
__thread BOOL  doTrim;
__thread PNOXCOM pJxCom;
__thread BOOL   debugger = false;
__thread UCHAR  nox_DecPoint = '.';

// iconv_t xlateEto1208;
// iconv_t xlate1208toE;
static INT64 LVARCHARNULL =0;
static PLVARCHAR PLVARCHARNULL = (PLVARCHAR) &LVARCHARNULL;

#pragma convert(1252)
static const PUCHAR delimiters = DELIMITERS;
#pragma convert(0)


// --------------------------------------------------------------------------- 
void nox_SetMessage (PUCHAR Ctlstr , ... )
{
	va_list arg_ptr;
	if (*jxMessage > ' ') return; // Already made

	// Build a temp string with the formated data  */
	va_start(arg_ptr, Ctlstr);
	vsprintf(jxMessage, Ctlstr, arg_ptr);
	va_end(arg_ptr);
}
// ---------------------------------------------------------------------------
void  freeNodeValue(PNOXNODE pNode)
{
	if (pNode->type != POINTER_VALUE) {
		memFree(&pNode->Value );
	}
}
/* ------------------------------------------------------------- */
PNOXNODE nox_traceNode (PUCHAR text, PNOXNODE pNode)
{
	static int i;
	UCHAR filename [128];

	if (debugger ==0)  return pNode;

	if (debugger == 1) {
		sprintf(filename, "/tmp/jsonxml-%05.5d.json" , i ++);
		nox_WriteJsonStmf (pNode, filename , 1208, OFF, NULL);
	} else if (debugger == 2) {
		UCHAR temp [65536];
		int l = nox_AsJsonTextMem (pNode , temp , sizeof(temp));
		// TODO!! 2 ebcdic
		temp [l] = 0;
		puts (text);
		puts (temp);
		puts ("\n");
	}
	return pNode;
}

/* --------------------------------------------------------------------------- */
void nox_SetDecPoint(PUCHAR p)
{
	nox_DecPoint = *p;
}
/* --------------------------------------------------------------------------- */
FIXEDDEC nox_Num (PUCHAR in)
{
	FIXEDDEC        Res   = 0D;
	decimal(17,16)  Temp  = 0D;
	decimal(17)     Decs  = 1D;
	BOOL  DecFound = FALSE;
	UCHAR c = '0';
	int   FirstDigit = -1;
	int   LastDigit = -1;
	int   i;
	int   Dec=0;
	int   Prec=0;
	int   l = strlen (in);

	for (i=0; i < l ; i++) {
		c = in[i];
		if (c >= '0' && c <= '9' ) {
			if (FirstDigit == -1) FirstDigit = i;
			LastDigit = i;
			if (DecFound) {
				if (++Prec <= 15) {
					Decs  *= 10D;
					Temp = (c - '0');
					Temp /= Decs;
					Res += Temp;
				}
			} else {
				if (Dec < 15) {
					Res = Res * 10D + (c - '0');
					if (Res > 0D) Dec++;
				}
			}
		} else if (c == nox_DecPoint) {
			DecFound = TRUE;
		}
	}
	if ((FirstDigit > 0 && in[FirstDigit-1] == '-')
	||  (LastDigit  > 0 && in[LastDigit+1]  == '-' && (LastDigit + 1) < l )) {
		Res = - Res;
	}
	return (Res );
}
/* --------------------------------------------------------------------------- */
#pragma convert(1252)
FIXEDDEC nox_aNum (PUCHAR in)
{
	FIXEDDEC        Res   = 0D;
	decimal(17,16)  Temp  = 0D;
	decimal(17)     Decs  = 1D;
	BOOL  DecFound = FALSE;
	UCHAR c = '0';
	int   FirstDigit = -1;
	int   LastDigit = -1;
	int   i;
	int   Dec=0;
	int   Prec=0;
	int   l = strlen (in);

	for (i=0; i < l ; i++) {
		c = in[i];
		if (c >= '0' && c <= '9' ) {
			if (FirstDigit == -1) FirstDigit = i;
			LastDigit = i;
			if (DecFound) {
				if (++Prec <= 15) {
					Decs  *= 10D;
					Temp = (c - '0');
					Temp /= Decs;
					Res += Temp;
				}
			} else {
				if (Dec < 15) {
					Res = Res * 10D + (c - '0');
					if (Res > 0D) Dec++;
				}
			}
		} else if (c == nox_DecPoint) {
			DecFound = TRUE;
		}
	}
	if ((FirstDigit > 0 && in[FirstDigit-1] == '-')
	||  (LastDigit  > 0 && in[LastDigit+1]  == '-' && (LastDigit + 1) < l )) {
		Res = - Res;
	}
	return (Res );
}
#pragma convert (0)
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
				*(p++) = n;
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

// ---------------------------------------------------------------------------
static void freeAttrList (PNOXATTR pAttr)
{
	PNOXATTR pAttrTemp, pAttrNext;

	for (pAttrTemp = pAttr; pAttrTemp ; pAttrTemp = pAttrNext){
		pAttrNext = pAttrTemp->pAttrSibling;
		memFree(&pAttrTemp->Value);
		memFree(&pAttrTemp->Name);
		memFree(&pAttrTemp);
	}
}
// ---------------------------------------------------------------------------
// Delete the node, with out the relations
// Used in bulk cleanup
// ---------------------------------------------------------------------------
void nox_NodeFreeNodeOnly(PNOXNODE pNode)
{
	if (pNode == NULL
	||  pNode->signature != NODESIG) {
		return;
	}
	pNode->signature = 0; // never delete me again - even if unatended...
	freeNodeValue(pNode);
	memFree(&(pNode->Name));
	memFree(&(pNode->Comment));
	freeAttrList (pNode->pAttrList);
	memFree (&pNode);
}
// ---------------------------------------------------------------------------
static void nox_NodeFree(PNOXNODE pNode)
{
	nox_NodeFreeNodeOnly(pNode);
}
// ---------------------------------------------------------------------------
void nox_NodeRename(PNOXNODE pNode, PUCHAR name)
{
	if (pNode == NULL) return;

	memFree(&pNode->Name);
	pNode->Name = memStrDup(name);
}
// ---------------------------------------------------------------------------
void nox_NodeRenameVC(PNOXNODE pNode, PLVARCHAR name)
{
	nox_NodeRename(pNode, plvc2str(name));
}

// ---------------------------------------------------------------------------
PUCHAR nodevalue  (PNOXNODE p)
{
	if (p == NULL || p->Value == NULL) return "";
	return p->Value;
}
// ---------------------------------------------------------------------------
int doubleCmp (double x, double y)
{
	if (x < y) return -1;
	if (x > y) return  1;
	return 0;
}
// ---------------------------------------------------------------------------
double num2float(PUCHAR s)
{
	return nox_aNum(s);
}
// ---------------------------------------------------------------------------
#pragma convert(1252)
BOOL isNumberNodeStrict (PNOXNODE node)
{
	UCHAR c;
	PUCHAR p;

	if (node == NULL
	||  node->isLiteral == false
	||  node->Value == NULL) {
		return false;
	}
	c = *node->Value;
	return ((c >= '0' && c <= '9') || c == '-');
}
#pragma convert(0)
// ---------------------------------------------------------------------------
#pragma convert(1252)
BOOL isNumberNodeLoose  (PNOXNODE node)
{
	UCHAR c;
	PUCHAR p;

	if (node == NULL
	||  node->Value == NULL) {
		return false;
	}
	p = node->Value;
	for (;*p == ' ' ; p++); // Skip leading blanks
	c = *p;
	return ((c >= '0' && c <= '9') || c == '-');
}
#pragma convert(0)
// ---------------------------------------------------------------------------
LGL nox_IsLiteral (PNOXNODE node)
{
	BOOL isString = (
		 node
		 &&  node->isLiteral == false
		 &&  node->Value
	);
	return isString ?  OFF:ON ;
}
// ---------------------------------------------------------------------------
// use simple bouble-sort to sort an array by keyvalues
// ---------------------------------------------------------------------------
#pragma convert(1252) 
PNOXNODE nox_ArraySort(PNOXNODE pNode, PUCHAR fields, BOOL useLocale)
{
	PNOXNODE pNodeNext, pNode1, pNode2, pCompNode1, pCompNode2 ;
	BOOL    bubles;
	UCHAR   keys [256][256];
	BOOL    descending [256];
	int     kix, kx, comp ;

	// Set function pointers for callback
	//double (* getnumberval)(PUCHAR s)  =  useLocale ? num2float   : num2floatLocale;
	double (* getnumberval)(PUCHAR s)  =  num2float ;
	BOOL   (* isNumberNode)(PNOXNODE n) =  useLocale ? isNumberNodeLoose : isNumberNodeStrict;

	// if (pNode == NULL || pNode->type != ARRAY) return;

	// Lets allow to sourt anuthing ( XML will work too then)
	if (pNode == NULL) return;

	// Split the list into array elements
	// handle the following syntax:
	//    key1:ASC,key2:DESC,key3,key:desc
	for(kix=0 ; kix < 256 ; kix ++) {
		UCHAR key [256];
		UCHAR descStr  [256];
		if (*subword(key, fields, kix , ",") == '\0') break;
		subword(keys[kix], key, 0 , ":");
		subword(descStr  , key, 1 , ":");
		descending[kix] = amemiBeginsWith(descStr , "desc");
	}

	do {
		bubles = false;
		pNode1  = pNode->pNodeChildHead;
		if (pNode1 == NULL ) return;
		pNode2  = pNode1->pNodeSibling;

		while (pNode2) {
			for(kx = 0; kx < kix ; kx++)  {
				PUCHAR v1, v2;
				pCompNode1 = nox_GetNode  (pNode1 ,keys[kx]);
				pCompNode2 = nox_GetNode  (pNode2 ,keys[kx]);
				v1 = nodevalue(pCompNode1);
				v2 = nodevalue(pCompNode2);

				if (isNumberNode(pCompNode1) && isNumberNode(pCompNode2)) {
					comp = doubleCmp (getnumberval(v1) , getnumberval (v2));
				} else {
					comp = strcmp (v1, v2);
				}

				if (descending[kx]) {
					comp = - comp;
				}

				switch (comp) {
					case 0: break;
					case 1: {
						bubles = true;
						nox_SwapNodes(&pNode1, &pNode2);
						kx = kix; // done
						break;
					}
					case -1:{
						kx = kix; // done
						break;
					}
				}
			}
			// Setup next;
			pNode1 = pNode1->pNodeSibling;
			pNode2 = pNode2->pNodeSibling;
		}
	} while(bubles);

	return pNode;
}
#pragma convert(0) 

PNOXNODE nox_ArraySortVC(PNOXNODE pNode, PLVARCHAR fieldsP, USHORT optionsP)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	PUCHAR  fields = (pParms->OpDescList->NbrOfParms >= 2) ? plvc2str(fieldsP) : "";
	BOOL    useLocale =  (pParms->OpDescList->NbrOfParms >= 3) ? optionsP & 1: false;

	return nox_ArraySort(pNode, fields, useLocale);
}
// ---------------------------------------------------------------------------
void nox_FreeSiblings(PNOXNODE pNode)
{
	PNOXNODE pNodeNext;

	while (pNode) {
		pNodeNext=pNode->pNodeSibling;
		nox_FreeChildren (pNode);
		nox_NodeFree(pNode);
		pNode=pNodeNext;
	}
}
// -------------------------------------------------------------
void nox_FreeChildren (PNOXNODE pNode)
{
	nox_FreeSiblings(pNode->pNodeChildHead);
	pNode->pNodeChildHead = NULL;
	pNode->pNodeChildTail = NULL;
	pNode->Count = 0;
}
// -------------------------------------------------------------
void nox_DumpNodeList (PNOXNODE pNodeTemp)
{
	PNOXNODE  pNodeNext;
	PNOXATTR pAttrTemp;

	while (pNodeTemp) {
		PNOXNODE p;
		PUCHAR in ="";
		printf("\n");

		for (p=pNodeTemp; p && p->pNodeParent ; p=p->pNodeParent) {
			if (p->Name && * p->Name) {
				printf("%s%s (line:%d)" , in , p->Name , p->lineNo);
			} else {
				printf("%s%i" , in , p->Handle);
			}

			in = " in ";
		}

		printf("\n   Value: %s" , pNodeTemp->Value == NULL ? "(null)" : pNodeTemp->Value);

		for (pAttrTemp = pNodeTemp->pAttrList; pAttrTemp ; pAttrTemp = pAttrTemp->pAttrSibling){
			printf("\n   Attribute: %s = %s" , 
				pAttrTemp->Name == NULL ? "" : pAttrTemp->Name,
				pAttrTemp->Value== NULL ? "" : pAttrTemp->Value);
		}
		nox_DumpNodeList(pNodeTemp->pNodeChildHead);
		pNodeTemp = pNodeTemp->pNodeSibling;
	}
}
// -------------------------------------------------------------
static ULONG sumString (PUCHAR p)
{
	ULONG sum = 0;
	if (p == NULL) return 0;
	while (*p) {
		sum += *(p++);
	}
	return sum;
}
// -------------------------------------------------------------
ULONG nox_NodeCheckSum (PNOXNODE pNode)
{
	PNOXNODE  pNodeNext;
	PNOXATTR pAttrTemp;
	ULONG    sum =0;

	while (pNode) {

		sum += sumString (pNode->Name);
		sum += sumString (pNode->Value);

		for (pAttrTemp = pNode->pAttrList; pAttrTemp ; pAttrTemp = pAttrTemp->pAttrSibling){
			sum += sumString (pAttrTemp->Name);
			sum += sumString (pAttrTemp->Value);
		}
		sum += nox_NodeCheckSum (pNode->pNodeChildHead);
		pNode = pNode->pNodeSibling;
	}
	return sum;
}
// ---------------------------------------------------------------------------
#pragma convert(1252)
void nox_WriteXmlStmfNodeList (FILE * f, iconv_t * pIconv ,PNOXNODE pNode)
{
	PNOXNODE  pNodeTemp, pNodeNext;
	PNOXATTR pAttrTemp;
	static int level = 0;
	UCHAR    tab[256];
	BOOL     shortform;

#pragma convert(0)
	PUCHAR  defaultNode = "row";
#pragma convert(1252)

	if ( pNode == NULL) return;

	//' Make indention
	tab [0] = 0x0d;
	tab [1] = 0x0a;
	memset(tab+2, 0x20 ,level*2);
	tab [2 + (level*2)] = '\0';

	level++;

	while (pNode) {

		if (pNode->Comment) {
			if (!doTrim)  fputs ( tab,  f);
			fputs ( "<!--",  f);
			iconvWrite(f,pIconv, pNode->Comment, FALSE);
			fputs ( "-->",  f);
		}

		if (!doTrim)  fputs ( tab,  f);
		fputs ("<", f);
		iconvWrite(f,pIconv, pNode->Name ? pNode->Name: defaultNode, FALSE);

		for (pAttrTemp = pNode->pAttrList; pAttrTemp ; pAttrTemp = pAttrTemp->pAttrSibling){
			if (pNode->newlineInAttrList) {
				if (!doTrim)  fputs ( tab,  f);
				fputs ("  ", f);
			} else {
				fputc( 0x20 , f);
			}
			iconvWrite( f,pIconv, pAttrTemp->Name, FALSE);
			fputs("=\"" , f);
			iconvWrite( f,pIconv, pAttrTemp->Value, TRUE);
			fputs("\"", f);
		}

		shortform = TRUE;

		if (pNode->Value != NULL && pNode->Value[0] > '\0') {
			shortform = FALSE;
			fputs(">", f);
			iconvWrite( f,pIconv, pNode->Value, TRUE);
		}

		if (pNode->pNodeChildHead) {
			shortform = FALSE;
			if (pNode->Value != NULL && pNode->Value[0] > '\0') {
			// Already put - in the above
			} else {
				fputs(">", f);
			}
			nox_WriteXmlStmfNodeList (f, pIconv, pNode->pNodeChildHead);
		}

		if (shortform) {
			if (pNode->newlineInAttrList) {
				if (!doTrim)  fputs ( tab,  f);
			}
			fputs("/>", f);
		} else {
			if (pNode->pNodeChildHead) {
				if (!doTrim)  fputs ( tab,  f);
			}
			fputs("</" , f);
			iconvWrite( f,pIconv, pNode->Name ? pNode->Name : defaultNode , FALSE);
			fputs(">", f);
		}

		if (level == 1) {
			pNode = NULL;
		} else {
			pNode = pNode->pNodeSibling;
		}
	}

	level --;
}
#pragma convert(0)
// ---------------------------------------------------------------------------
LONG nox_AsXmlTextMem (PNOXNODE pNode, PUCHAR buf)
{
	PNOXNODE    pNodeTemp, pNodeNext;
	PNOXATTR   pAttrTemp;
	static int level = 0;
	BOOL       shortform;
	PUCHAR     temp = buf;

	level++;

	while (pNode) {

		temp +=  sprintf(temp , "<%s", pNode->Name ? pNode->Name : "row");
		for (pAttrTemp = pNode->pAttrList; pAttrTemp ; pAttrTemp = pAttrTemp->pAttrSibling){
			temp +=  sprintf(temp , " %s=\"%s\"", pAttrTemp->Name, pAttrTemp->Value);
		}

		shortform = TRUE;

		if (pNode->Value != NULL && pNode->Value[0] > '\0') {
			shortform = FALSE;
			temp +=  sprintf(temp , ">%s", pNode->Value);
		}

		if (pNode->pNodeChildHead) {
			shortform = FALSE;
			if (pNode->Value != NULL && pNode->Value[0] > '\0') {
				// Already put - in the above
			} else {
				temp +=  sprintf(temp , ">");
			}
			temp += nox_AsXmlTextMem (pNode->pNodeChildHead , temp);
		}

		if (shortform) {
			temp +=  sprintf(temp , "/>");
		} else {
			temp +=  sprintf(temp , "</%s>", pNode->Name ? pNode->Name : "row");
		}

		if (level == 1) {
			pNode = NULL;
		} else {
			pNode = pNode->pNodeSibling;
		}
	}

	level --;
	return temp - buf;

}
// ---------------------------------------------------------------------------
VOID nox_AsXmlText (PLVARCHAR res , PNOXNODE pNode)
{
	res->Length = nox_AsXmlTextMem (pNode , res->String);
}
// ---------------------------------------------------------------------------
// Traverse up the tree and build the name  like: "root/tree/node"
// --------------------------------------------------------------------------- 
VARCHAR nox_GetNodeNameAsPath (PNOXNODE pNode, UCHAR Delimiter)
{
	PNOXNODE  p;
	VARCHAR  res;
	UCHAR    buf  [4096];
	PUCHAR   pBuf, pBufEnd;
	int len , i =0;

	res.Length = 0;
	if ( pNode == NULL) return res;
	pBuf = pBufEnd = buf + sizeof(buf) -1;

	p = pNode;
	while (p) {

		if (p->Name  &&  *p->Name > ' ') {
			if (i++) {
				pBuf --;
				*pBuf = Delimiter;
			}

			len = memSize(p->Name)  -1; // with out the zero term ;
			pBuf -= len ;
			memcpy(pBuf,p->Name, len);
		}
		p = p->pNodeParent;
	}

	res.Length = pBufEnd - pBuf;
	substr(res.String , pBuf , res.Length );
	return res;
}
/* --------------------------------------------------------------------------- */
SHORT nox_GetNodeType (PNOXNODE pNode)
{
	return (pNode) ? pNode->type : 0;
}
// ---------------------------------------------------------------------------
void nox_NodeCloneAndReplace (PNOXNODE pDest , PNOXNODE pSource)
{
	PNOXNODE  pNewNode = nox_NodeClone (pSource);
	nox_NodeMoveAndReplace (pDest, pNewNode);
}
// ---------------------------------------------------------------------------
//	 This works great, have to go back and update the "cloneFormat" logic to do similar
// --------------------------------------------------------------------------- 
#pragma convert(1252)
void  nox_MergeList (PNOXNODE pDest, PNOXNODE pSource, PJWRITE pjWrite, PUCHAR name, PNOXNODE pParent, MERGEOPTION merge)
{
	PNOXNODE  p;
	UCHAR tempname[256];
	PNOXNODE pDestNode , pEdt ;
	int ix =0;

	while (pSource) {

		if (pParent && pParent->type == ARRAY) {
			sprintf(tempname,"%s[%d]", name , ix++  );
		} else if (pSource->Name && *pSource->Name){
			sprintf(tempname,"%s/%s", name , pSource->Name);
		} else {
			strcpy (tempname,name );
		}

		if (pSource->type == VALUE) {
			PUCHAR relName = tempname+1; // Remove first slash absolut and make it relative
			// printf("\n%s - %s : %d val:%s\n" , tempname , pSource->Name, pjWrite->level,pSource->Value);

			pDestNode = nox_GetNode  (pDest, relName);
			if (pDestNode != NULL) {
				if (merge == MO_MERGE_REPLACE || merge == MO_MERGE_MATCH) {
					nox_NodeSet(pDestNode , pSource->Value);
				}
			} else {
				if (merge == MO_MERGE_REPLACE || merge == MO_MERGE_NEW ) {
					pEdt = nox_SetValueByName  (pDest , relName, pSource->Value, pSource->type);
					pEdt->isLiteral = pSource->isLiteral;
				}
			}
		}

		if (pSource->pNodeChildHead) {
			pjWrite->level ++;
			nox_MergeList (pDest , pSource->pNodeChildHead,pjWrite, tempname , pSource, merge  );
			pjWrite->level --;
		}
		// Merging only take the first occurent where the object object names has a match
		// pSource = (pjWrite->level == 0) ? NULL: pSource->pNodeSibling;
		pSource = pSource->pNodeSibling;
	}
}
#pragma convert(0)
/* --------------------------------------------------------------------------- */
PNOXNODE  nox_InsertByName (PNOXNODE pDest , PUCHAR name , PNOXNODE pSource )
{
	PNOXNODE pNode;

	if ( pSource->type == OBJECT || pSource->type == ARRAY ) {
		pNode  =  nox_NodeCopy (pDest, pSource , RL_LAST_CHILD);
		pNode->Name = memStrDup(name);
	} else {
		pNode  = nox_SetValueByName  (pDest , name , pSource->Value , pSource->type);
		pNode->isLiteral = pSource->isLiteral;
	}
	return pNode;
}
/* --------------------------------------------------------------------------- */
PNOXNODE  nox_InsertByNameVC (PNOXNODE pDest , PLVARCHAR name , PNOXNODE pSource )
{
	return nox_InsertByName (pDest , plvc2str(name), pSource );
}
/* --------------------------------------------------------------------------- */
PNOXNODE  nox_CopyValue (PNOXNODE pDest , PUCHAR destName , PNOXNODE pSource , PUCHAR sourceName)
{
	PNOXNODE pRes;
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	PUCHAR pSourceName = pParms->OpDescList->NbrOfParms >= 3 ? sourceName : "";


	pSource = nox_GetNode  (pSource  , pSourceName );
	if (pSource == NULL) return NULL;

	pDest = nox_GetOrCreateNode (pDest, destName);
	if (pDest  == NULL) return NULL;

	if ( pSource->type == OBJECT || pSource->type == ARRAY ) {
		nox_NodeCloneAndReplace (pDest  , pSource);

	} else {
		nox_NodeSet (pDest ,pSource->Value);
		pDest->isLiteral = pSource->isLiteral;
	}

	return pDest ;
}
/* --------------------------------------------------------------------------- */
PNOXNODE  nox_CopyValueVC (PNOXNODE pDest , PLVARCHAR destName , PNOXNODE pSource , PLVARCHAR sourceName)
{
	return nox_CopyValue (pDest , plvc2str(destName) , pSource , plvc2str(sourceName));
}
/* --------------------------------------------------------------------------- */
static void  nox_MergeObj  (PNOXNODE pDest, PNOXNODE pSource, PJWRITE pjWrite, MERGEOPTION merge)
{
	PNOXNODE  p;
	UCHAR tempname[256];
	PNOXNODE pDestNode , pEdt ;
	int ix =0;

	while (pSource) {

		if (pSource->Name && *pSource->Name){
			pDestNode = nox_GetNode  (pDest, pSource->Name);
			if (pDestNode) {
				if (merge == MO_MERGE_REPLACE) {
					nox_NodeDelete (pDestNode);
					nox_InsertByName (pDest , pSource->Name , pSource );
				} else {
					if (pSource->pNodeChildHead && pSource->type == OBJECT) {
						nox_MergeObj  (pDestNode ,  pSource->pNodeChildHead , pjWrite, merge);
					}
				}
			} else {
				nox_InsertByName (pDest , pSource->Name , pSource );
			}
		} else {
			if (pSource->pNodeChildHead ) {
				// PNOXNODE pNewDest = pDest->pNodeChildHead ?  pDest->pNodeChildHead : pDest; // Handle roots !! TODO !!
				PNOXNODE pNewDest = pDest;
				nox_MergeObj  (pNewDest,  pSource->pNodeChildHead , pjWrite, merge);
			}
		}
		pSource = pSource->pNodeSibling;
	}
}
// ---------------------------------------------------------------------------
void  nox_MergeObjects (PNOXNODE pDest, PNOXNODE pSource , MERGEOPTION merge)
{
	PNOXNODE  p;
	UCHAR tempname[256];
	PNOXNODE pDestNode , pEdt ;
	PNOXNODE pSourceNode;
	int ix =0;

	if (pDest ==NULL ||pSource == NULL) return;

	pSourceNode =  pSource->pNodeChildHead;
	while (pSourceNode) {

		pDestNode = nox_GetNode  (pDest, pSourceNode->Name);
		if (pDestNode) {
			if (merge == MO_MERGE_REPLACE) {
				nox_NodeDelete (pDestNode);
				nox_InsertByName (pDest , pSourceNode->Name , pSourceNode );
			} else {
				if (pSourceNode->type == OBJECT) {
					nox_MergeObjects  (pDestNode ,  pSourceNode , merge);
				}
			}
		} else {
			nox_InsertByName (pDest , pSourceNode->Name , pSourceNode );
		}
		pSourceNode = pSourceNode->pNodeSibling;
	}
}
// --------------------------------------------------------------------------- 
void  nox_LoadRecursiveList (PNOXNODE pNode, PNOXITERATOR pIter, BOOL first)
{
	while (pNode) {
		if (pIter->length >= pIter->size) {
			pIter->size += 256;
			pIter->list = realloc (pIter->list , sizeof(PNOXNODE) * pIter->size);
		}
		pIter->list [pIter->length] = pNode;
		pIter->length++;
		nox_LoadRecursiveList (pNode->pNodeChildHead , pIter, FALSE);
		pNode = first ? NULL : pNode->pNodeSibling;
	}
}
// ---------------------------------------------------------------------------
// Delete nodes which are NULL
// --------------------------------------------------------------------------- 
void  nox_NodeSanitize(PNOXNODE pNode)
{
	while (pNode) {
		PNOXNODE pNext = pNode->pNodeSibling;
		if (pNode->Value != NULL && strcmp (pNode->Value , "null") == 0
		||  pNode->Value == NULL && pNode->type == VALUE) {
			nox_NodeDelete(pNode);
		} else {
			nox_NodeSanitize(pNode->pNodeChildHead);
		}
		pNode = pNext;
	}
}
// ---------------------------------------------------------------------------
void nox_Dump(PNOXNODE  pNode)
{
	if (pNode == NULL) {
		return;
	}

	printf("%s\n" , jxMessage) ;
	nox_DumpNodeList(pNode);
	printf("\n") ;
}
// ---------------------------------------------------------------------------
// Detect if XML or json and if has UTF-8 BOM code
// ---------------------------------------------------------------------------
void  detectEncoding(PNOXCOM pJxCom)
{
	PUCHAR p = pJxCom->StreamBuf;

	// Skip bom ?
	if (p [0] == 0xef && p[1] == 0xbb && p[2] == 0xbf) { // utf8 -BOM code 
		p += 3; // Skip bom code;
	}

	// skip blanks 
	for (; *p <= BLANK && *p != '\0'; p++);

	pJxCom->isJson = (*p != LT);
	pJxCom->StreamBuf = p;	
}
// ---------------------------------------------------------------------------
/* Old implementation
PUCHAR detectEncoding(PNOXCOM pJxCom, PUCHAR pIn)
{
	UCHAR  e2aTbl [256];
	UCHAR  buf [128];
	PUCHAR p, outbuf;
	int i;
	BOOL done = FALSE;
	BOOL isXml = FALSE;
	BOOL isAscii = FALSE;

	// need temp version since it is modified
	substr ( buf, pIn , 128);

	if (buf [0] == 0xef && buf[1] == 0xbb && buf [2] == 0xbf) { // utf8
		 InputCcsid = 1208;
		 isAscii = TRUE;
		 p = buf + 3;
		 outbuf = pIn + 3;
	} else {
		 p = buf;
		 outbuf = pIn;
	}

	for (i=0; ! done; i++, p++) {
		switch(*p) {
			case  '['  :
			case  '{'  :
			case  '\"' :
			case  '\'' :
				pJxCom->isJson = TRUE;
				done = TRUE;
				break;

			case  '<' :
				pJxCom->isJson = FALSE;
				isXml = TRUE;
				done = TRUE;
				break;

	 #pragma convert(1252)
			case  '['  :
			case  '{'  :
			case  '\"' :
			case  '\'' :
				pJxCom->isJson = TRUE;
				isAscii = TRUE;
				done = TRUE;
				break;

			case  '<' :
				pJxCom->isJson = FALSE;
				isAscii = TRUE;
				isXml = TRUE;
				done = TRUE;
				break;

	 #pragma convert(0)
			case  '\0' :
				InputCcsid = 0; // Empty string; build from scratch XML
				return;

			default:
				// For other codepages than 277
				if (*p == BRABEG || *p == CurBeg || *p == Quot || *p == Apos
				||  isdigit(*p)
				||  memBeginsWith(p , "true" )
				||  memBeginsWith(p , "false")
				||  memBeginsWith(p , "null" )) {
					 pJxCom->isJson = TRUE;
					 done = TRUE;
					 break;
				}
		}
	}

	// Bump back to rigt after "<" or what made it stop
	p--;
	if (p && pJxCom->isJson) {
		/ *  .... Avoid to use the ccsid from the file - this can be anything ....
		if (InputCcsid == 0 && pJxCom->File && lstat(pJxCom->FileName, &statbuf) == 0) {
			 InputCcsid = statbuf.st_ccsid;
		} else if (isAscii && InputCcsid == 0) {
			 InputCcsid = 1208;
		} .... * /
		// Assume 1208 for any ascii JSON and set with EBCDIC ccsid on the file
		if (isAscii && InputCcsid < 900) {
			 InputCcsid = 1208;
		}
	} else if (p && isXml && isAscii) {
		if ( InputCcsid == 0) {
			// InputCcsid = 1252;  // Default to basic windows ascii
			InputCcsid = 1208;  // Default to UTF-8
		}

		if (*(p+1) == 0x00) { // UNICODE litle endian
			pJxCom->LittleEndian  = TRUE;
			InputCcsid = 1200;
		}
		else if (p > buf && *(p-1) == 0x00) { // UNICODE big endian
			pJxCom->LittleEndian  = FALSE;
			// InputCcsid = 13488;
			InputCcsid = 1200;
		}
		else if (*(p+1) == 0x3f) { // ? in ascii
			#pragma convert(1252)
			p = strchr(p+2 , 0x3f);  // ? in ascii
			if (*p) *p = '\0';

			if (strstr  ( buf ,  "-8859-1")) {  // Short for ISO-8859-1
				InputCcsid = 819;
			}
			else if (strstr  ( buf ,  "-8")) {  // Short for UTF-8
				InputCcsid = 1208;
			}
			else if (strstr  ( buf ,  "-1252")) {  // Short for windows-1252
				InputCcsid = 1252;
			}
			#pragma convert(0)
		}
	} else if (strlen(buf) == 0) {
		InputCcsid = 0; // Empty string; build from scratch XML
	} else {
		nox_SetMessage( "Unsupported /unknown charset or encoding for file %s ", pJxCom->FileName);
		pJxCom->State = XML_EXIT_ERROR;
		return outbuf;
	}

	return outbuf;
}
*/
// ---------------------------------------------------------------------------
static PNOXNODE  SelectParser (PNOXCOM pJxCom)
{
	PNOXNODE pRoot;
	CheckBufSize(pJxCom);
	pJxCom->pNodeRoot = pRoot = NewNode (NULL, NULL, OBJECT);
	pJxCom->pFileBuf = NULL;
	pJxCom->State = XML_FIND_START_TOKEN;
	pJxCom->LineCount = 1;
	pJxCom->pNodeWorkRoot = pJxCom->pNodeRoot;
	pJxCom->Comment = memAlloc(COMMENT_SIZE);
	* pJxCom->Comment = '\0';

	detectEncoding (pJxCom);

	if (pJxCom->isJson) {
		jxError = nox_ParseJson (pJxCom);
	} else {
		jxError = nox_ParseXml (pJxCom);
	}

	// Clean up
	memFree(&pJxCom->Comment);
	memFree(&pJxCom);

	return pRoot;
}
// ---------------------------------------------------------------------------
// This works, however
// it is dangling for clean up since the subnotes are moved to another tree
// ---------------------------------------------------------------------------
void nox_NodeAppendChild(PNOXNODE pRoot, PNOXNODE pNewChild)
{
	if (pRoot == NULL) return;
	if (pNewChild == NULL) return;

	pNewChild->pNodeParent = pRoot;

	if (pRoot->pNodeChildHead == NULL) {
		pNewChild->pNodeParent->pNodeChildHead = pNewChild;
	} else {
		pNewChild->Seq = pNewChild->pNodeParent->pNodeChildTail->Seq + 1; // Increment Sibling number
		pNewChild->pNodeParent->pNodeChildTail->pNodeSibling = pNewChild;
	}
	pNewChild->pNodeParent->pNodeChildTail = pNewChild;
}
// ---------------------------------------------------------------------------
static PNOXNODE previousSibling(PNOXNODE p)
{
	PNOXNODE t;
	if (p->pNodeParent == NULL) return NULL; // I am the root
	t = p->pNodeParent->pNodeChildHead;
	while (t) {
		if (t->pNodeSibling == p) return(t);
		t = t->pNodeSibling;
	}
	return ( NULL);
}

// ---------------------------------------------------------------------------
static PNOXNODE DupNode(PNOXNODE pSource)
{
	PNOXATTR pAttrTemp;
	PNOXNODE  pNode;

	// A copy of null is null
	if (pSource == NULL) return NULL;

	// Dupling a nodex which is a string simply kicks in the parser
	if (pSource->signature != NODESIG) {
		pNode = nox_ParseString((PUCHAR) pSource);
		return pNode;
	}

	pNode = (PNOXNODE) memAlloc (sizeof(*pNode));
	memcpy  (pNode , pSource, sizeof(*pNode));

	pNode->pAttrList  = NULL;
	pNode->pNodeParent = pNode->pNodeChildHead = pNode->pNodeChildTail = pNode->pNodeSibling = NULL;
	pNode->Name  = memStrDup(pSource->Name);
	pNode->Value = memStrDup(pSource->Value);

	for (pAttrTemp = pSource->pAttrList; pAttrTemp ; pAttrTemp = pAttrTemp->pAttrSibling){
		PNOXATTR  pPrev, pAttr = (PNOXATTR) memAlloc (sizeof(*pAttr));
		memset (pAttr , 0, sizeof(*pAttr));
		pAttr->signature  = ATTRSIG;
		pAttr->Name  = memStrDup( pAttrTemp->Name);
		pAttr->Value = memStrDup(pAttrTemp->Value);
		if ( pNode->pAttrList ==NULL) {
			pNode->pAttrList = pAttr;
		} else {
			pPrev->pAttrSibling = pAttr;
		}
		pPrev =pAttr;
	}

	return (pNode);
}
// ---------------------------------------------------------------------------
void nox_NodeAddChildTail( PNOXNODE pRoot, PNOXNODE pChild)
{
	if (pChild == NULL || pRoot == NULL) return;

	pChild->pNodeParent = pRoot;

	if (pChild->pNodeParent->type == ARRAY) {
		pChild->pNodeParent->Count ++;
	}

	if (pChild->pNodeParent->pNodeChildHead == NULL) {
		pChild->pNodeParent->pNodeChildHead = pChild;
		pChild->pNodeParent->pNodeChildTail = pChild;
	} else {
		// TODO !! Why is the tail some times NULL?
		// AND: found the "unlink" error, so may we can remove it now...
		// This "if" can be remove when this bug i found.
		if (pChild->pNodeParent->pNodeChildTail) {
			pChild->Seq = pChild->pNodeParent->pNodeChildTail->Seq + 1; // Increment Sibling number
			pChild->pNodeParent->pNodeChildTail->pNodeSibling = pChild;
		}
		pChild->pNodeParent->pNodeChildTail = pChild;
	}
}
// ---------------------------------------------------------------------------
// unlink a node from the tree and returns it as a new root
// It has no parent nor any siblings. It can only have children
// ---------------------------------------------------------------------------
PNOXNODE nox_NodeUnlink  (PNOXNODE  pNode)
{
	PNOXNODE pNewRoot, pPrevNode, pParent;

	if (pNode == NULL) return NULL;

	pParent = pNode->pNodeParent;

	// if I am a root node, then look no further
	if (pParent == NULL) return pNode;

	pPrevNode  = previousSibling(pNode);
	if (pPrevNode) {
		pPrevNode->pNodeSibling = pNode->pNodeSibling;
	} else {
		pParent->pNodeChildHead = pNode->pNodeSibling;
	}
	if (pParent->pNodeChildTail == pNode) {
		pParent->pNodeChildTail = pPrevNode;
	}

	// json arrays has the "length" counter synconized
	if (pParent->type == ARRAY) {
		pParent->Count --;
	}

	// Now i am alone:
	pNode->pNodeSibling = null;
	pNode->pNodeParent  = null;

	return pNode;
}
// ---------------------------------------------------------------------------
void nox_SwapNodes (PNOXNODE * ppNode1, PNOXNODE * ppNode2)
{
	PNOXNODE pNode1 = *ppNode1  , pNode2 =  * ppNode2;
	PNOXNODE pTemp1, pTemp2, pPrevNode, pParent = NULL;

	if (pNode1 == NULL || pNode2 == NULL) return;


	pParent = pNode1->pNodeParent;
	pPrevNode  = previousSibling(pNode1);
	if (pPrevNode) {
		pPrevNode->pNodeSibling = pNode2;
	} else if (pParent) {
		pParent->pNodeChildHead = pNode2;
	}

	pNode1->pNodeSibling = pNode2->pNodeSibling;
	pNode2->pNodeSibling = pNode1;

	if (pParent && pParent->pNodeChildTail == pNode2) {
		pParent->pNodeChildTail = pNode1;
	}
	*ppNode1 = pNode2;
	*ppNode2 = pNode1;
}
// ---------------------------------------------------------------------------
PNOXNODE nox_NodeMoveInto (PNOXNODE  pDest, PUCHAR name , PNOXNODE pSource)
{

	PNOXNODE  pTempNode;

	if (pDest == pSource
	||  pDest == NULL) {
		return pDest;
	}

	// If no destination given, then it is actually a replace og the
	// destimnation node - with respect to the memmory locaitons
	if (*name == '\0') {
		nox_NodeMoveAndReplace (pDest , pSource);
		return pDest;
	}

	pSource = nox_NodeUnlink(pSource); // Now I am my own root
	nox_NodeRename(pSource , name);

	pTempNode  = nox_GetNode  (pDest, name );
	if (pTempNode == NULL) {
	// if (pSource->type == VALUE) {
	//    nox_NodeSet (pDest , pSource->Value);
	//    nox_NodeDelete (pSource);
	//    return pDest;
	// }
		nox_NodeAddChildTail (pDest, pSource);

		// Since we have a name - we must be an object
		// required if we were a value i.e. produce by
		// locateOrCreate / getorCreate or we were a value by ie. setStr
		if (pDest->type != ARRAY ) {
			pDest->type = OBJECT;
		}
		freeNodeValue(pDest);

	} else {
		// replace, by adding a new with same name and the remove the original. Will keep the same position
		nox_NodeAddSiblingAfter(pTempNode, pSource);
		nox_NodeDelete (pTempNode);
	}

	return pSource;

}
// ---------------------------------------------------------------------------
PNOXNODE nox_NodeMoveIntoVC (PNOXNODE  pDest, PLVARCHAR  name , PNOXNODE pSource)
{
	return nox_NodeMoveInto (pDest, plvc2str (name) ,  pSource);
}
// ---------------------------------------------------------------------------
void nox_NodeMoveAndReplace (PNOXNODE  pDest, PNOXNODE pSource)
{
	if (pDest == pSource
	||  pDest == NULL) {
		return;
	}

	pSource = nox_NodeUnlink(pSource);      // Now I am my own root
	nox_NodeRename(pSource , pDest->Name);  // I need the same name of the node i gonna replace

	// replace, by adding a new with same name and the remove the original. Will keep the same position
	nox_NodeAddSiblingAfter(pDest, pSource);
	nox_NodeDelete (pDest);
}
// ---------------------------------------------------------------------------
void nox_NodeAddChildHead( PNOXNODE pRoot, PNOXNODE pChild)
{
	pChild->pNodeParent = pRoot;

	if (pChild->pNodeParent->type == ARRAY) {
		pChild->pNodeParent->Count ++;
	}

	if (pChild->pNodeParent->pNodeChildHead == NULL) {
		pChild->pNodeParent->pNodeChildHead = pChild;
		pChild->pNodeParent->pNodeChildTail = pChild;
	} else {
		PNOXNODE pTemp;
		pTemp = pChild->pNodeParent->pNodeChildHead;
		pChild->pNodeParent->pNodeChildHead = pChild;
		pChild->pNodeSibling = pTemp;
//    pChild->Seq = pChild->pNodeParent->pNodeChildTail->Seq + 1; // Increment Sibling number to do ... renumber
	}
}
// ---------------------------------------------------------------------------
void nox_NodeAddSiblingBefore( PNOXNODE pRef, PNOXNODE pSibling)
{
	PNOXNODE pPrev = previousSibling(pRef);

	if (pPrev == NULL) {
		nox_NodeAddChildHead( pRef->pNodeParent, pSibling);
		return;
	}
	pSibling->pNodeParent  = pRef->pNodeParent;
	pSibling->pNodeSibling = pRef;
	pPrev->pNodeSibling    = pSibling;
}
// ---------------------------------------------------------------------------
void nox_NodeAddSiblingAfter( PNOXNODE pRef, PNOXNODE pSibling)
{
	if (pRef->pNodeSibling == NULL) {
		nox_NodeAddChildTail ( pRef->pNodeParent, pSibling);
		return;
	}
	pSibling->pNodeParent  = pRef->pNodeParent;
	pSibling->pNodeSibling = pRef->pNodeSibling;
	pRef->pNodeSibling     = pSibling;
}
// ---------------------------------------------------------------------------
void AddNode(PNOXNODE pDest, PNOXNODE pSource, REFLOC refloc)
{
	if (pDest   == NULL) return;

	switch ( refloc) {
		case RL_LAST_CHILD:
			nox_NodeAddChildTail (pDest, pSource);
			break;
		case RL_FIRST_CHILD:
			nox_NodeAddChildHead (pDest, pSource);
			break;
		case RL_BEFORE_SIBLING:
			nox_NodeAddSiblingBefore(pDest, pSource);
			break;
		case RL_AFTER_SIBLING:
			nox_NodeAddSiblingAfter(pDest, pSource);
			break;
	}
}
// ---------------------------------------------------------------------------
PNOXNODE nox_NodeClone  (PNOXNODE pSource)
{
	PNOXNODE  pNewNode, pNext;

	if (pSource == NULL) return NULL;

	pNewNode = DupNode(pSource);

	pNext = pSource->pNodeChildHead;
	while (pNext) {
		PNOXNODE  pNewChild = nox_NodeClone (pNext);
		nox_NodeAddChildTail (pNewNode , pNewChild);
		pNext=pNext->pNodeSibling;
	}
	return pNewNode;
}
// ---------------------------------------------------------------------------
PNOXNODE nox_NodeCopy (PNOXNODE pDest, PNOXNODE pSource, REFLOC refloc)
{
	PNOXNODE  pNewNode, pNode;

	if (pDest   == NULL) return;
	if (pSource == NULL) return;

	pNewNode = nox_NodeClone  (pSource);
	AddNode(pDest, pNewNode, refloc);
	return pNewNode;

}
// ---------------------------------------------------------------------------
PNOXNODE NewNode  (PUCHAR Name , PUCHAR Value, NODETYPE type)
{
	PNOXNODE  pNode;

	pNode = (PNOXNODE) memAlloc (sizeof(*pNode));
	memset (pNode , 0, sizeof(*pNode));
	pNode->signature  = NODESIG;

	// TODO !! Need use only the type in the future
	if (type == LITERAL) {
		pNode->type      = VALUE;
		pNode->isLiteral = TRUE;
	} else {
		pNode->type = type;
		pNode->isLiteral = FALSE;
	}
	pNode->Name   = memStrDup(Name);
	pNode->Value  = memStrDup(Value);
	return pNode;
}
// ---------------------------------------------------------------------------
PNOXNODE nox_NodeAdd (PNOXNODE pDest, REFLOC refloc, PUCHAR Name , PUCHAR Value, NODETYPE type)
{
    PNOXNODE  pNewNode  = NewNode  (Name , Value, type);
	AddNode(pDest, pNewNode, refloc);
	return pNewNode;
}
PNOXNODE nox_NodeAddVC (PNOXNODE pDest, REFLOC refloc, PLVARCHAR Name , PLVARCHAR Value, NODETYPE typeP)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	NODETYPE type =  pParms->OpDescList->NbrOfParms >= 5 ? typeP : VALUE;
	return  nox_NodeAdd  (pDest, refloc , plvc2str(Name) , plvc2str(Value), type);
}
// ---------------------------------------------------------------------------
PNOXNODE nox_NewObject ()
{
	PNOXNODE  pNode = (PNOXNODE) memAllocClear (sizeof(NOXNODE));
	pNode->signature  = NODESIG;
	pNode->type       = OBJECT;
	return pNode;
} 
// ---------------------------------------------------------------------------
PNOXNODE nox_NewArray ()
{
	PNOXNODE  pNode = (PNOXNODE) memAllocClear (sizeof(NOXNODE));
	pNode->signature  = NODESIG;
	pNode->type       = ARRAY;
	return pNode;
}
// ---------------------------------------------------------------------------
void nox_NodeSet (PNOXNODE pNode , PUCHAR Value)
{
	if (pNode == NULL) return;

	// Remake me as a value node...
	if (pNode->type != VALUE ) {
		nox_FreeChildren (pNode);
		pNode->type = VALUE;
	}
	freeNodeValue(pNode);

	if (Value) {
		pNode->Value = memStrDup(Value);
	}
}
// ---------------------------------------------------------------------------
void nox_NodeSetVC (PNOXNODE pNode , PLVARCHAR Value)
{
	nox_NodeSet (pNode , plvc2str(Value));
}
// ---------------------------------------------------------------------------
void nox_NodeSetAsPointer (PNOXNODE pNode , PUCHAR Value)
{
	if (pNode == NULL) return;

	// Remake me as a pointer node node...
	freeNodeValue(pNode);     // If i was a value - - drop it
	nox_FreeChildren (pNode);  // Ensure we are only a value
	pNode->Value     = Value;
	pNode->type      = POINTER_VALUE;
	pNode->isLiteral = true; // no escaping and no conversion
}
// ---------------------------------------------------------------------------
void nox_NodeDelete(PNOXNODE pNode)
{
	PNOXNODE  pTemp;

	if (pNode == NULL) return;

	nox_NodeUnlink (pNode);
	nox_FreeChildren (pNode);
	nox_NodeFree(pNode);
}
void nox_Delete(PNOXNODE * pNode)
{
	nox_NodeDelete(* pNode);
	*pNode = NULL;
}
// ---------------------------------------------------------------------------
// delim was originally only 5.
// ---------------------------------------------------------------------------
/*
void nox_SetDelimiters(PNOXDELIM pDelim)
{
	PUCHAR delim = (PUCHAR) pDelim;

	// delim was originally only 5.
	memcpy(delimiters , pDelim , 5);
	Slash       = delim [0];
	BackSlash   = delim [1];
	MASTERSPACE = delim [2];
	BRABEG      = delim [3];
	BRAEND      = delim [4];
}
*/ 
// ---------------------------------------------------------------------------
// New wrapper  - Missing in old "SetDelimiters" - now the string is NULL
// terminated to we can just build more on as we go
// ---------------------------------------------------------------------------
/* 
void nox_SetDelimiters2(PNOXDELIM pDelim)
{
	int i;
	PUCHAR p = (PUCHAR) pDelim;
	for (i=0; i< sizeof(delimiters) && *p   ; i++,p++) {
		 UCHAR c = delimiters [i] = *p;
		 switch (i) {
				case 0 : Slash       = c; break;
				case 1 : BackSlash   = c; break;
				case 2 : MASTERSPACE = c; break;
				case 3 : BRABEG      = c; break;
				case 4 : BRAEND      = c; break;
				case 5 : Blank       = c; break;
				case 6 : Dot         = c; break;
				case 7 : CurBeg      = c; break;
				case 8 : CurEnd      = c; break;
				case 9 : Apos        = c; break;
				case 10: Quot        = c; break;
		 }
	}
}
*/
// ---------------------------------------------------------------------------
/*
PNOXDELIM nox_GetDelimiters(void)
{
	return   (PNOXDELIM)   &delimiters;
}
*/
// ---------------------------------------------------------------------------
PNOXNODE nox_ParseString(PUCHAR Buf)
{
	PNOXNODE pRoot;
	PNOXCOM  pJxCom;

	#ifdef MEMDEBUG
		UCHAR  tempStr[100];
		substr(tempStr , Buf , 100);
	#endif

	// Asume OK
	jxError = false;

	if (Buf == NULL || *Buf == '\0' ) {
		return NULL;
	}
	// Is it already a object graph, then return it
	if (*Buf == NODESIG) {
		return (PNOXNODE) Buf;
	}

	jxMessage[0] = '\0';

	pJxCom = memAllocClear (sizeof(NOXCOM));

	pJxCom->StreamBuf =  Buf;
	pRoot = SelectParser (pJxCom);

	// DEBUGGER TODO !!!
	#ifdef MEMDEBUG
		printf("\n\nParse String: %p - %-90.90s\n " , pRoot  , tempStr);
		memStat();
	#endif

	return (pRoot);
}
// ---------------------------------------------------------------------------
PNOXNODE nox_ParseStringVC(PLVARCHAR buf)
{
	return nox_ParseString ( plvc2str (buf));
}
// ---------------------------------------------------------------------------
PNOXNODE nox_ParseFile(PUCHAR FileName)
{

	PUCHAR  streamBuf;
	PNOXNODE pRoot;
	PUCHAR  pFirstChar;
	LONG    fileSize;
	LONG    len ;
	FILE  * f;
	struct  stat statbuf;

	jxMessage[0] = '\0';

	f  = fopen(strTrim(FileName), "rb");
	if (f  == NULL) {
		nox_SetMessage( "File %s not open: %s", FileName, strerror(errno));
		jxError = true;
		return NULL;
	}

	// Get the default input ccsid from the file system ( It might be wrong because it is set to default)
	fstat(fileno(f), &statbuf);

	// Locate end to find the size of the file
	fseek( f , 0L, SEEK_END);
	fileSize = ftell( f );
	fseek( f , 0L, SEEK_SET);

	// read it all
	streamBuf = memAlloc (fileSize+1);
	len = fread(streamBuf, 1 , fileSize  , f );
	fclose(f);

	if (len != fileSize) {
		nox_SetMessage( "File %s was not read", FileName);
		jxError = true;
		memFree (&streamBuf);
		return NULL;
	}

	// make it a string
	streamBuf[len] = '\0';
	pRoot = nox_ParseString(streamBuf);
	memFree (&streamBuf);

	return (pRoot);
}
/* --------------------------------------------------------------------------- *\
	 Following routines are for manipulatin with the Xml-Tree inscance
\* --------------------------------------------------------------------------- */
PNOXNODE nox_GetNodeParent(PNOXNODE pNode)
{
	if (pNode == NULL) return NULL;
	return(pNode->pNodeParent);
}
/* ---------------------------------------------------------------------------
	 go to the top to find the root
	 --------------------------------------------------------------------------- */
PNOXNODE  nox_GetRoot (PNOXNODE pNode)
{
	int i = 0;
	if (pNode == NULL) return NULL;
	for(;i<1000;i++) { // avoid loop if self reference - just return any top level
		if (pNode->signature != NODESIG) return NULL;
		if (pNode->pNodeParent == NULL)  break;
		pNode = pNode->pNodeParent;
	}
	return ( pNode);
}
/* --------------------------------------------------------------------------- */
#pragma convert(1252)
PNOXNODE nox_lookupByXpath (PNOXNODE pRootNode, PUCHAR * ppName)
{
	PUCHAR  Name = * ppName;
	PUCHAR  pEnd = findchr(Name , "=<>" , 3);
	PUCHAR  compVal;
	UCHAR   keyName[256];
	int     nameLen, compLen;
	int     comp =0;

	switch(*pEnd) {
		case '=' :  comp = 0 ; break;
		case '<' :  comp = -1; break;
		case '>' :  comp = 1 ; break;
	}

	compVal = pEnd +1;
	for(;*(pEnd-1) == ' '; pEnd--);       // quick trim
	nameLen = pEnd  - Name;
	substr(keyName , Name , nameLen);

	for(;*compVal == ' '; compVal++); // Skip blanks
	pEnd = strchr (compVal , BRAEND);
	if (pEnd == NULL) return NULL;
	compLen = pEnd - compVal;
	*ppName =  *ppName + (pEnd - Name);

	if (*keyName == MASTERSPACE) {

		// Find by atribute value
		PNOXNODE pNodeTemp = pRootNode;
		substr(keyName , Name+1 , nameLen-1);

		while (pNodeTemp && pNodeTemp->signature == NODESIG) {
			PNOXATTR pAtr = nox_AttributeLookup  (pNodeTemp, keyName);
			if (pAtr && pAtr->Value) {
				// Does the value match
				if (memicmp(compVal , pAtr->Value, compLen) == comp
				&&  pAtr->Value[compLen] == '\0') {
					return pNodeTemp;
				}
			}
			pNodeTemp=pNodeTemp->pNodeSibling;
		}

	} else {
		// Find by value
		PNOXNODE pNodeTemp = pRootNode == NULL? NULL:pRootNode->pNodeChildHead;
		while (pNodeTemp && pNodeTemp->signature == NODESIG) {
			PNOXNODE pNode = nox_GetNode  (pNodeTemp, keyName);
			if (pNode && pNode->Value) {

				// Does the value match
				if (memicmp(compVal , pNode->Value, compLen) == comp
				&&  pNode->Value[compLen] == '\0') {
					return pNodeTemp;
				}
			}
			pNodeTemp=pNodeTemp->pNodeSibling;
		}
	}
	return NULL;

}
#pragma convert(0)
/* --------------------------------------------------------------------------- */
PUCHAR nox_NodeName (PNOXNODE pNode,BOOL SkipNameSpace)
{
	PUCHAR p;

	if (pNode == NULL ) return NULL;
	p = pNode->Name;
	if (p == NULL) return NULL;

	if (SkipNameSpace) {
		PUCHAR temp;
		temp  = strchr(p , ':');
		if (temp) {
			return  temp + 1 ; // Just after the :
		}
	}
	return p;
}
/* --------------------------------------------------------------------------- */
nox_NodeNameVC (PLVARCHAR name, PNOXNODE pNode,BOOL SkipNameSpace)
{
	str2plvc(name , nox_NodeName (pNode,SkipNameSpace));
}

/* --------------------------------------------------------------------------- */
PNOXNODE  nox_FindNodeAtIndex(PNOXNODE pNode , PUCHAR Key , int index , BOOL SkipNameSpace)
{
	int i =0;
	PUCHAR CurName;

	while (pNode) {

		CurName = nox_NodeName (pNode, SkipNameSpace);
		if (CurName && stricmp(Key , CurName) == 0) {
			if (index == i) return (pNode); // Found :)
			i++;
		}
		pNode=pNode->pNodeSibling;
	}
	return NULL;
}
/* --------------------------------------------------------------------------- */
/**********'' OLD
void nox_GetKeyFromName (PUCHAR tempKey , PBOOL SkipNameSpace , PUCHAR KeyName , PUCHAR SearchName)
{
	 int l=0;

	 for (;  *KeyName != Slash && KeyName >= SearchName ; KeyName--, l++);
	 KeyName++;
	 *SkipNameSpace = (* KeyName  == '*');
	 if (*SkipNameSpace) {
			KeyName+= 2; // Skip the *:
			l-= 2; // Skip the *:
	 } else {
			*SkipNameSpace = (memchr(KeyName , ':' , l) == NULL);
	 }
	 substr(tempKey , KeyName, l);
}
*/
void nox_GetKeyFromName (PUCHAR tempKey , PBOOL SkipNameSpace , PUCHAR prevKey)
{
	*SkipNameSpace = (strchr(prevKey, COLON) == NULL);
	strcpy (tempKey , prevKey);
}
/* ---------------------------------------------------------------------------
	 Find node by name, by parsing a name string and traverse the tree
	 The Node can be the casted to the xml root
	 --------------------------------------------------------------------------- */
static BOOL isNextDelimiter(UCHAR c)
{
	return c == BACKSLASH || c  == SLASH || c == DOT;
}
/* ---------------------------------------------------------------------------
	 name contains [UBOUND]
	 --------------------------------------------------------------------------- */
#pragma convert(1252)
BOOL nox_isUbound (PUCHAR name)
{
	return (memicmp(name  , "[UBOUND]" , 8) == 0);
}
#pragma convert(0)
/* ---------------------------------------------------------------------------
	 Set the counter
	 --------------------------------------------------------------------------- */
PNOXNODE nox_CountChildren(PNOXNODE pNode)
{
	PNOXNODE p;

	// Arrays are already counted
	if (pNode->type == ARRAY) {
		return pNode;   // Already counted
	}

	// Now count each child
	pNode->Count = 0;
	p=pNode->pNodeChildHead;
	while (p) {
		pNode->Count ++;
		p=p->pNodeSibling;
	}
}
/* ---------------------------------------------------------------------------
	 Return the node ; With counter flag or not
	 --------------------------------------------------------------------------- */
static PNOXNODE nox_ReturnNode (PNOXNODE pNode, BOOL asCounter)
{
	if (pNode) pNode->doCount = asCounter;
	nox_traceNode("GetNode return", pNode);
	return pNode;
}
/* ---------------------------------------------------------------------------
	 Return the node with name match
	 --------------------------------------------------------------------------- */
static PNOXNODE nox_lookUpSiblingByName(PNOXNODE pNode , PUCHAR keyName)
{
	PUCHAR curName;
	BOOL   SkipNameSpace;

	SkipNameSpace = (strchr(keyName , COLON) == NULL);

	// Locate name match
	while (pNode) {
		curName = nox_NodeName (pNode,SkipNameSpace);

		if (curName == NULL ) {
			pNode=pNode->pNodeSibling;
			continue;
		}

		// Name Match ? Go one step deeper
		if (stricmp(keyName, curName) == 0) {  // Found
			return pNode;  // This level found, setup for itterarion
		}
		// No ! try next
		pNode=pNode->pNodeSibling;
	}

	return NULL;
}
/* ---------------------------------------------------------------------------
	 count nodes with same name
	 --------------------------------------------------------------------------- */
static PNOXNODE nox_CalculateUbound(PNOXNODE pNode , PUCHAR key , BOOL SkipNameSpace)
{

	PNOXNODE pNodeTemp = pNode;

	// JSON has an array type
	if (pNode == NULL) return NULL;

	// JSON can count faster:
	if (pNode->type == ARRAY || pNode->type == OBJECT) {
		nox_CountChildren(pNode);
		return nox_ReturnNode (pNode, true ); // Done !! return the current node with the counter updated
	}

	pNode->Count = 0;

	while (pNodeTemp) {
		// Skip namespace ? - when namespace is a *:
		PUCHAR CurName = nox_NodeName (pNodeTemp, SkipNameSpace);
		if (CurName && stricmp(key , CurName) == 0) {
			pNode->Count ++;
		}
		pNodeTemp=pNodeTemp->pNodeSibling;
	}
	return nox_ReturnNode (pNode, true ); // Done !! return the current node with the counter updated
}
/* ---------------------------------------------------------------------------
	 Use index subscription to locate the node
	 --------------------------------------------------------------------------- */
static PNOXNODE nox_lookupByIndex(PNOXNODE pNode , PUCHAR tempKey , int Index, BOOL SkipNameSpace)
{
	if (pNode == NULL) return NULL;

	// JSON only can do fast array and object lookup
	if (pNode->type == ARRAY || pNode->type == OBJECT) {
		int i;
		pNode = pNode->pNodeChildHead;
		for (i=0 ; i < Index ; i++) {
			if (pNode == NULL) return NULL;
			pNode=pNode->pNodeSibling;
		}
		return pNode;
	} else if (pNode->type == VALUE) {
		return NULL; // Indexing values makes no sense - This is only for JSON; JSON sets the pNode->type
	} else {
		return nox_FindNodeAtIndex(pNode , tempKey , Index , SkipNameSpace);
	}
}
/* ---------------------------------------------------------------------------
	 Get the numeric portion between two memory locations
	 This has to be conservative: if not every characters
	 is numeric we return -1 for not fully numeric
	 --------------------------------------------------------------------------- */
#pragma convert(1252)
int nox_getNumericKey (PUCHAR pStr, PUCHAR pEnd)
{
	int index = 0;

	while(pStr < pEnd ) {
		if (*pStr  >= '0' && *pStr  <= '9') {
			index = 10 * index + (*pStr - '0');
		} else {    // Not numeric => Stop the loop
			return -1;
		}
		pStr++;
	}
	return index;
}
#pragma convert(0)
/* ---------------------------------------------------------------------------
	 Find node by name, by parsing a name string and traverse the tree
	 --------------------------------------------------------------------------- */
PNOXNODE nox_GetNode  (PNOXNODE pNode, PUCHAR Name)
{
	PUCHAR  pStart   = Name;
	PNOXNODE pNodeTemp = NULL;
	BOOL    Found = FALSE;
	int     Len=0, l , i, StartIx;
	LONG    index;
	PUCHAR  p, pName, pEnd = "";
	PNOXNODE refNode;
	UCHAR   refName [256];

	if (pNode == NULL
	||  pNode->signature != NODESIG) {
		return NULL;
	}

	// You can change the "debug" in a debugsession to dump the source node
	nox_traceNode ( "GetNode " , pNode);

	// Only "/" in the name ... that is my self
	if (Name == NULL || *Name == '\0'  ) {
		return nox_ReturnNode (pNode, false); // Done !! Just want the root
	}
	// Ubound on the root node
	if (nox_isUbound(Name)) {
		nox_CountChildren(pNode);
		return nox_ReturnNode (pNode, true ); // Done !! return the current node with the counter updated
	}

	if (isNextDelimiter(*Name)) {
		pNode = nox_GetRoot(pNode);
		Name++; // Skip root
		// dont do this - list will break since it will use the firs child on the list .. see later:
		// if (*Name == '\0') return nox_ReturnNode (pNode, false);; // Done
	}


	// By default we are searching for Nodeents in objects hench Start with the
	// First child and match; if OK the take the next level etc
	// However - the level can be restored to the object for ie [UBOUND] or index lookup like: [123]
	if (*Name != BRABEG) {
		pNode = pNode->pNodeChildHead;
		// .. but we can do it here: baically: "/" gives the first child to the root
		if (*Name == '\0') return nox_ReturnNode (pNode, false);; // Done
	}

	// Setup for iteration
	*refName = '\0';
	refNode = pNode;
	pName = Name;

	for (;;) {

		// No node or dead node
		if (pNode == NULL
		||  pNode->signature != NODESIG) {
			return NULL;
		}

		// Find delimiter, find the end of this token
		if (*pEnd == BRABEG) {
			pEnd = strchr ( pName , BRAEND);
		} else {
			pEnd = findchr(pName , delimiters , sizeof(DELIMITERS)-1); // Not the zerotermination included
		}

		// No Bytes remaining => End of name = rest of string
		if ( pEnd == NULL ) {
			pEnd = pName + strlen(pName);
		}

		// Break at empty arrays: []  otherwise the "set value will find the array root !!
		// Empty arrays does not exists but is rather an indications of a new array element has to be appended
		else if (pEnd[0] == BRABEG && pEnd[1] == BRAEND) {
			return NULL;
		}

		Len = pEnd - pName;

		// Check for anonymous object and array in the root  TODO this need to be allowed
		if (*pName == BRABEG && Len == 0) {
			pName ++;
			continue;
		}

		// Check for special names: Subscriptions and Ubound like yy/xx[UBOUND]
		// Note: This uses the refrecene name "refName" which is the last "real name" from the parser
		if ( pName > pStart && *(pName-1)  == BRABEG) {
			UCHAR  tempKey [256];
			BOOL   SkipNameSpace;
			nox_GetKeyFromName (tempKey , &SkipNameSpace , refName);

			#pragma convert(1252)
			if (memicmp (pName , UBOUND , 6) == 0) {
				return nox_CalculateUbound(refNode, tempKey, SkipNameSpace);
			}
			#pragma convert(0)

			// .. If the name is numeric, it is a subscription
			index = nox_getNumericKey (pName , pEnd);

			// When a subscription is found, then locate the occurens
			if (index >= 0) {
				pNode = nox_lookupByIndex(refNode , tempKey, index, SkipNameSpace);
			} else {
				// X-path Nodeent search:
				pNode = nox_lookupByXpath(refNode , &pName);
				pEnd = pName +1;
			}
			if (pNode == NULL) return NULL;

		} else {
			// "Normal" nodes with "normal" names. Store the name for furthere references "refName"
			substr(refName, pName, Len);
			pNode = nox_lookUpSiblingByName(pNode , refName);
		}

		// Current node will be our reference node for subsequent iterations
		refNode = pNode;

		// Skip trailing "]" and blanks
		for (; *pEnd == BRAEND || *pEnd == BLANK ; pEnd++);    // the ']'

		// This level found. Iterate on next name
		if (*pEnd > '\0') { // Otherwise past end of string
			if (*pEnd != BRABEG) {
				// Found but empty or dead
				if (pNode == NULL
				||  pNode->signature != NODESIG) {
					return NULL;
				}

				pNode = pNode->pNodeChildHead;
			}
			pName = pEnd +1 ; // Skip the '.' or '/' and set up next iteration

		} else {
			return nox_ReturnNode (pNode, false ); // Done !! return the current node with the counter updated
		}
	}
}
/* ---------------------------------------------------------------------------
	 Find node by name, by parsing a name string and traverse the tree
	 --------------------------------------------------------------------------- */
PNOXNODE nox_GetNodeVC  (PNOXNODE pNode, PLVARCHAR pName)
{
	return nox_GetNode (pNode , plvc2str(pName));
}
/* ------------------------------------------------------------- */
LGL nox_Has  (PNOXNODE pNode, PUCHAR Name)
{
	PNOXNODE p = nox_GetNode  (pNode, Name);
	if (p == NULL) return OFF;
	if (p->type == VALUE) {
		if (p->Value == NULL) return OFF;
		if (p->isLiteral && memBeginsWith(p->Value, "null")) return OFF;
	}
	return (ON );
}
LGL nox_HasVC  (PNOXNODE pNode, PLVARCHAR  pName)
{
	return nox_Has  (pNode, plvc2str(pName));
}
/* ------------------------------------------------------------- */
LGL nox_IsTrue  (PNOXNODE pNode, PUCHAR Name)
{
	PNOXNODE p = nox_GetNode  (pNode, Name);
	if (p == NULL) return OFF;
	if (p->type == VALUE) {
		if (p->Value == NULL)  return OFF;
		if (p->Value[0] == 0 ) return OFF;
		if (p->Value[0] == '0' && p->Value[1] == 0 )  return OFF;
		if (p->isLiteral && memBeginsWith(p->Value, "false")) return OFF;
	}
	return (ON );
}
LGL nox_IsTrueVC  (PNOXNODE pNode, PLVARCHAR  pName)
{
	return nox_IsTrue  (pNode, plvc2str(pName));
}
/* ------------------------------------------------------------- */
LGL nox_IsNull  (PNOXNODE pNode, PUCHAR Name)
{
	PNOXNODE p = nox_GetNode  (pNode, Name);
	if (p == NULL) return ON;
	if (p->type == VALUE) {
		if (p->Value == NULL)  return ON;
	}
	return (OFF);
}
LGL nox_IsNullVC  (PNOXNODE pNode, PLVARCHAR  pName)
{
	return nox_IsNull  (pNode, plvc2str(pName));
}
/* ------------------------------------------------------------- */
LGL nox_isNode  (PNOXNODE pNode)
{
	return (
		   (pNode == NULL)
		|| (pNode->signature != NODESIG)
		? OFF : ON
	);
}
/* -------------------------------------------------------------
	 Find attribute to a Nodeent; traverse the chain
	 ------------------------------------------------------------- */
PNOXATTR nox_AttributeLookup   (PNOXNODE pNode, PUCHAR Name)
{
	PNOXATTR pAttr;
	SHORT    NameLen;
	if (pNode == NULL) {
		return NULL;
	}

	NameLen = strlen (Name);
	for (; NameLen > 1 && Name[NameLen-1] <= ' '; NameLen--); // Trim Left lenght

	pAttr = pNode->pAttrList;

	while (pAttr) {
		if (memicmp (Name ,pAttr->Name , NameLen ) == 0
		&&  pAttr->Name[NameLen] == '\0') {
			return (pAttr);
		}
		pAttr = pAttr->pAttrSibling;
	}
	return (NULL);
}
PNOXATTR nox_AttributeLookupVC   (PNOXNODE pNode, PLVARCHAR Name)
{
	return nox_AttributeLookup   (pNode, plvc2str(Name));
}
/* -------------------------------------------------------------
	 returns the value of the node
	 ------------------------------------------------------------- */
PNOXNODE nox_GetNodeByName  (PNOXNODE  pNode, PUCHAR Ctlstr , ... )
{
	va_list arg_ptr;
	UCHAR Name[1024];
	SHORT l;
	PNOXNODE pNodeOut;

	// Build a temp string with the formated data 
	va_start(arg_ptr, Ctlstr);
	l = vsprintf(Name, Ctlstr, arg_ptr);
	va_end(arg_ptr);

	pNodeOut = nox_GetNode(pNode, Name);
	return (pNodeOut);
}
/* -------------------------------------------------------------
	 returns the value of the node
	 ------------------------------------------------------------- */
PUCHAR  nox_GetNodeValuePtr  (PNOXNODE pNode , PUCHAR DefaultValue)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	if (pNode == NULL
	||  pNode->Value == NULL){
		return (pParms->OpDescList->NbrOfParms >= 2 ? DefaultValue : NULL);
	} else {
		return (pNode->Value);
	}
}
/* -------------------------------------------------------------
	 returns the value of the node
	 ------------------------------------------------------------- */
PUCHAR  nox_GetNodeAttrValuePtr  (PNOXNODE pNode , PUCHAR AttrName, PUCHAR DefaultValue)
{
	PNOXATTR pAttr;

	pAttr = nox_AttributeLookup   (pNode, AttrName);
	if (pAttr == NULL
	||  pAttr->Value == NULL) {
		return ( DefaultValue);
	} else {
		return pAttr->Value;
	}
}
/* -------------------------------------------------------------
	 Add a attribute to the end of the attribute list for an Nodeent
	 ------------------------------------------------------------- */
PNOXATTR nox_NodeAddAttributeValue  (PNOXNODE pNode , PUCHAR AttrName, PUCHAR Value)
{

	PNOXATTR pAttrTemp;
	PNOXATTR * ppEnd = &pNode->pAttrList;

	for (pAttrTemp = pNode->pAttrList; pAttrTemp ; pAttrTemp = pAttrTemp->pAttrSibling){
		ppEnd = &pAttrTemp->pAttrSibling;
	}

	pAttrTemp =  memAlloc (sizeof(*pAttrTemp));
	memset (pAttrTemp , 0, sizeof(*pAttrTemp));
	pAttrTemp->signature  = ATTRSIG;
	pAttrTemp->Name =  memStrDup(AttrName);
	pAttrTemp->Value = memStrDup(Value);
	*ppEnd = pAttrTemp;
	return pAttrTemp;
}
/* -------------------------------------------------------------
	 Update or add an attribue
	 ------------------------------------------------------------- */
VOID nox_SetNodeAttrValue  (PNOXNODE pNode , PUCHAR AttrName, PUCHAR Value)
{
	PNOXATTR pAttr;

	pAttr = nox_AttributeLookup   (pNode, AttrName);
	if (pAttr == NULL) {
		nox_NodeAddAttributeValue( pNode , AttrName, Value);
		return;
	} else {
		memFree(&pAttr->Value);
		pAttr->Value = memStrDup(Value);
		return;
	}
}
VOID nox_SetNodeAttrValueVC  (PNOXNODE pNode , PLVARCHAR AttrName, PLVARCHAR Value)
{
	nox_SetNodeAttrValue  (pNode , plvc2str(AttrName) , plvc2str(Value));
}
/* ---------------------------------------------------------------------------
	 Find node by path, by parsing a name string and traverse the tree
	 It can be relative by diging a Nodeent. 
	 --------------------------------------------------------------------------- */
PUCHAR nox_GetValuePtr (PNOXNODE pNodeRoot, PUCHAR Name, PUCHAR Default)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	// from "C" return null in number of parms
	PUCHAR  dft =  (pParms->OpDescList == NULL
				||  pParms->OpDescList->NbrOfParms == 0
				||  pParms->OpDescList->NbrOfParms >= 3) ? Default : "";

	PUCHAR    pNodeKey, pAtrKey;
	PNOXATTR  pAtr;
	PNOXNODE   pNode;
	static UCHAR temp [10];

	if (pNodeRoot == NULL) {
		return dft;
	}

	pAtrKey = strchr(Name, MASTERSPACE);

	if (pAtrKey) {
		PUCHAR pExp = strchr(Name, BRABEG);
		if  (pExp == null || pAtrKey  < pExp) {
			*pAtrKey = '\0'; // Terminate the Nodeent
			pAtrKey ++;     // atribute is the next
		}
	}

	pNode = nox_GetNode  (pNodeRoot , Name);
	if (pNode == NULL) return dft;

	if (pAtrKey) {
		pAtr =  nox_AttributeLookup   (pNode, pAtrKey);
		if (pAtr == NULL)        return dft;
		if (pAtr->Value == NULL) return dft;
		return pAtr->Value;
	} else if (pNode->doCount) {
		sprintf(temp , "%ld" , pNode->Count);
		return (temp);
	} else {
		if ( pNode->Value == NULL && dft != NULL) return dft;  // Note - if value is a proc ptr - Value compare to NULL
		return pNode->Value;
	}
}
/* --------------------------------------------------------------------------- */
static void nox_joinArray2vc (PLVARCHAR pRes , PNOXNODE pNode)
{
	PNOXNODE p = pNode->pNodeChildHead;
	int len;
	pRes->Length = 0;
	while (p) {
		PUCHAR v = p->Value;
		if (v  && *v) {
			plvccatstr(pRes , v);
		}
		p = p->pNodeSibling;
	}
}
/* ---------------------------------------------------------------------------
	 Take the name after the last  @ - that is the attributename
	 --------------------------------------------------------------------------- */
PUCHAR nox_splitAtrFromName (PUCHAR name)
{
	int balance = 0;
	PUCHAR pEnd;

	for (pEnd = name + strlen(name)-1 ; pEnd >= name; pEnd --) {
		if (*pEnd == MASTERSPACE && balance == 0) {
			*pEnd  = '\0';     // Terminate the Node end giving the name to the node only
			return (pEnd +1);  // atribute name is the next. Return that
		}
		else if (*pEnd == BRABEG) {
			balance ++;
		}
		else if (*pEnd == BRAEND) {
			balance ++;
		}
	}
	return NULL;
}
/* ---------------------------------------------------------------------------
	 Find node by path name, by parsing a name string and traverse the tree
	 It can be relative by giging either a Nodeent or a XML-common pointer
	 --------------------------------------------------------------------------- */
#pragma convert(1252)	 
void nox_CopyValueByNameVC (PLVARCHAR pRes, PNOXNODE pNodeRoot, PLVARCHAR pName, PLVARCHAR pDefault, BOOL joinString)
{
	PUCHAR    pNodeKey, pAtrKey;
	PNOXATTR  pAtr;
	PNOXNODE  pNode;
	PUCHAR    Name = plvc2str(pName);

	// Assume : Not found
	plvccopy (pRes , pDefault);

	if (pNodeRoot == NULL) return;

	pAtrKey = nox_splitAtrFromName (Name);

	pNode = nox_GetNode  (pNodeRoot , Name);
	if (pNode == NULL) return;

	if (pAtrKey) {
		pAtr =  nox_AttributeLookup   (pNode, pAtrKey);
		if (pAtr == NULL)        return;
		if (pAtr->Value == NULL) return;
		str2plvc(pRes , pAtr->Value);

	} else if (pNode->doCount) {
		vcprintf( pRes, "%ld" , pNode->Count);

	} else if (joinString &&  pNode->type == ARRAY) {
		nox_joinArray2vc (pRes , pNode);
		if (pRes->Length == 0) { // No data found when joining arrays as string - Now serialize it as usual
			nox_AsJsonText (pRes, pNode);
		}

	} else if (pNode->type == OBJECT ||  pNode->type == ARRAY ) {
		nox_AsJsonText (pRes, pNode );

	} else if (pNode->Value) {
		pRes->Length = memSize(pNode->Value) -1 ; // With out the zero termination
 		memcpy(pRes->String, pNode->Value, pRes->Length);
	}
}
#pragma convert(0)
/* ---------------------------------------------------------------------------
   Obsolete- use MergeObjects, but still used by nox_SetByParseString !! TODO !!
   --------------------------------------------------------------------------- */
void nox_NodeMerge(PNOXNODE pDest, PNOXNODE pSource, SHORT replace)
{
  JWRITE jWrite;
  MERGEOPTION merge;
  switch (replace) {
     case true :  merge = MO_MERGE_REPLACE; break;
     case false:  merge = MO_MERGE_NEW    ; break;
     default   :  merge = replace;
  }
  memset(&jWrite , 0 , sizeof(jWrite));
  if (pDest == NULL || pSource == NULL  || pSource->pNodeChildHead == NULL) return;
  // jx_MergeList(pDest, pSource->pNodeChildHead, &jWrite, "", pSource, merge);
  nox_MergeObj (pDest, pSource, &jWrite, merge);
}
/* ---------------------------------------------------------------------------
	 --------------------------------------------------------------------------- */
#pragma convert(1252)
void  nox_SetByParseString (PNOXNODE pDest , PUCHAR pSourceStr , MERGEOPTION merge , BOOL move)
{
	PNOXNODE pSource = NULL;
	PUCHAR  firstNonBlank = pSourceStr;

	// quick trim
	for (;*firstNonBlank == ' '; firstNonBlank++);

	// TODO :  nox_ParseStringVC returns object for any string which is an error; now dont use
	// the paser if it is not an OBJECT or ARRAY
	if ( *firstNonBlank == BRABEG ||  *firstNonBlank == CURBEG) {
		pSource = nox_ParseString( firstNonBlank);
	}

	if (pSource) {
		// TODO !!! Arrays dont work in NodeMerger.. This is a simple workarround
		if (pSource->type == ARRAY) {
			nox_NodeMoveAndReplace (pDest, pSource);
			// nox_NodeFree(pSource); Why delete what we just made .. NLI removed line
			return;
		}

		if (move) {
			nox_NodeMoveAndReplace (pDest, pSource);
			// nox_NodeFree(pSource); Why delete what we just made .. NLI removed line
		} else {
			nox_NodeMerge(pDest, pSource, merge  );
		}
	} else {
		nox_NodeSet (pDest  , pSourceStr);
		pDest->type      = VALUE;
		pDest->isLiteral =  // isdigit (*pSourceStr)  !! No !! the "123 - John" is not a number
			   strcmp(pSourceStr ,TRUESTR) == 0
			|| strcmp(pSourceStr ,FALSESTR) == 0
			|| strcmp(pSourceStr ,NULLSTR) == 0;
	}
}
#pragma convert(0)
/* ---------------------------------------------------------------------------
	 Insert a node as tail in an array - as copy or move it into
	 --------------------------------------------------------------------------- */
#pragma convert(1252)

PNOXNODE  nox_ArrayPush (PNOXNODE pDest, PNOXNODE pSource , BOOL16 copyP)
{
	PNOXNODE  pNewNode;
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	BOOL copy = (pParms->OpDescList->NbrOfParms >= 3) ? copyP : false;

	if (pSource == NULL)  {
	// TODO - rather have NULL as value, that literal null,
	// But this requires to check the serialized .....
	// pNewNode  = NewNode  (NULL  , NULL , VALUE);
		pNewNode  = NewNode  (NULL  , NULLSTR , LITERAL);
	} else if (pSource->signature != NODESIG) {
		if (*(PUCHAR) pSource == BRABEG || *(PUCHAR) pSource == CURBEG ) {
			pNewNode = nox_ParseString((PUCHAR) pSource);
		} else {
			pNewNode  = NewNode  (NULL  , (PUCHAR) pSource , VALUE);
		}
	} else if (copy) {
		pNewNode = nox_NodeClone (pSource);
	} else {
		pNewNode = nox_NodeUnlink  (pSource);
	}

	nox_NodeAddChildTail (pDest, pNewNode);

}
#pragma convert(0)
/* ---------------------------------------------------------------------------
	 Appends an array to the end of another array
	 --------------------------------------------------------------------------- */
#pragma convert(1252)
PNOXNODE  nox_ArrayAppend  (PNOXNODE pDest, PNOXNODE pSource , BOOL16 copyP)
{
	PNOXNODE  pNewNode, pNode, pNext;
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	BOOL copy = (pParms->OpDescList->NbrOfParms >= 3) ? copyP : false;

	if (pSource == NULL)  {
	// TODO - rather have NULL as value, that literal null,
	// But this requires to check the serialized .....
	// pNewNode  = NewNode  (NULL  , NULL , VALUE);
		pNewNode  = NewNode  (NULL  , NULLSTR , LITERAL);
	} else if (pSource->signature != NODESIG) {
		if (*(PUCHAR) pSource == BRABEG || *(PUCHAR) pSource == CURBEG ) {
			pNewNode = nox_ParseString((PUCHAR) pSource);
		} else {
			pNewNode  = NewNode  (NULL  , (PUCHAR) pSource , VALUE);
		}
	} else if (copy) {
		pNewNode = nox_NodeClone (pSource);
	} else {
		pNewNode = nox_NodeUnlink  (pSource);
	}

	// Arrays - need first child;
	pNode = pNewNode->pNodeChildHead;
	while (pNode) {
		pNext = pNode->pNodeSibling;
		nox_ArrayPush (pDest , pNode , false);
		pNode = pNext;
	}

	return pDest;
}
#pragma convert(0)
/* ---------------------------------------------------------------------------
	 Slice from element to element in an array
	 --------------------------------------------------------------------------- */
PNOXNODE  nox_ArraySlice   (PNOXNODE pSource , int from , int to, BOOL16 copyP)
{
	PNOXNODE  pNewNode, pNode, pNext, pOut;
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	BOOL copy = (pParms->OpDescList->NbrOfParms >= 2) ? copyP : false;
	int i =0;
	BOOL  deleteAfter = false;

	if (pSource == NULL)  return null;

	if (pSource->signature != NODESIG) {
		if (*(PUCHAR) pSource == BRABEG || *(PUCHAR) pSource == CURBEG ) {
			pSource = nox_ParseString((PUCHAR) pSource);
		}
		if (pSource == NULL)  return null;
		deleteAfter = true;
		copy = false;
	}

	pOut = nox_NewArray();

	// first locate first element;
	pNode = pSource->pNodeChildHead;
	for (i=0; pNode && i < from ; i++) {
		pNode = pNode->pNodeSibling;
	}

	// now keep on pushing
	for (; pNode && (i < to || to == -1); i++) {
		pNext = pNode->pNodeSibling;
		nox_ArrayPush (pOut , pNode , copy);
		pNode = pNext;
	}

	if (deleteAfter) {
		nox_NodeDelete (pSource);
	}

	return pOut;
}
/* ---------------------------------------------------------------------------
	 Find node by name, by parsing a name string and traverse the array list
	 --------------------------------------------------------------------------- */
PNOXNODE  nox_lookupValue (PNOXNODE pNode, PUCHAR expr, BOOL16 ignorecaseP)
{
	PNOXNODE  pTemp;
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	BOOL  ignorecase = (pParms->OpDescList->NbrOfParms >= 3) ? ignorecaseP : false;

	// Dynamic set the compare function
	int (*pComp) (PUCHAR s1 , PUCHAR s2);
	pComp = ignorecase ? stricmp : strcmp ;

	// Works for array and objects
	if (pNode == NULL || ( pNode->type != ARRAY && pNode->type != OBJECT)) return NULL;

	pTemp = pNode->pNodeChildHead;


	while (pTemp) {
		if (pComp (pTemp->Value , expr) == 0) return pTemp; // found !!
		pTemp = pTemp->pNodeSibling;
	}

	return NULL;

}
PNOXNODE  nox_lookupValueVC (PNOXNODE pNode, PLVARCHAR expr, BOOL16 ignorecaseP)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	BOOL16  ignorecase = (pParms->OpDescList->NbrOfParms >= 3) ? ignorecaseP : false;
	return nox_lookupValue (pNode, plvc2str(expr), ignorecaseP);
}
/* ---------------------------------------------------------------------------
	 Find node by name, by parsing a name string and traverse the array list
	 --------------------------------------------------------------------------- */
LONG nox_getLength (PNOXNODE pNode)
{
	PNOXNODE  pTemp;
	LONG len = 0;

	// Works for array and objects
	if (pNode == NULL || (pNode->type != ARRAY && pNode->type != OBJECT)) return -1;

	pTemp = pNode->pNodeChildHead;
	while (pTemp) {
		len ++;
		pTemp = pTemp->pNodeSibling;
	}

	return len;

}
// -----------------------------------------------------------------------------------------
// Enshure that the complete path has a assoiceated node
// -----------------------------------------------------------------------------------------
PNOXNODE nox_CreateSubNodes  (PNOXNODE pNodeRoot , PUCHAR Path )
{

	UCHAR    tempName [256];
	PUCHAR   pName = tempName;
	PUCHAR   pEnd;
	PNOXNODE  pParentNode, pNodeTemp;
	BOOL     isNewArray = false;

	strcpy(tempName, Path);

	if  (pName[0] == BRABEG && pName[1] == BRAEND) {   // the empty array: []
		pName += 2;
		pNodeRoot->type = ARRAY;
		pParentNode = nox_NodeAdd (pNodeRoot, RL_LAST_CHILD, NULL , NULL, VALUE);
		isNewArray = true;
	} else if  (*pName == BRABEG) {
		pName ++ ;
		pParentNode = pNodeRoot;
	} else if (findchr(pName , delimiters , sizeof(DELIMITERS)-1) == pName) {
		pName ++ ;
		pParentNode = nox_GetRoot(pNodeRoot);
	} else {
		pParentNode = pNodeRoot;
	}


	do {
		NODETYPE nodeType = VALUE;
		UCHAR arrix [64];
		pEnd = findchr(pName , delimiters , sizeof(DELIMITERS)-1);
		if (pEnd) {
			if      (*pEnd == BRABEG && pEnd[1] == BRAEND) isNewArray = true;
			else if (isNextDelimiter(*pEnd))               nodeType = OBJECT;
			else if (*pEnd == BRABEG)                      nodeType = ARRAY;
			else if (*pEnd == BRAEND) {
				int len = pEnd - pName;
				sprintf(arrix , "%c%*.*s%c" , BRABEG, len,len, pName , BRAEND);
				pName = arrix;
			}
			*pEnd = '\0'; // temp termination
		}
		if (*pName) {
			pNodeTemp = nox_GetNode  (pParentNode , pName);
			if (pNodeTemp == NULL) {
				freeNodeValue (pParentNode); // Can not have values if we have childrens
				// When i have children, then i must be an object or an array
				if (pParentNode->type != ARRAY) {
					pParentNode->type = OBJECT;
				}
				pNodeTemp = nox_NodeAdd (pParentNode, RL_LAST_CHILD, pName , NULL, isNewArray ? ARRAY : nodeType);
			}

			// The [] syntax  - Add the new entry to the array
			if (isNewArray) {
				freeNodeValue(pNodeTemp);     // Can not have values if we have childrens
				pNodeTemp->type = ARRAY ;     // When i have childrne then i must be an object or array
				pNodeTemp = nox_NodeAdd (pNodeTemp, RL_LAST_CHILD, NULL , NULL, nodeType);
				pName = pEnd + 2;
				if (isNextDelimiter(*pName))  pName++;
				isNewArray = false; // Done with array chekking
			}
			// Todo !! (Not that elegant) - we just eate one byte to much at the [ xx ] index,
			// so push the bracket back again
			// else if (nodeType == ARRAY) {
			//    pName = pEnd;
			//    *pName = BRABEG;
			// }
			else {
				pName = pEnd + 1;
			}
			pParentNode = pNodeTemp;
		}
	 }  while (pEnd);

	 return pParentNode;
}
/* ---------------------------------------------------------------------------
	 Get the node. If not exists the produce all nodes required
	 --------------------------------------------------------------------------- */
PNOXNODE  nox_GetOrCreateNode (PNOXNODE pNodeRoot, PUCHAR Name)
{
	PNOXNODE pDest;

	pDest  = nox_GetNode  (pNodeRoot , Name);

	// Not found? Build the Nodeents
	if (pDest  == NULL) {
		pDest  = nox_CreateSubNodes (pNodeRoot , Name);
	}
	return pDest;
}
/* ---------------------------------------------------------------------------
	 Get the node. If not exists the produce all nodes required
	 --------------------------------------------------------------------------- */
PNOXNODE  nox_GetOrCreateNodeVC (PNOXNODE pNodeRoot, PLVARCHAR pName)
{
	return nox_GetOrCreateNode (pNodeRoot, plvc2str(pName));
}
/* ---------------------------------------------------------------------------
	 Find node by path name, by parsing a name string and traverse the tree
	 It can be relative by giving either a Node and a name
	 --------------------------------------------------------------------------- */
PNOXNODE  nox_SetValueByName (PNOXNODE pNodeRoot, PUCHAR Name, PUCHAR Value, NODETYPE typePP)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	PUCHAR        pNodeKey, pAtrKey;
	PNOXATTR      pAtr;
	PNOXNODE       pParentNode, pNodeTemp;
	NODETYPE      typeP = (pParms->OpDescList->NbrOfParms >= 4) ? typePP : UNKNOWN;
	NODETYPE      type  = typeP & 255;   // Strip the modifiers
	MERGEOPTION   merge = typeP & (MO_MERGE_NEW + MO_MERGE_MATCH + MO_MERGE_REPLACE); // All mergeoptions
	BOOL          move  = (typeP & NT_MOVE ) > 0;
	BOOL          debug = false;

	if (pNodeRoot == NULL) {
		return NULL;
	}

	pAtrKey = strchr(Name, MASTERSPACE);

	if (pAtrKey) {
		PUCHAR pExp = strchr(Name, BRABEG);
		if  (pExp == null || pAtrKey  < pExp) {
			*pAtrKey = '\0'; // Terminate the Nodeent
			pAtrKey ++;     // atribute is the next
		}
	}

	// Get the node or create it if it does not exists
	pParentNode = nox_GetOrCreateNode (pNodeRoot, Name);

	if (pAtrKey) {
		nox_SetNodeAttrValue  (pParentNode , pAtrKey, Value);
		return nox_traceNode("Attributes" ,pParentNode);
	}

	if (pParms->OpDescList->NbrOfParms >= 4) {
		if ( type == PARSE_STRING) {
			nox_SetByParseString (pParentNode , Value, merge , move);
			return nox_traceNode("Parse String", pParentNode);
		}
		if ( type == POINTER_VALUE) {
			nox_NodeSetAsPointer (pParentNode , Value);
			return nox_traceNode("Pointer", pParentNode);
		}
	}

	// The value is an object / or an array already
	if (Value && *Value == NODESIG) {
		// TODO!! Clean this up ... Node copy replace the node value
		// where NodeCloneAndReplace replace the node it self
		// if ( pParms->OpDescList->NbrOfParms >= 4 && (type == CLONE || type == CLONE_OLD)) {
		//    nox_NodeCopy (pParentNode , (PNOXNODE) Value, RL_LAST_CHILD);
		//   return nox_traceNode("Node Copy " , pParentNode);

		if (move) {
			nox_NodeMoveAndReplace (pParentNode , (PNOXNODE) Value);
			return nox_traceNode("Node Move and Replace " , pParentNode);
		} else {
			nox_NodeCloneAndReplace (pParentNode , (PNOXNODE) Value);
			return nox_traceNode("Node Clone and replace" , pParentNode);
		}
	}

	nox_NodeSet (pParentNode , Value);
	if (pParms->OpDescList->NbrOfParms >= 4) {
		if (type == LITERAL) {
			pParentNode->type      = VALUE;
			pParentNode->isLiteral = TRUE;
		} else {
			pParentNode->type = type;
			pParentNode->isLiteral = FALSE;
		}
	}

	return nox_traceNode("Set value" , pParentNode);
}
/* -------------------------------------------------------------
	 Set integer by name
	 ------------------------------------------------------------- */
PNOXNODE  nox_SetIntByName (PNOXNODE pNode, PUCHAR  Name, LONG Value)
{
	UCHAR  s [32];
	sprintf(s , "%ld" , Value);
	return nox_SetValueByName(pNode , Name, stre2a(s,s), LITERAL );
}
PNOXNODE  nox_SetIntByNameVC (PNOXNODE pNode, PLVARCHAR  Name, LONG Value)
{
	UCHAR  s [32];
	sprintf(s , "%ld" , Value);
	return nox_SetValueByName(pNode , plvc2str(Name) , stre2a(s,s), LITERAL );
}
PNOXNODE  nox_SetDateByNameVC (PNOXNODE pNode, PLVARCHAR  Name, DATE Value)
{
	UCHAR  s [32];
	substr(s , (PUCHAR) &Value  , sizeof(DATE));
	return nox_SetValueByName(pNode , plvc2str(Name) , stre2a(s,s), VALUE );
}
/* -------------------------------------------------------------
	 Set decimal  by name
	 ------------------------------------------------------------- */
PNOXNODE  nox_SetDecByNameVC (PNOXNODE pNode, PLVARCHAR Name, FIXEDDEC Value)
{
	UCHAR  s [32];
	PUCHAR t;
	int len = sprintf(s , "%D(30,15)" , Value);
	PUCHAR p = s + len -1 ;
	// int cutlen = 16; // remove last trailing zeroes. if none after the decimal point the also the secimal point
	int cutlen = 14; // remove last trailing zeroes. Keep the last zero so it is still a decimal point

	// %D is determined ny locale so we can have either  , or .
	// we always need .
	for(t=s; *t ; t++) {
		if (*t == ',') {
			*t = '.';
			break;
		}
	}

	while ((*p == '0' || *p == '.') && cutlen --) {
		*p = '\0';
		p--;
	}

	return nox_SetValueByName(pNode , plvc2str(Name) , stre2a(s,s), LITERAL );
}
/* -------------------------------------------------------------
	 Set BOOL by name
	 ------------------------------------------------------------- */
#pragma convert(1252)
PNOXNODE  nox_SetBoolByName (PNOXNODE pNode, PUCHAR pName, BOOL Value)
{
	return nox_SetValueByName(pNode , pName , Value ? FALSESTR:TRUESTR, LITERAL );
}
PNOXNODE  nox_SetBoolByNameVC (PNOXNODE pNode, PLVARCHAR pName, LGL Value)
{
	return nox_SetValueByName(pNode , plvc2str(pName) , Value == OFF ? FALSESTR:TRUESTR, LITERAL );
}
#pragma convert(0)
/* -------------------------------------------------------------
	 Set string value by name
	 ------------------------------------------------------------- */
PNOXNODE  nox_SetStrByName (PNOXNODE pNode, PUCHAR pName, PUCHAR pValue)
{
	return nox_SetValueByName(pNode , pName , pValue , VALUE );
}
PNOXNODE  nox_SetStrByNameVC (PNOXNODE pNode, PLVARCHAR pName, PLVARCHAR pValue)
{
	return nox_SetValueByName(pNode , plvc2str(pName) , plvc2str(pValue) ,VALUE);
}
/* -------------------------------------------------------------
	 Set evaluate by parser - set by name
	 ------------------------------------------------------------- */
PNOXNODE  nox_SetEvalByNameVC (PNOXNODE pNode, PLVARCHAR Name, PLVARCHAR pValue)
{
	return nox_SetValueByName(pNode , plvc2str(Name) , plvc2str(pValue) , PARSE_STRING );
}
/* -------------------------------------------------------------
	 Set pointer by name
	 ------------------------------------------------------------- */
PNOXNODE  nox_SetPtrByNameVC (PNOXNODE pNode, PLVARCHAR pName, PUCHAR Value, LGL isStringP)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	BOOL isString  = (pParms->OpDescList->NbrOfParms >= 4 && isStringP == ON);
	PNOXNODE pRes = nox_SetValueByName(pNode , plvc2str(pName) , Value , POINTER_VALUE );
	pRes->isLiteral = ! isString;
	return pRes;
}
// -------------------------------------------------------------
void nox_GetValueVC(PLVARCHAR pRes, PNOXNODE pNodeRoot, PLVARCHAR NameP, PLVARCHAR DefaultP)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	PLVARCHAR  Name    = (pParms->OpDescList->NbrOfParms >= 3) ? NameP    : PLVARCHARNULL;
	PLVARCHAR  Default = (pParms->OpDescList->NbrOfParms >= 4) ? DefaultP : PLVARCHARNULL;
	nox_CopyValueByNameVC ( pRes , pNodeRoot, Name , Default , false) ;
}
// -------------------------------------------------------------
void nox_GetStrJoinVC(PLVARCHAR pRes, PNOXNODE pNodeRoot, PLVARCHAR NameP, PLVARCHAR DefaultP)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	PLVARCHAR  Name    = (pParms->OpDescList->NbrOfParms >= 3) ? NameP    : PLVARCHARNULL;
	PLVARCHAR  Default = (pParms->OpDescList->NbrOfParms >= 4) ? DefaultP : PLVARCHARNULL;
	nox_CopyValueByNameVC ( pRes , pNodeRoot, Name , Default , true ) ;
}
// -------------------------------------------------------------
FIXEDDEC nox_GetValueNumVC (PNOXNODE pNode , PLVARCHAR NameP  , FIXEDDEC dftParm)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	PLVARCHAR  path  =  (pParms->OpDescList->NbrOfParms >= 2) ? NameP  : PLVARCHARNULL;
	FIXEDDEC   dft   =  (pParms->OpDescList->NbrOfParms >= 3) ? dftParm : 0;
	
	PUCHAR  value;

	value = nox_GetValuePtr    (pNode , plvc2str(path) , NULL ) ;
	if (value == NULL) {
		return  dft;
	}
	return nox_aNum(value);
}
// -------------------------------------------------------------
INT64 nox_GetValueIntVC (PNOXNODE pNode , PLVARCHAR NameP  , INT64 dftParm)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	PLVARCHAR  path  =  (pParms->OpDescList->NbrOfParms >= 2) ? NameP  : PLVARCHARNULL;
	INT64      dft   =  (pParms->OpDescList->NbrOfParms >= 3) ? dftParm : 0;
	PUCHAR   value;

	value = nox_GetValuePtr    (pNode , plvc2str(path) , NULL ) ;
	if (value == NULL) {
		return  dft;
	}
	return nox_aNum(value);
}
// -------------------------------------------------------------
DATE nox_GetValueDateVC (PNOXNODE pNode , PLVARCHAR NameP  , DATE dftParm)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	PLVARCHAR  path  =  (pParms->OpDescList->NbrOfParms >= 2) ? NameP  : PLVARCHARNULL;
	PUCHAR     value;
	DATE       ret;

	value = nox_GetValuePtr    (pNode , plvc2str(path) , NULL ) ;
	if (value == NULL) {
		if (pParms->OpDescList->NbrOfParms >= 3) {
			return  dftParm;
		}
		memcpy (&ret , "0001-01-01", sizeof(DATE));
	} else {
		mema2e ((PUCHAR) &ret , value , sizeof(DATE));
	}
	return ret;
}
// -------------------------------------------------------------
void nox_GetNodeValueVC (PLVARCHAR pRes, PNOXNODE pNode , PLVARCHAR pDefaultValue)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	PLVARCHAR dft = (pParms->OpDescList->NbrOfParms >= 3) ? pDefaultValue : PLVARCHARNULL;
	PUCHAR value;

	value =  nox_GetNodeValuePtr  (pNode , plvc2str(dft));
	pRes->Length = memSize(value) -1 ; // without the zero term char
	memcpy(pRes->String , value , pRes->Length);
}
// -------------------------------------------------------------
FIXEDDEC nox_GetNodeValueNum (PNOXNODE pNode , FIXEDDEC DefaultValue)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	FIXEDDEC dft = (pParms->OpDescList->NbrOfParms >= 2) ? DefaultValue : 0;
	PUCHAR value =  nox_GetNodeValuePtr  (pNode , NULL  );
	if (value == NULL) {
		return dft;
	} else {
		return nox_aNum(value);
	}
 }
// -------------------------------------------------------------
PUCHAR  nox_GetNodeNamePtr (PNOXNODE pNode)
{
	return (pNode && pNode->Name) ? pNode->Name : "";
}
// -------------------------------------------------------------
void nox_GetNodeNameVC (PLVARCHAR pRes, PNOXNODE pNode)
{
	pRes->Length = 0;
	if (pNode && pNode->Name) {
		pRes->Length = memSize(pNode->Name) -1; // with out the zero term 
		memcpy(pRes->String , pNode->Name , pRes->Length);
	}
}
// -------------------------------------------------------------
void nox_GetNodeAttrValueVC (PLVARCHAR pRes, PNOXNODE pNode ,PLVARCHAR pAttrName, PLVARCHAR  pDefaultValue)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	PLVARCHAR dft = (pParms->OpDescList->NbrOfParms >= 4) ? pDefaultValue : PLVARCHARNULL;
	PUCHAR value =  nox_GetNodeAttrValuePtr  ( pNode , plvc2str(pAttrName),  plvc2str(dft)) ;
	pRes->Length = memSize(value) -1; // with out the zero term 
	memcpy(pRes->String , value , pRes->Length);
}
// -------------------------------------------------------------
FIXEDDEC nox_GetNodeAttrValueNumVC (PNOXNODE pNode , PLVARCHAR pAttrName, FIXEDDEC DefaultValue)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	FIXEDDEC dft = (pParms->OpDescList->NbrOfParms >= 3) ? DefaultValue : 0;
	PNOXATTR pAttr = nox_AttributeLookup   (pNode, plvc2str(pAttrName));

	if (pAttr == NULL
	||  pAttr->Value == NULL) {
		return ( dft );
	} else {
		return nox_aNum(pAttr->Value);
	}
}
// -------------------------------------------------------------
PNOXNODE nox_GetNodeNext (PNOXNODE pNode)
{
	if (pNode == NULL) {
		return  NULL ;
	} else {
		return  pNode->pNodeSibling ;
	}
}
// -------------------------------------------------------------
PNOXNODE nox_GetNodeChild  (PNOXNODE pNode)
{
	if (pNode == NULL) {
		return  NULL ;
	} else {
		return  pNode->pNodeChildHead ;
	}
}
// -------------------------------------------------------------
PNOXNODE nox_GetNodeChildNo ( PNOXNODE pNode , int childNo)
{
	PNOXNODE pChild =  nox_GetNodeChild (pNode);
	int i =0;
	while (i < childNo && pChild) {
		pChild  = nox_GetNodeNext(pChild);
		i++;
	}
	return pChild;
}
// -------------------------------------------------------------
PNOXATTR  nox_GetAttrFirst (PNOXNODE pNode)
{
	if (pNode == NULL) {
		return (NULL);
	} else {
		return (pNode->pAttrList);
	}
}
// -------------------------------------------------------------
PNOXATTR  nox_GetAttrNext  (PNOXATTR pAttr)
{
	if (pAttr == NULL) {
		return (NULL);
	} else {
		return (pAttr->pAttrSibling);
	}
}
// -------------------------------------------------------------
void nox_GetAttrNameVC (PLVARCHAR pRes, PNOXATTR pAttr)
{
	pRes->Length = 0;
	if (pAttr) {
		pRes->Length = memSize(pAttr->Name)  -1; // with out the zero term ;
		memcpy(pRes->String , pAttr->Name , pRes->Length);
	}
}
// -------------------------------------------------------------
PUCHAR  nox_GetAttrNamePtr (PNOXATTR pAttr)
{
	return (pAttr && pAttr->Name) ? pAttr->Name : null;
}
// -------------------------------------------------------------
PUCHAR  nox_GetAttrValuePtr (PNOXATTR pAttr)
{
	return (pAttr && pAttr->Value) ? pAttr->Value : null;
}
// -------------------------------------------------------------
FIXEDDEC nox_GetAttrValueNum  (PNOXATTR pAttr, FIXEDDEC dftParm)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	FIXEDDEC dft = (pParms->OpDescList->NbrOfParms >= 2) ? dftParm  : 0;
	PUCHAR  value = nox_GetAttrValuePtr (pAttr);
	return  value ? nox_aNum(value)  : dft;
}
// -------------------------------------------------------------
void nox_GetAttrValueVC (PLVARCHAR pRes, PNOXATTR pAttr, PLVARCHAR pDefaultValue)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	PLVARCHAR  dft = (pParms->OpDescList->NbrOfParms >= 3) ? pDefaultValue :  PLVARCHARNULL;;

	pRes->Length = 0;
	if (pAttr &&  pAttr->Value ) {
		pRes->Length = memSize(pAttr->Value) -1; // with out the zero term 
		memcpy(pRes->String , pAttr->Value, pRes->Length);
	}

	if (pRes->Length ==0) {
		plvccopy (pRes , dft);
	}
}
// -------------------------------------------------------------
LGL  nox_Error (PNOXNODE  pNode)
{
    return ( jxError || pNode == NULL) ? ON : OFF;
}
// -------------------------------------------------------------
PUCHAR nox_ErrStr (PNOXNODE pJxNode)
{
	return jxMessage;
}
// -------------------------------------------------------------
VARCHAR1024 nox_MessageVC  (PNOXNODE pJxNode)
{
	VARCHAR1024 res;
	str2vc (&res ,  jxMessage);
	return res;
}
// -------------------------------------------------------------
VOID nox_SetApiErr (PNOXNODE pJxNode, PAPIERR pApiErr)
{
	strcpy (pApiErr->msgid , "CPF9898");
	substr  (pApiErr->msgdta , jxMessage ,pApiErr->size - 25 );  // not inc. the header
	pApiErr->avail  = strlen(pApiErr->msgdta);
}
// -------------------------------------------------------------
#pragma convert(1252)
PNOXNODE nox_GetMessageObject (PUCHAR msgId , PUCHAR msgDta)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	PNOXNODE pMsg = nox_NewObject();
	nox_SetBoolByName (pMsg , "success" ,  false);
	if (pParms->OpDescList->NbrOfParms > 0)  {
		nox_SetStrByName (pMsg , "msgId" ,  msgId);
		nox_SetStrByName (pMsg , "msgDta",  msgDta);
		// TODO - convert the msgid / msgData to text
	} else  {
		nox_SetStrByName (pMsg , "msg",  jxMessage);
	}
	return pMsg;
}
#pragma convert(0)
// -------------------------------------------------------------
#pragma convert(1252)
PNOXNODE nox_SuccessTrue ()
{
	PNOXNODE pMsg = nox_NewObject();
	nox_SetBoolByName (pMsg , "success" ,  true);
	return pMsg;
}
#pragma convert(0)
// -------------------------------------------------------------
// Avoid closing an already closed XML
// -------------------------------------------------------------
void nox_Close (PNOXNODE * ppNode)
{
	PNOXNODE  pRoot  =  nox_GetRoot (*ppNode);
	nox_NodeDelete (pRoot);

	*ppNode = NULL;
}
// -------------------------------------------------------------
// remove all children from an object / array
// -------------------------------------------------------------
void nox_Clear  (PNOXNODE pNode)
{
	if (pNode != NULL) {
		nox_FreeChildren(pNode);
	}
}
// ------------------------------------------------------Ë-------
void nox_Free  (PNOXNODE pNode)
{
	nox_FreeSiblings(pNode);
}
//---------------------------------------------------------------------------
BOOL nox_HasMore(PNOXNODE pNode)
{
	return (pNode != NULL);
}
//---------------------------------------------------------------------------
LGL nox_IsNode(PNOXNODE pNode)
{
	return  (pNode->signature == NODESIG) ? ON : OFF;
}
//---------------------------------------------------------------------------
LGL nox_MemLeak(VOID)
{
	return  isOn(memLeak());
}
//---------------------------------------------------------------------------
VOID nox_MemStat(VOID)
{
	memStat();
}
//---------------------------------------------------------------------------
INT64 nox_MemUse(VOID)
{
	return memUse();
}

