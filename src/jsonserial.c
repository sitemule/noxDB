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
#include <unistd.h>
#include <sys/stat.h>

#include "ostypes.h"
#include "varchar.h"
#include "sndpgmmsg.h"
#include "trycatch.h"
// #include "rtvsysval.h"
#include "parms.h"
#include "memUtil.h"
#include "streamer.h"
#include "noxDbUtf8.h"


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
   PNOXWRITER pNoxWriter = pStream->handle;
   if (pNoxWriter->doTrim) return;

   //if(!pNoxWriter->wasHere) {
   //   pNoxWriter->wasHere = true;
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
         nox_Joblog("Invalid parent relation %s , %s for %s",
            pNode->pNodeParent->Name,
            pParent->Name,
            pNode->Name
         );
      }
      catch (NULL) ;
    }
}
/* --------------------------------------------------------------------------- */
#pragma convert(1252)
static void  jsonStreamPrintObject  (PNOXNODE pParent, PSTREAM pStream, SHORT level)
{
   PNOXNODE pNode;
   SHORT nextLevel = level +1;

   // indent (pStream ,level);
   stream_putc (pStream, CURBEG);
   for (pNode = pParent->pNodeChildHead ; pNode ; pNode=pNode->pNodeSiblingNext) {
      indent (pStream ,nextLevel);
      stream_putc(pStream, QUOT);
      stream_puts(pStream, pNode->Name);
      stream_putc(pStream, QUOT);
      stream_putc(pStream, COLON);
      checkParentRelation(pNode , pParent);
      jsonStreamPrintNode (pNode , pStream, nextLevel);
      if (pNode->pNodeSiblingNext) stream_putc  (pStream, COMMA );
   }
   indent (pStream , level);
   stream_putc (pStream, CUREND);
}
#pragma convert(0)
/* --------------------------------------------------------------------------- */
#pragma convert(1252)
static void  jsonStreamPrintArray (PNOXNODE pParent, PSTREAM pStream, SHORT level)
{
    PNOXNODE pNode;
    SHORT nextLevel = level +1;

    // indent (pStream ,level);
    stream_putc (pStream, BRABEG);
    indent (pStream ,nextLevel);
    for (pNode = pParent->pNodeChildHead ; pNode ; pNode=pNode->pNodeSiblingNext) {
      // indent (pStream ,nextLevel);
      checkParentRelation(pNode , pParent);
      jsonStreamPrintNode (pNode , pStream, nextLevel);
      if (pNode->pNodeSiblingNext) stream_putc  (pStream, COMMA );
    }
    indent (pStream , level);
    stream_putc (pStream, BRAEND);
}
#pragma convert(0)
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
/* -- Experimental for issue90 ----------------------------------------------- */
/* Transcode - analyse what node type it might be                              */
/* XML Elements - if no children then a value else an object object            */
/* --------------------------------------------------------------------------- */
static void jsonStreamPrintTranscode (PNOXNODE pNode, PSTREAM pStream, SHORT level)
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
      case NOX_SUBGRAPH:
         jsonStreamPrintNode   ((PNOXNODE) pNode->Value, pStream, level);
         break;
      default:
         jsonStreamPrintTranscode (pNode, pStream, level);
    }
}
/* --------------------------------------------------------------------------- */
#pragma convert(1252)
void  jsonStream (PNOXNODE pNode, PSTREAM pStream)
{
   if (pNode == NULL) {
      stream_puts (pStream, NULLSTR);
   } else {
      jsonStreamPrintNode (pNode, pStream, 0);
   }
}
#pragma convert(0)

// ----------------------------------------------------------------------------
LONG nox_AsJsonTextMem (PNOXNODE pNode, PUCHAR buf , ULONG maxLenP)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PSTREAM  pStream;
   LONG     len;
   NOXWRITER   noxWriter;
   PNOXWRITER  pNoxWriter = &noxWriter;
   memset(pNoxWriter , 0 , sizeof(noxWriter));

   if (pNode == NULL) return 0;
   if (pNode->signature != NODESIG) {
      strcpy (buf, (PUCHAR) pNode);
      return strlen(buf);
   }

   pStream = stream_new (4096);
   pStream->writer  = nox_memWriter;
   pStream->handle = pNoxWriter;
   pNoxWriter->buf = buf;
   pNoxWriter->doTrim = true;
   pNoxWriter->maxSize =   pParms->OpDescList == NULL
      || (pParms->OpDescList && pParms->OpDescList->NbrOfParms >= 3) ? maxLenP : MEMMAX;

   jsonStream (pNode , pStream);
   len = pStream->totalSize;
   stream_putc   (pStream,'\0');
   stream_delete (pStream);
   return  len;

}
// ----------------------------------------------------------------------------
void  jsonStreamRunner   (PSTREAM pStream)
{
   PNOXNODE  pNode = pStream->context;
   jsonStream (pNode , pStream);
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
   NOXWRITER  noxWriter;
   PNOXWRITER pNoxWriter= &noxWriter;
   UCHAR   mode[32];
   UCHAR  sigUtf8[]  =  {0xef , 0xbb , 0xbf , 0x00};
   UCHAR  sigUtf16[] =  {0xff , 0xfe , 0x00};

   // Negative values trigger BOM codes
   BOOL   makeBomCode  = Ccsid < 0;
   Ccsid = Ccsid < 0  ? - Ccsid : Ccsid;

   memset(pNoxWriter , 0 , sizeof(noxWriter));

   if (pNode == NULL) return;

   pStream = stream_new (4096);
   pStream->handle = pNoxWriter;
   pStream->writer = nox_fileWriter;

   sprintf(mode , "wb,o_ccsid=%d", Ccsid);
   unlink  ( strTrim(FileName)); // Just to reset the CCSID which will not change if file exists
   pNoxWriter->outFile  = fopen ( strTrim(FileName) , mode );
   if (pNoxWriter->outFile == NULL) return;

   pNoxWriter->doTrim = (pParms->OpDescList && pParms->OpDescList->NbrOfParms >= 4 && trimOut == OFF) ? FALSE : TRUE;
   pNoxWriter->iconv  = XlateOpen(1208, Ccsid, false);

   if (makeBomCode) {
      switch(Ccsid) {
         case 1208 :
            fputs (sigUtf8, pNoxWriter->outFile );
            break;
         case 1200 :
            fputs (sigUtf16, pNoxWriter->outFile );
            break;
      }
   }

   jsonStream (pNode , pStream);

   stream_delete (pStream);
   fclose(pNoxWriter->outFile);
   iconv_close(pNoxWriter->iconv);
}
