// CMD:CRTCMOD
/* ------------------------------------------------------------- *
 * Company . . . : System & Method A/S                           *
 * Design  . . . : Niels Liisberg                                *
 * Function  . . : NOX - XML serializer - refactored             *
 *                                                               *
 * By     Date       Task    Description                         *
 * NL     22.07.2021 0000000 New module                          *
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
#include <unistd.h>

#include <sys/stat.h>
#include "ostypes.h"
#include "varchar.h"
#include "xlate.h"
#include "parms.h"
// #include "rtvsysval.h"
#include "strUtil.h"
#include "memUtil.h"
#include "streamer.h"
#include "noxDbUtf8.h"
#include "e2aa2e.h"



static void xmlStream (PNOXNODE pNode, PSTREAM pStream,  SHORT cdatamode, SHORT level);
LONG nox_AsXmlTextMem (PNOXNODE pNode, PUCHAR buf , ULONG maxLenP);
static PNOXWRITER nox_NewWriter (void);


/* ---------------------------------------------------------------------------
   Local write implementation
	--------------------------------------------------------------------------- */
PNOXWRITER nox_NewWriter ()
{
	PNOXWRITER pNoxWriter = malloc (sizeof(NOXWRITER));
	memset(pNoxWriter , 0 , sizeof(NOXWRITER));
	#pragma convert(1252)
	// XlateBuf(&pNoxWriter->braBeg , "[]{}\\\"" , 6, 1252 ,0 ); ;
	#pragma convert(0)
	return pNoxWriter;
}
/* ---------------------------------------------------------------------------
   Local write implementation
	--------------------------------------------------------------------------- */
VOID nox_DeleteWriter (PNOXWRITER  pNoxWriter)
{
	free(pNoxWriter);
}
/* ---------------------------------------------------------------------------
   Put newline and tabs accoringly to the indention level
   --------------------------------------------------------------------------- */
static void indentXml (	PSTREAM pStream , SHORT cdatamode, SHORT level)
{
   PNOXWRITER pNoxWriter = (PNOXWRITER) pStream->handle;
	if (! pNoxWriter->doTrim && ! cdatamode) {

  	   if(!pNoxWriter->wasHere) {
	      pNoxWriter->wasHere = true;
	   } else {
         stream_putc (pStream,0x0d);
         stream_putc (pStream,0x0a);
   	}

      while (level-- > 0) {
         stream_putc (pStream,0x09);
      }
   }
}
/* ---------------------------------------------------------------------------
   XML escape data to the stream
   --------------------------------------------------------------------------- */
#pragma convert(1252)
void putEscape (PSTREAM pStream , PUCHAR str , BOOL doEscape)
{

   if (doEscape) {
      for (;*str;str++) {
         switch(*str) {
            case '<' : stream_puts (pStream , "&lt;")   ; break;
            case '>' : stream_puts (pStream , "&gt;")   ; break;
            case '&' : stream_puts (pStream , "&amp;")  ; break;
            case '\'': stream_puts (pStream , "&apos;") ; break;
            case '\"': stream_puts (pStream , "&quot;") ; break;
            default  : stream_putc (pStream , *str);
         }
      }
   } else {
      stream_puts (pStream , str);
   }
}
#pragma convert(0)
/* ---------------------------------------------------------------------------
   Stream out the XML
   --------------------------------------------------------------------------- */
#pragma convert(1252)
static void xmlStream (PNOXNODE pNode, PSTREAM pStream,  SHORT cdatamode, SHORT level)
{
   PNOXNODE    pNodeTemp, pNodeNext;
   PNOXATTR   pAttrTemp;
   BOOL       shortform;
   PUCHAR     CdataBegin = "";
   PUCHAR     CdataEnd   = "";
   BOOL       doEscape;

   // Recurse if we are the annonumus root
   if (pNode
   &&  pNode->pNodeParent == NULL
   &&  pNode->Name        == NULL) {
      PNOXNODE pTemp;
      for ( pTemp = pNode ; pTemp; pTemp= pTemp->pNodeSibling) {
	      xmlStream (pTemp->pNodeChildHead ,pStream , FALSE, level);
      }
      return;
   }

   // Iterate through each sibling
   while (pNode) {

      if (pNode->Comment) {
         indentXml ( pStream, cdatamode , level);
         stream_puts (pStream , "<!--");
         stream_puts (pStream , pNode->Comment);
         stream_puts (pStream , "-->");
      }


      // For current node and children
      if (pNode->options & NOX_FORMAT_CDATA && cdatamode == 0) {
         cdatamode  = level;
         CdataBegin = "<![CDATA[";
         CdataEnd   = "]]>";
      }
      doEscape = cdatamode ? FALSE : TRUE;

      // For current node and children
      if (pNode->options & NOX_FORMAT_CDATA && cdatamode == 0) {
         cdatamode = level;
      }

      indentXml ( pStream, cdatamode , level);
      stream_puts (pStream , "<");
      stream_puts (pStream , pNode->Name ? pNode->Name : "row");

      for (pAttrTemp = pNode->pAttrList; pAttrTemp ; pAttrTemp = pAttrTemp->pAttrSibling){
         if (pNode->newlineInAttrList) {
            indentXml ( pStream, cdatamode , level);
         }
         stream_puts (pStream , " "); // TODO - only next time
         stream_puts (pStream , pAttrTemp->Name);
         stream_puts (pStream , "=\"");
         putEscape   (pStream , pAttrTemp->Value , doEscape); // TODO - ENCODE
         stream_puts (pStream , "\"");
      }

      shortform = TRUE;

      if (pNode->Value != NULL && pNode->Value[0] > '\0') {
         shortform = FALSE;
         stream_puts (pStream , ">");
         stream_puts (pStream , CdataBegin);
         putEscape   (pStream , pNode->Value, doEscape);
      }

      if (pNode->pNodeChildHead) {
         shortform = FALSE;
         if (pNode->Value != NULL && pNode->Value[0] > '\0') {
         // Already put - in the above
         } else {
            stream_puts (pStream , ">");
            stream_puts (pStream , CdataBegin);
         }
         xmlStream (pNode->pNodeChildHead , pStream, cdatamode, level + 1);
      }

      if (shortform) {
         if (pNode->newlineInAttrList) {
            indentXml ( pStream, cdatamode , level);
         }
         stream_puts (pStream , "/>");
      } else {
         if (pNode->pNodeChildHead) {
            indentXml ( pStream, cdatamode , level);
         }

         stream_puts (pStream , CdataEnd);
         stream_puts (pStream , "</");
         stream_puts (pStream , pNode->Name ? pNode->Name : "row");
         stream_puts (pStream , ">");
      }

      if (cdatamode == level) {
         cdatamode = 0;
      }
      CdataBegin = "";
      CdataEnd   = "";

      pNode = pNode->pNodeSibling;
   }

}
#pragma convert(0)
// ----------------------------------------------------------------------------
void  xmlStreamRunner   (PSTREAM pStream)
{
	PNOXNODE  pNode = pStream->context;
   xmlStream (pNode , pStream , FALSE , 0);
}

/* ---------------------------------------------------------------------------
   exported function
   --------------------------------------------------------------------------- */
LONG nox_AsXmlTextMem (PNOXNODE pNode, PUCHAR buf , ULONG maxLenP)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	PSTREAM  pStream;
	LONG     len;
	PNOXWRITER  pNoxWriter;


	if (pNode == NULL) return 0;
	if (pNode->signature != NODESIG) {
		strcpy (buf, (PUCHAR) pNode);
		return strlen(buf);
	}

	pStream = stream_new (4096);
	pStream->writer  = nox_memWriter;
	pStream->handle = pNoxWriter = nox_NewWriter();
	pNoxWriter->buf = buf;
	pNoxWriter->doTrim = true;
   pNoxWriter->maxSize =
          pParms->OpDescList == NULL
		|| (pParms->OpDescList && pParms->OpDescList->NbrOfParms >= 3 ) ? maxLenP : MEMMAX;

	xmlStream (pNode , pStream , FALSE , 0);
	len = pStream->totalSize;
	stream_putc   (pStream,'\0');
	stream_delete (pStream);
	nox_DeleteWriter(pNoxWriter);
	return  len;

}
// ---------------------------------------------------------------------------
VOID nox_AsXmlText (PLVARCHAR res , PNOXNODE pNode)
{
	res->Length = nox_AsXmlTextMem (pNode , res->String, MEMMAX);
}
/* ---------------------------------------------------------------------------
   Write using the stream system to disk
   --------------------------------------------------------------------------- */
void nox_WriteXmlStmf (PNOXNODE pNode, PUCHAR FileName, int Ccsid, LGL trimOut, PNOXNODE options)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	PSTREAM pStream;
	PNOXWRITER pNoxWriter;
	UCHAR   mode[32];
   PUCHAR  enc;

	if (pNode == NULL) return;

	pNoxWriter = nox_NewWriter();
	pStream = stream_new (4096);
	pStream->writer = nox_fileWriter;

	sprintf(mode , "wb,o_ccsid=%d", Ccsid);
	unlink  ( strTrim(FileName)); // Just to reset the CCSID which will not change if file exists
	pNoxWriter->outFile  = fopen ( strTrim(FileName) , mode );
	if (pNoxWriter->outFile == NULL) {
		nox_DeleteWriter(pNoxWriter);
		return;
	}

	pStream->handle = pNoxWriter;

	pNoxWriter->doTrim = (pParms->OpDescList && pParms->OpDescList->NbrOfParms >= 4 && trimOut == OFF) ? FALSE : TRUE;
	pNoxWriter->iconv  = XlateOpen(1208 , Ccsid , false );

   #pragma convert(1252)
   switch(Ccsid) {
     case 1252 :
       enc = "WINDOWS-1252";
       break;
     case 1208 :
       enc = "UTF-8";
       break;
     case 1200 :
       enc = "UTF-16";
       break;
     case 819  :
       enc = "ISO-8859-1";
       break;
     default   :
       enc = "windows-1252";
   }

   stream_puts (pStream , "<?xml version=\"1.0\" encoding=\"");
   stream_puts (pStream , enc);
   stream_puts (pStream ,"\" ?>");
   indentXml      (pStream , 0, 0);

   #pragma convert(0)

	xmlStream ( pNode, pStream, FALSE , 0);

	stream_delete (pStream);
	fclose(pNoxWriter->outFile);
	iconv_close(pNoxWriter->iconv);
	nox_DeleteWriter(pNoxWriter);
}

