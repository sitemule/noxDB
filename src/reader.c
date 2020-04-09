// CMD:CRTCMOD 
/* ------------------------------------------------------------- *
 * Company . . . : System & Method A/S                           *
 * Design  . . . : Niels Liisberg                                *
 * Function  . . : File reader                                   *
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

// Just for debugging

static LONG  dbgStep=0;
static BOOL  skipBlanks = TRUE;

// Note !! The complete file is in ASCII
#pragma convert(1252)

/* ---------------------------------------------------------------------------
	--------------------------------------------------------------------------- */
/* 
void initconst(int ccsid)
{
	static int prevccsid = -1;  // can not be negative => force rebuild const

	// already done?
	if ( prevccsid == ccsid) return;
	prevccsid = ccsid;

	RtvXlateTbl  (e2aTbl , a2eTbl , 1252 , ccsid);  // 0=Current job CCSID

	#pragma convert(1252)
	Apos       = a2eTbl['\''];
	Quot       = a2eTbl['\"'];
	Question   = a2eTbl['?' ];
	EQ         = a2eTbl['=' ];
	GT         = a2eTbl['>' ];
	LT         = a2eTbl['<' ];
	Underscore = a2eTbl['_' ];
	Colon      = a2eTbl[':' ];
	Dot        = a2eTbl['.' ];
	Slash      = a2eTbl['/' ];
	Exclmark   = a2eTbl['!' ];
	BackSlash  = a2eTbl['\\'];
	Masterspace= a2eTbl['@' ];
	BraBeg     = a2eTbl['[' ];
	BraEnd     = a2eTbl[']' ];
	CurBeg     = a2eTbl['{' ];
	CurEnd     = a2eTbl['}' ];
	Minus      = a2eTbl['-' ];
	Blank      = a2eTbl[' ' ];
	Amp        = a2eTbl['&' ];
	Hash       = a2eTbl['#' ];
	#pragma convert(0)

	sprintf(Remark    , "%c%c%c", Exclmark , Minus , Minus);    // "!--"
	sprintf(EndRemark , "%c%c%c", Minus, Minus, GT ) ;          // "-->"
	sprintf(SlashGT   , "%c%c"  , Slash , GT ) ;                // "/>"
	sprintf(BraBraGT  , "%c%c%c", BraEnd, BraEnd, GT ) ;        // "]]>"
	sprintf(Cdata     , "%c%c%cCDATA%c", LT, Exclmark , BraBeg, BraBeg ) ; // "<![CDATA["
	sprintf(DocType   , "%cDOCTYPE", Exclmark  ) ; // "!DOCTYPE"

	delimiters [0] = Slash;
	delimiters [1] = BackSlash;
	delimiters [2] = Masterspace;
	delimiters [3] = BraBeg;
	delimiters [4] = BraEnd;
	delimiters [5] = Blank;
	delimiters [6] = Dot;
	delimiters [7] = CurBeg;
	delimiters [8] = CurEnd;

}
*/

// ---------------------------------------------------------------------------
void  nox_SkipChars(PNOXCOM pJxCom , int skip)
{
	int i;
	for(i=0;i<skip; i++) {
		nox_GetChar(pJxCom);
	}
}
// ---------------------------------------------------------------------------
PUCHAR nox_GetChar(PNOXCOM pJxCom)
{

	/*
	if (dbgStep > 8170 ) { //       8179)
		int q = 1;
	}
	*/

	if (pJxCom->State == XML_EXIT_ERROR) {
		return (pJxCom->pFileBuf == NULL ? "" : pJxCom->pFileBuf );
	}

	if (pJxCom->pFileBuf == NULL) {
		pJxCom->pFileBuf =  pJxCom->StreamBuf;
	} else {
		pJxCom->pFileBuf ++;
	}

	if (*pJxCom->pFileBuf == '\0') {
		pJxCom->State = XML_EXIT;
	}
	if (*pJxCom->pFileBuf == CR) {
		pJxCom->LineCount ++;
		pJxCom->ColCount = 0;
	} else {
		pJxCom->ColCount ++;
	}
	return (pJxCom->pFileBuf);
}
/* ---------------------------------------------------------------------------
	--------------------------------------------------------------------------- */
UCHAR SkipBlanks (PNOXCOM pJxCom)
{
	UCHAR c;

	for(;;) {
		c  = *nox_GetChar(pJxCom);
		if ( pJxCom->State == XML_EXIT
		||   pJxCom->State == XML_EXIT_ERROR ) {
			return '\0';
		}
		if (c > BLANK) {
			pJxCom->pFileBuf --; // step back one...
			return c;
		}
	}
}
/* ---------------------------------------------------------------------------
	--------------------------------------------------------------------------- */
void CheckBufSize(PNOXCOM pJxCom)
{
	if (pJxCom->DataIx >= pJxCom->DataSize ||  pJxCom->Data  == NULL) {
		pJxCom->DataSize += DATA_SIZE;
		memRealloc(&pJxCom->Data , pJxCom->DataSize ); // Initial size
	}
}
/* ---------------------------------------------------------------------------
	--------------------------------------------------------------------------- */
void nox_CheckEnd(PNOXCOM pJxCom)
{
	if (*pJxCom->pFileBuf == GT) {
		pJxCom->State = XML_COLLECT_DATA;
		if (skipBlanks) {
			SkipBlanks(pJxCom);
		}
		pJxCom->DataIx=0;
		pJxCom->Data[0]='\0';
		return;
	}
	if (memBeginsWith (pJxCom->pFileBuf ,SLASHGT))  {  // Check for short form   />
		pJxCom->pNodeWorkRoot = pJxCom->pNodeWorkRoot->pNodeParent;
		pJxCom->Level --;
		pJxCom->State = XML_FIND_START_TOKEN;
	}
}

/* ---------------------------------------------------------------------------
	--------------------------------------------------------------------------- */
/*   
int readBlock(PNOXCOM pJxCom , PUCHAR buf, int size)
{
  int len, rlen, j;

  if ( pJxCom->UseIconv) {
	 PUCHAR temp = memAlloc (size);
	 rlen = fread(temp, 1, size , pJxCom->File);
	 len = xlate(pJxCom, buf, temp , rlen);
	 // When Invalid boundry; skip the last byte and retry. This is not complete but works for UTF-8
	 if (len  == -1) {
		len = xlate(pJxCom, buf, temp , rlen -1);

		// OK  - invalid boundary did it, reset the file pointer one back ...
		if (len >= 0) {
			fseek (pJxCom->File , -1 , SEEK_CUR );

		// Still invalid char .. go into win-1252 and retry
		} else {
			iconv_close(pJxCom->Iconv );
			InputCcsid = 1252;
			pJxCom->Iconv = OpenXlate(InputCcsid  , OutputCcsid);
			len = xlate(pJxCom, buf, temp , rlen);
			if (len == -1) { // Still invalid char .. don't what to do !!!
			  pJxCom->State == XML_EXIT_ERROR;
			  memFree (&temp);
			  return 0;
			}
		}
	 }
	 if (OutputCcsid < 1000)  { // Only for EBCDIC output includsice current ccsid which is zero
		for (j=0; j<len ; j++) {
		  if (buf[j] == 0x3f) buf[j] = '_'; // replace substitution char with underscore
		}
	 }
	 memFree (&temp);
  }
  else {
	 len = fread(buf, 1, size , pJxCom->File);
  }

  buf[(len > 0 ) ? len:0] = '\0';
  return len;
}
*/

