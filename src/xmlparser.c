/* SYSIFCOPT(*IFSIO) TERASPACE(*YES *TSIFC) STGMDL(*SNGLVL) */
/* ------------------------------------------------------------- *
 * Company . . . : System & Method A/S                           *
 * Design  . . . : Niels Liisberg                                *
 * Function  . . : XML Parser                                    *
 *                                                               *
 * By     Date     Task    Description                           *
 * NL     02.06.03 0000000 New program                           *
 * NL     27.02.08 0000510 Allow also no namespace for *:tag     *
 * NL     27.02.08 0000510 jx_NodeCopy                           *
 * NL     13.05.08 0000577 jx_NodeAdd / WriteNote                *
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
#include "xlate.h"
#include "jsonxml.h"
#include "parms.h"
#include "rtvsysval.h"
#include "utl100.h"
#include "mem001.h"
#include "varchar.h"


extern UCHAR Remark   [4];   // !--
extern UCHAR DocType  [9];   // !DOCTYPE
extern UCHAR EndRemark[4];   // -->
extern UCHAR SlashGT  [3];   // />
extern UCHAR BraBraGT [4];   // ]]>
extern UCHAR Cdata    [10];  // <![CDATA[

extern UCHAR Apos       ;
extern UCHAR Quot       ;
extern UCHAR Question   ;
extern UCHAR EQ         ;
extern UCHAR GT         ;
extern UCHAR LT         ;
extern UCHAR Underscore ;
extern UCHAR Colon      ;
extern UCHAR Dot        ;
extern UCHAR Slash       ;
extern UCHAR Exclmark   ;
extern UCHAR BackSlash  ;
extern UCHAR Masterspace;
extern UCHAR BraBeg     ;
extern UCHAR BraEnd     ;
extern UCHAR CurBeg     ;
extern UCHAR CurEnd     ;
extern UCHAR Minus      ;
extern UCHAR Blank      ;
extern UCHAR Amp        ;
extern UCHAR Hash       ;
extern UCHAR CR         ;


extern UCHAR e2aTbl[256];
extern UCHAR a2eTbl[256];
extern LONG  dbgStep=0;

/* --------------------------------------------------------------------------- */
static void jx_XmlDecode (PUCHAR out, PUCHAR in , ULONG inlen)
{
  PUCHAR p = out;
  PUCHAR pEnd = in  + inlen;
  UCHAR  c;

  while (in < pEnd)  {
    c = *(in);
    if (c == Amp) {
      PUCHAR kwd = in+1;
      if       (BeginsWith(kwd ,"lt;"))  { *(p++) = LT  ; in += 4; }
      else if  (BeginsWith(kwd ,"gt;"))  { *(p++) = GT  ; in += 4; }
      else if  (BeginsWith(kwd ,"amp;")) { *(p++) = Amp ; in += 5; }
      else if  (BeginsWith(kwd ,"apos;")){ *(p++) = Apos; in += 6; }
      else if  (BeginsWith(kwd ,"quot;")){ *(p++) = Quot; in += 6; }
      else if  (in[1] == Hash) {
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
           *(p++) = a2eTbl[n];
        // Unicode chars ...
        } else {
           int l = XlateBufferQ(p  , (PUCHAR) &n , 2 , 13488, 0 );
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
/* ---------------------------------------------------------------------------
   --------------------------------------------------------------------------- */
void jx_AppendName (PJXCOM pJxCom)
{
   PJXNODE pNode;
   UCHAR c = *pJxCom->pWorkBuf;

   if (*pJxCom->pNameIx > sizeof(pJxCom->StartName)) {
      jx_SetMessage( "Name to long at (%d:%d)", pJxCom->LineCount, pJxCom->ColCount);
      pJxCom->State = XML_EXIT_ERROR;
      return;
   }
/* Still a valid name */
   if (c > Blank
   &&  c != Quot
   &&  c != Apos
   &&  c != EQ
   &&  c != LT
   &&  c != GT
   &&  c != Slash) {
      pJxCom->pName[(*pJxCom->pNameIx)++] = c;
      pJxCom->pName[(*pJxCom->pNameIx)]   = '\0';
      return;
   }
/* Name complete .. Add node */
   if (pJxCom->pName == pJxCom->StartName) {
      pJxCom->Level ++;
      pNode = (PJXNODE) memAlloc (sizeof(*pNode));
      memset (pNode , 0, sizeof(*pNode));
      SegmentNodeAdd(pNode);

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
         jx_SetMessage( "Invalid end tag </%s> for start tag <%s> at (%d:%d)" ,
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
   jx_CheckEnd(pJxCom);
   SkipBlanks(pJxCom);
}
/* ---------------------------------------------------------------------------
   --------------------------------------------------------------------------- */
static void jx_AttrAppendName  (PJXCOM pJxCom)
{
   PXMLATTR pAttr;
   UCHAR c = *pJxCom->pWorkBuf;

/*
   {
      static int debug ;
      debug ++;
      if (debug == 617) {
         jx_Dump(pJxCom);
      }
   }
*/

/* Still a valid name */
   if (c > Blank
   &&  c != Quot
   &&  c != Apos
   &&  c != EQ
   &&  c != LT
   &&  c != GT
   &&  c != Slash) {
      CheckBufSize(pJxCom);
      pJxCom->Data[pJxCom->DataIx++] = c;
      pJxCom->Data[pJxCom->DataIx]   = '\0';
      return;
   }

/* Name complete .. Add node */
   if ( pJxCom->DataIx > 0) {
      pAttr = (PXMLATTR) memAlloc (sizeof(*pAttr));
      memset (pAttr , 0, sizeof(*pAttr));
      pAttr->signature  = NODESIG;
      pAttr->Name = memStrDup (pJxCom->Data);
      * pJxCom->pAttr = pAttr;
   }

   pJxCom->DataIx=0;
   pJxCom->Data[0]='\0';
   pJxCom->State = XML_ATTR_VALUE;
   jx_CheckEnd(pJxCom);
}
// ---------------------------------------------------------------------------
// When hitting that point we have to get rid of the <![CDATA[
// and the copy data until we find the ]]>
// ---------------------------------------------------------------------------
void jx_CopyCdata (PJXCOM pJxCom)
{
   PUCHAR p;

   jx_SkipChars(pJxCom , sizeof("<![CDATA[") -2) ; // omit the zero terminator
   p = jx_GetChar(pJxCom);
   while (! BeginsWith(p , BraBraGT  ) &&  pJxCom->State != XML_EXIT) {  // the "]]>"
      CheckBufSize(pJxCom);
      pJxCom->Data[pJxCom->DataIx++] = *p;
      p = jx_GetChar(pJxCom);
   }
   jx_SkipChars(pJxCom , sizeof(BraBraGT) -2) ; // omit the zero terminator
   pJxCom->Data[pJxCom->DataIx]   = '\0';
}
// ---------------------------------------------------------------------------
void jx_AppendData (PJXCOM pJxCom)
{
   UCHAR lookahead;
   UCHAR c = *pJxCom->pWorkBuf;

/* Still a valid name � */
   if (c == LT ) {
   // Check for CDATA stream ... copy until ]]>
      if (BeginsWith(pJxCom->pWorkBuf , Cdata )) {   // the "<![CDATA["
         jx_CopyCdata (pJxCom);
         return;
      }
      lookahead = *(pJxCom->pWorkBuf+1);
      if (lookahead == EQ
      ||  lookahead == GT
      ||  lookahead == Apos
      ||  lookahead == Quot) {
         CheckBufSize(pJxCom);
         pJxCom->Data[pJxCom->DataIx++] = c;
         pJxCom->Data[pJxCom->DataIx]   = '\0';
         return;
      }

      if (lookahead == Slash
      ||  lookahead == Exclmark
      ||  lookahead > Blank      ) {
         pJxCom->State = XML_DETERMIN_TAG_TYPE;
         if (pJxCom->pName == pJxCom->StartName) {
             if (pJxCom->DataIx > 0) {
                pJxCom->pNodeWorkRoot->Value = memAlloc (pJxCom->DataIx + 1) ;
                jx_XmlDecode( pJxCom->pNodeWorkRoot->Value  , pJxCom->Data , pJxCom->DataIx + 1);
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
/* ---------------------------------------------------------------------------
   --------------------------------------------------------------------------- */
static void jx_AttrAppendValue  (PJXCOM pJxCom)
{
   PXMLATTR pAttr;
   UCHAR c = *pJxCom->pWorkBuf;

/* Find wich kind of quote  */
   if (pJxCom->fnyt == '\0') {
      if (c <= Blank) {
         return;
      }
      if (c == Apos || c== Quot) {
         pJxCom->fnyt = c;
      }
      return;
   }
/* End of value */
   if (c == pJxCom->fnyt) {
      pJxCom->fnyt = '\0';
      if (pJxCom->DataIx > 0) {
         pAttr =  *pJxCom->pAttr;
         if(pAttr==NULL) {
            jx_SetMessage( "Invalid attribute termination at (%d:%d)", pJxCom->LineCount, pJxCom->ColCount);
            pJxCom->State = XML_EXIT_ERROR;
            return;
         }
         pAttr->Value = memAlloc (pJxCom->DataIx + 1) ;
         jx_XmlDecode(pAttr->Value   , pJxCom->Data , pJxCom->DataIx + 1);
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
BOOL jx_ParseXml (PJXCOM pJxCom)
{
   UCHAR  c;
   PUCHAR p;
   BOOL  debug = FALSE;
   dbgStep=0;

   for(;;) {
      p = jx_GetChar(pJxCom);
      c = *p;
      switch (pJxCom->State) {
         case XML_FIND_START_TOKEN:
            if (c == LT ) {
              pJxCom->State = XML_DETERMIN_TAG_TYPE;
            }
            break;

         case XML_DETERMIN_TAG_TYPE:

            if (BeginsWith(p , Remark  )) {  // the "!--"
              int commentIx =0;
              do {
                 p = jx_GetChar(pJxCom);
                 if (commentIx < COMMENT_SIZE -1) {
                   pJxCom->Comment[commentIx++] = *p;
                 }
              } while (! BeginsWith (p , EndRemark ) && pJxCom->State != XML_EXIT);  // EndRemark "-->"
              pJxCom->Comment[commentIx-1] = '\0';
              pJxCom->State = XML_FIND_END_TOKEN;
            } else if (BeginsWith(p , DocType  )) {  // the "!DOCTYPE"
              pJxCom->State = XML_FIND_END_TOKEN;
            } else if (c == Question) {  // the ?
              pJxCom->State = XML_FIND_END_TOKEN;
            } else if (c == Slash) {   //  the /
              pJxCom->State = XML_BUILD_NAME;
              pJxCom->pNameIx = &pJxCom->EndNameIx;
              pJxCom->pName   = pJxCom->EndName;
             *pJxCom->pNameIx = 0;

            } else {
              pJxCom->State = XML_BUILD_NAME;
              pJxCom->pNameIx = &pJxCom->StartNameIx;
              pJxCom->pName   = pJxCom->StartName;
             *pJxCom->pNameIx = 0;
              jx_AppendName (pJxCom);
            }
            break;

         case XML_BUILD_NAME:
            jx_AppendName (pJxCom);
            break;

         case XML_ATTR_NAME:
            jx_AttrAppendName(pJxCom);
            break;

         case XML_ATTR_VALUE:
            jx_AttrAppendValue(pJxCom);
            break;

         case XML_COLLECT_DATA:
            jx_AppendData (pJxCom);
            break;

         case XML_FIND_END_TOKEN:
            if (c == GT ) {
              pJxCom->State = XML_FIND_START_TOKEN;
            }
            break;

         case XML_EXIT:
            if (debug) {
               jx_Dump(pJxCom->pNodeRoot);
            }
            // printf("\ndbgStep:%d\n" , dbgStep);
            // getchar();

            if (pJxCom->UseIconv) iconv_close(pJxCom->Iconv );
            memFree(&pJxCom->Data);
            fcloseAndSetNull(&pJxCom->File);
            if (pJxCom->Level == 0) {
               return false;
            } else {
               pJxCom->State = XML_EXIT_ERROR;
               if (pJxCom->FileName) {
                  jx_SetMessage( "Unexpected end of file %s", pJxCom->FileName);
               } else {
                  jx_SetMessage( "Unexpected end of inputstream");
               }
               return true;
            }

         case XML_EXIT_ERROR:
            if (pJxCom->UseIconv) iconv_close(pJxCom->Iconv );
            memFree(&pJxCom->Data);
            fcloseAndSetNull(&pJxCom->File);
            return true;
      }
   }
}

