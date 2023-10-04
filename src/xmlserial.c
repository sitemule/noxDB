/* SYSIFCOPT(*IFSIO) TERASPACE(*YES *TSIFC) STGMDL(*SNGLVL) */
/* ----------------------------------------------------------------- *
 * Company . . . : System & Method A/S                               *
 * Design  . . . : Niels Liisberg                                    *
 * Function  . . : NOX - XML serializer - refactored                 *
 *                                                                   *
 * By     Date       Task    Description                             *
 * NL     22.07.2021 0000000 New module                              *
 * NL     04.10.2023 0000000 FIx for serialize only selected element *
 * ----------------------------------------------------------------- */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h>
#include <leod.h>
#include <decimal.h>
#include <wchar.h>

#include <sys/stat.h>
#include "ostypes.h"
#include "xlate.h"
#include "parms.h"
#include "rtvsysval.h"
#include "utl100.h"
#include "mem001.h"
#include "varchar.h"
#include "streamer.h"
#include "jsonxml.h"


BOOL  doTrim;
extern int   InputCcsid , OutputCcsid;
extern UCHAR BraBraGT [4];  // ]]>
extern UCHAR Cdata    [10]; // <![CDATA[


#pragma convert(1252)
static void jx_WriteXmlStmfNodeList (FILE * f, iconv_t * pIconv ,PJXNODE pNode, SHORT cdatamode, SHORT level)
{
   PJXNODE  pNodeTemp, pNodeNext;
   PXMLATTR pAttrTemp;
   UCHAR    tab[256];
   BOOL     shortform;
   BOOL     doEscape;

   #pragma convert(0)
   PUCHAR  defaultNode = "row";
   #pragma convert(1252)

   //' Make indention
   tab [0] = 0x0d;
   tab [1] = 0x0a;
   memset(tab+2, 0x20 ,(level-1)*2);
   tab [2 + ((level-1)*2)] = '\0';

   while (pNode) {

      // For current node and children
      if (pNode->options & JX_FORMAT_CDATA && cdatamode == 0) {
         cdatamode = level;
      }
      doEscape = cdatamode ? FALSE : TRUE;

      if (pNode->Comment) {
         if (!doTrim && cdatamode == 0)  fputs ( tab,  f);
         fputs ( "<!--",  f);
         iconvWrite(f,pIconv, pNode->Comment, FALSE);
         fputs ( "-->",  f);
      }

      if (!doTrim && cdatamode == 0)  fputs ( tab,  f);
      fputs ("<", f);
      iconvWrite(f,pIconv, pNode->Name ? pNode->Name : defaultNode , FALSE);

      for (pAttrTemp = pNode->pAttrList; pAttrTemp ; pAttrTemp = pAttrTemp->pAttrSibling){
         if (pNode->newlineInAttrList) {
            if (!doTrim && cdatamode == 0)  fputs ( tab,  f);
            fputs ("  ", f);
         } else {
            fputc( 0x20 , f);
         }
         iconvWrite( f,pIconv, pAttrTemp->Name, FALSE);
         fputs("=\"" , f);
         iconvWrite( f,pIconv, pAttrTemp->Value, doEscape);
         fputs("\"", f);
      }

      shortform = TRUE;

      if (pNode->Value != NULL && pNode->Value[0] > '\0') {
         shortform = FALSE;
         fputs(">", f);
         if (cdatamode == level) {
            fputs("<![CDATA[", f);
         }
         iconvWrite( f,pIconv, pNode->Value, doEscape);
      }

      if (pNode->pNodeChildHead) {
         shortform = FALSE;
         if (pNode->Value != NULL && pNode->Value[0] > '\0') {
         // Already put - in the above
         } else {
            fputs(">", f);
            if (cdatamode == level) {
               fputs("<![CDATA[", f);
            }
         }
         jx_WriteXmlStmfNodeList (f, pIconv, pNode->pNodeChildHead, cdatamode , level + 1);
      }

      if (shortform) {
         if (pNode->newlineInAttrList) {
            if (!doTrim && cdatamode==0)  fputs ( tab,  f);
         }
         fputs("/>", f);
      } else {
         if (pNode->pNodeChildHead) {
            if (!doTrim && cdatamode==0)  fputs ( tab,  f);
         }
         if (cdatamode == level) {
            fputs("]]>", f);
         }
         fputs("</" , f);
         iconvWrite( f,pIconv, pNode->Name ? pNode->Name : defaultNode , FALSE);
         fputs(">", f);
      }
      if (cdatamode==level) {
         cdatamode = 0;
      }
      // Only process first element on root node
      pNode = (level == 1) ? NULL : pNode->pNodeSibling;
   }

   level --;
}
#pragma convert(0)
/* ---------------------------------------------------------------------------
   --------------------------------------------------------------------------- */
void jx_WriteXmlStmf (PJXNODE pNode, PUCHAR FileName, int Ccsid, LGL trimOut , PJXNODE options)
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

   doTrim = (pParms->OpDescList &&  pParms->OpDescList->NbrOfParms >= 4 && trimOut == OFF) ? FALSE : TRUE;

   if (pNode == NULL) return;

   sprintf(mode , "wb,codepage=%d", Ccsid);
   f = fopen ( strTrim(FileName) , mode );
   if (f == NULL) return;

   Iconv = XlateOpenDescriptor(OutputCcsid , Ccsid , false);

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

   // Root node (the document) is an anonymus list of elements
   if (pNode->pNodeParent == NULL
   &&  pNode->Name       == NULL) {
      PJXNODE pTemp;
      for ( pTemp = pNode ; pTemp; pTemp= pTemp->pNodeSibling) {
         jx_WriteXmlStmfNodeList (f , &Iconv , pTemp->pNodeChildHead, 0, 1);
      }
   // But serialization of any other node in the tree is also supported
   } else {
      jx_WriteXmlStmfNodeList (f , &Iconv , pNode, 0, 1);
   }
   fclose(f);
   iconv_close(Iconv);
}

/* ---------------------------------------------------------------------------
   --------------------------------------------------------------------------- */
static LONG xmlTextMemList (PJXNODE pNode, PUCHAR buf, SHORT cdatamode , SHORT level)
{
   PJXNODE    pNodeTemp, pNodeNext;
   PXMLATTR   pAttrTemp;
   BOOL       shortform;
   PUCHAR     temp = buf;
   PUCHAR     CdataBegin = "";
   PUCHAR     CdataEnd   = "";
   PUCHAR     defaultNode = "row";


   while (pNode) {

      // For current node and children
      if (pNode->options & JX_FORMAT_CDATA && cdatamode == 0) {
         cdatamode  = level;
         CdataBegin = Cdata;
         CdataEnd   = BraBraGT;
      }

      temp +=  sprintf(temp , "<%s", pNode->Name ? pNode->Name : defaultNode  );
      for (pAttrTemp = pNode->pAttrList; pAttrTemp ; pAttrTemp = pAttrTemp->pAttrSibling){
         temp +=  sprintf(temp , " %s=\"%s\"", pAttrTemp->Name, pAttrTemp->Value);
      }

      shortform = TRUE;

      if (pNode->Value != NULL && pNode->Value[0] > '\0') {
         shortform = FALSE;
         temp +=  sprintf(temp , ">%s%s", CdataBegin, pNode->Value);
      }

      if (pNode->pNodeChildHead) {
         shortform = FALSE;
         if (pNode->Value != NULL && pNode->Value[0] > '\0') {
         // Already put - in the above
         } else {
            temp +=  sprintf(temp , ">%s",CdataBegin);
         }
         temp += xmlTextMemList (pNode->pNodeChildHead , temp, cdatamode, level + 1);
      }

      if (shortform) {
         temp +=  sprintf(temp , "/>");
      } else {
         temp +=  sprintf(temp , "%s</%s>", CdataEnd, pNode->Name ? pNode->Name : defaultNode );
      }

      if (cdatamode == level) {
         cdatamode = 0;
      }
      CdataBegin = "";
      CdataEnd   = "";

      // Only process first element on root node
      pNode = (level == 1) ? NULL : pNode->pNodeSibling;
   }

   return temp - buf;

}

// ---------------------------------------------------------------------------
LONG jx_AsXmlTextMem (PJXNODE pNode, PUCHAR buf)
{
   PUCHAR     temp = buf;

   if (pNode== NULL) return (0);

   // Root node (the document) is an anonymus list of elements
   if (pNode->pNodeParent == NULL
   &&  pNode->Name       == NULL) {
      PJXNODE pTemp;
      for ( pTemp = pNode; pTemp; pTemp= pTemp->pNodeSibling) {
         temp += xmlTextMemList (pTemp->pNodeChildHead, temp, 0, 1);
      }
   // But serialization of any other node in the tree is also supported
   } else {
      temp += xmlTextMemList (pNode, temp, 0, 1);
   }

   return temp - buf;

}
// ---------------------------------------------------------------------------
VARCHAR jx_AsXmlText (PJXNODE pNode)
{
   VARCHAR  res;
   res.Length = jx_AsXmlTextMem (pNode , res.String);
   return res;
}
