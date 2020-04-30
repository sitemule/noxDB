/* SYSIFCOPT(*IFSIO) TERASPACE(*YES *TSIFC) STGMDL(*SNGLVL) */
/* ------------------------------------------------------------- *
 * Company . . . : System & Method A/S                           *
 * Design  . . . : Niels Liisberg                                *
 * Function  . . : NOX - main service program API exports        *
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
#include "parms.h"
#include "rtvsysval.h"
#include "utl100.h"
#include "mem001.h"
#include "varchar.h"
#include "streamer.h"
#include "jsonxml.h"

// Prototypes --
//PJXNODE jx_ParseString(PUCHAR Buf, PUCHAR pOptions);

// Global
UCHAR jxMessage[512];
BOOL  jxError = false;



// Unit global
UCHAR Remark   [4];  // !--
UCHAR DocType  [9];  // !DOCTYPE
UCHAR EndRemark[4];  // -->
UCHAR SlashGT  [3];  // />
UCHAR BraBraGT [4];  // ]]>
UCHAR Cdata    [10]; // <![CDATA[

UCHAR Apos       =  '\'';
UCHAR Quot       =  '\"';
UCHAR Question   =  '?' ;
UCHAR EQ         =  '=' ;
UCHAR GT         =  '>' ;
UCHAR LT         =  '<' ;
UCHAR Underscore =  '_' ;
UCHAR Colon      =  ':' ;
UCHAR Dot        =  '.' ;
UCHAR Slash      =  '/' ;
UCHAR Exclmark   =  '!' ;
UCHAR BackSlash  =  '\\';
UCHAR Masterspace=  '@' ;
UCHAR BraBeg     =  '[' ;
UCHAR BraEnd     =  ']' ;
UCHAR CurBeg     =  '{' ;
UCHAR CurEnd     =  '}' ;
UCHAR Minus      =  '-' ;
UCHAR Blank      =  ' ' ;
UCHAR Amp        =  '&' ;
UCHAR Hash       =  '#' ;
UCHAR CR         =  0x25;

UCHAR jobSlash       ;
UCHAR jobBackSlash   ;
UCHAR jobMasterspace ;
UCHAR jobBraBeg      ;
UCHAR jobBraEnd      ;
UCHAR jobCurBeg      ;
UCHAR jobCurEnd      ;
UCHAR jobQuot  ;
UCHAR jobApos  ;


int   InputCcsid = 0, OutputCcsid = 0;
//  BOOL  skipBlanks = TRUE;
BOOL  doTrim;
UCHAR delimiters [11] = {'/', '\\', '@', '[', ']', ' ', '.' , '{' , '}', '\'', '\"' };

UCHAR  e2aTbl[256];
UCHAR  a2eTbl[256];
PJXCOM pJxCom;
BOOL   debugger = false;
UCHAR  jx_DecPoint = '.';
iconv_t xlateEto1208;
iconv_t xlate1208toE;



/* --------------------------------------------------------------------------- */
void jx_SetMessage (PUCHAR Ctlstr , ... )
{
   va_list arg_ptr;
   if (*jxMessage > ' ') return; // Already made

   // Build a temp string with the formated data  */
   va_start(arg_ptr, Ctlstr);
   vsprintf(jxMessage, Ctlstr, arg_ptr);
   va_end(arg_ptr);
}
// ---------------------------------------------------------------------------
void  freeNodeValue(PJXNODE pNode)
{
   if (pNode->type != POINTER_VALUE) {
      memFree(&pNode->Value );
   }
}
/* ------------------------------------------------------------- */
//void dummy01(){}
/* ------------------------------------------------------------- */
PJXNODE jx_traceNode (PUCHAR text, PJXNODE pNode)
{
  static int i;
  UCHAR filename [128];

  if (debugger ==0)  return pNode;

  if (debugger == 1) {
     sprintf(filename, "/tmp/jsonxml-%05.5d.json" , i ++);
     jx_WriteJsonStmf (pNode, filename , 1208, OFF, NULL);
  } else if (debugger == 2) {
     UCHAR temp [65536];
     int l = jx_AsJsonTextMem (pNode , temp , sizeof(temp));
     temp [l] = 0;
     puts (text);
     puts (temp);
     puts ("\n");
  }
  return pNode;
}

/* --------------------------------------------------------------------------- */
void jx_SetDecPoint(PUCHAR p)
{
   jx_DecPoint = *p;
}
/* --------------------------------------------------------------------------- */
FIXEDDEC jx_Num (PUCHAR in)
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
      } else if (c == jx_DecPoint) {
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
        *(p++) = a2eTbl[n];
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

// ---------------------------------------------------------------------------
static void freeAttrList (PXMLATTR pAttr)
{
   PXMLATTR pAttrTemp, pAttrNext;

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
void jx_NodeFreeNodeOnly(PJXNODE pNode)
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
static void jx_NodeFree(PJXNODE pNode)
{
   SegmentNodeDelete(pNode);
   jx_NodeFreeNodeOnly(pNode);
}
/* --------------------------------------------------------------------------- */
void jx_NodeRename(PJXNODE pNode, PUCHAR name)
{
   if (pNode == NULL) return;

   memFree(&pNode->Name);
   pNode->Name = memStrDup(name);
}
//  --------------------------------------------------------------------------- */
PUCHAR nodevalue  (PJXNODE p)
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
   return jx_Num(s);
}
// ---------------------------------------------------------------------------
BOOL isNumberNodeStrict (PJXNODE node)
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
// ---------------------------------------------------------------------------
BOOL isNumberNodeLoose  (PJXNODE node)
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
// ---------------------------------------------------------------------------
LGL jx_IsLiteral (PJXNODE node)
{
  BOOL isString = (
     node
     &&  node->isLiteral == false
     &&  node->Value
  );
  return isString ?  OFF:ON ;
}
/* ---------------------------------------------------------------------------
   use simple bouble-sort to sort an array by keyvalues
   --------------------------------------------------------------------------- */
PJXNODE jx_ArraySort(PJXNODE pNode, PUCHAR fieldsP, USHORT optionsP)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PUCHAR  fields = (pParms->OpDescList->NbrOfParms >= 2) ? fieldsP : "";
   BOOL    useLocale =  (pParms->OpDescList->NbrOfParms >= 3) ? optionsP & 1: FALSE;
   PJXNODE pNodeNext, pNode1, pNode2, pCompNode1, pCompNode2 ;
   BOOL    bubles;
   UCHAR   keys [256][256];
   BOOL    descending [256];
   int     kix, kx, comp ;

   // Set function pointers for callback
   double (* getnumberval)(PUCHAR s)  =  useLocale ? num2float   : atof;
   BOOL   (* isNumberNode)(PJXNODE n) =  useLocale ? isNumberNodeLoose : isNumberNodeStrict;

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
      descending[kix] = BeginsWith(descStr , "desc");
   }

   do {
      bubles = false;
      pNode1  = pNode->pNodeChildHead;
      if (pNode1 == NULL ) return;
      pNode2  = pNode1->pNodeSibling;

      while (pNode2) {
         for(kx = 0; kx < kix ; kx++)  {
            PUCHAR v1, v2;
            pCompNode1 = jx_GetNode  (pNode1 ,keys[kx]);
            pCompNode2 = jx_GetNode  (pNode2 ,keys[kx]);
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
                  jx_SwapNodes(&pNode1, &pNode2);
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
/* ---------------------------------------------------------------------------
   --------------------------------------------------------------------------- */
void jx_FreeSiblings(PJXNODE pNode)
{
   PJXNODE pNodeNext;

   while (pNode) {
      pNodeNext=pNode->pNodeSibling;
      jx_FreeChildren (pNode);
      jx_NodeFree(pNode);
      pNode=pNodeNext;
   }
}
// -------------------------------------------------------------
void jx_FreeChildren (PJXNODE pNode)
{
   jx_FreeSiblings(pNode->pNodeChildHead);
   pNode->pNodeChildHead = NULL;
   pNode->pNodeChildTail = NULL;
   pNode->Count = 0;
}
// -------------------------------------------------------------
void jx_DumpNodeList (PJXNODE pNodeTemp)
{
   PJXNODE  pNodeNext;
   PXMLATTR pAttrTemp;

   while (pNodeTemp) {
      PJXNODE p;
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
         printf("\n   Attribute: %s = %s" , pAttrTemp->Name == NULL ? "" : pAttrTemp->Name,
                                            pAttrTemp->Value== NULL ? "" : pAttrTemp->Value);

      }
      jx_DumpNodeList(pNodeTemp->pNodeChildHead);
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
ULONG jx_NodeCheckSum (PJXNODE pNode)
{
   PJXNODE  pNodeNext;
   PXMLATTR pAttrTemp;
   ULONG    sum =0;

   while (pNode) {

      sum += sumString (pNode->Name);
      sum += sumString (pNode->Value);

      for (pAttrTemp = pNode->pAttrList; pAttrTemp ; pAttrTemp = pAttrTemp->pAttrSibling){
         sum += sumString (pAttrTemp->Name);
         sum += sumString (pAttrTemp->Value);

      }
      sum += jx_NodeCheckSum (pNode->pNodeChildHead);
      pNode = pNode->pNodeSibling;
   }
   return sum;
}
/* ---------------------------------------------------------------------------
   --------------------------------------------------------------------------- */
#pragma convert(1252)
static void jx_WriteXmlStmfNodeList (FILE * f, iconv_t * pIconv ,PJXNODE pNode)
{
   PJXNODE  pNodeTemp, pNodeNext;
   PXMLATTR pAttrTemp;
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
          jx_WriteXmlStmfNodeList (f, pIconv, pNode->pNodeChildHead);
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
/* ---------------------------------------------------------------------------
   --------------------------------------------------------------------------- */
LONG jx_AsXmlTextMem (PJXNODE pNode, PUCHAR buf)
{
   PJXNODE    pNodeTemp, pNodeNext;
   PXMLATTR   pAttrTemp;
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
          temp += jx_AsXmlTextMem (pNode->pNodeChildHead , temp);
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
VARCHAR jx_AsXmlText (PJXNODE pNode)
{
   VARCHAR  res;
   res.Length = jx_AsXmlTextMem (pNode , res.String);
   return res;
}
/* ---------------------------------------------------------------------------
   Traverse up the tree and build the name  like: "root/tree/node"
   --------------------------------------------------------------------------- */
VARCHAR jx_GetNodeNameAsPath (PJXNODE pNode, UCHAR Delimiter)
{

   PJXNODE  p;
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

         len = strlen(p->Name);
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
// CSV Helpers
/* --------------------------------------------------------------------------- */
void csvReplaceDecpoint ( PUCHAR out , PUCHAR in , UCHAR decpoint)
{
    for(;*in; in++) {
       *out++ = (*in == '.') ? decpoint: *in;
    }
    *out = '\0';
}
/* --------------------------------------------------------------------------- */
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
/* ---------------------------------------------------------------------------
   --------------------------------------------------------------------------- */
void jx_WriteCsvStmf (PJXNODE pNode, PUCHAR FileName, int Ccsid, LGL trimOut, PJXNODE options)
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
      PJXNODE  pOptions  = jx_ParseString((PUCHAR) options , ""); // When already a object: simply returns that
      comma    = *jx_GetValuePtr    (pOptions , "delimiter" , &comma );
      decpoint = *jx_GetValuePtr    (pOptions , "decPoint"  , &decpoint );
      headers  = (ON == jx_IsTrue   (pOptions , "headers"));
      if (pOptions != options) jx_Close(&pOptions); // It was already a josn object , then don't close
   }

   pjWrite->buf    = wTemp;
   pjWrite->iconv  = OpenXlate(OutputCcsid , Ccsid );

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
      PJXNODE pHead  = pNode->pNodeChildHead;
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

      PJXNODE pCol  = pNode->pNodeChildHead;


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
/* --------------------------------------------------------------------------- */
SHORT jx_GetNodeType (PJXNODE pNode)
{
   return (pNode) ? pNode->type : 0;
}
/* --------------------------------------------------------------------------- */
void  jx_CloneNodeFormat (PJXNODE pNode, PJXNODE pSource, PJWRITE pjWrite, PUCHAR name, PJXNODE pParent)
{
   PJXNODE  p;
   UCHAR tempname[256];
   PJXNODE pCloneNode;
   int ix =0;

   while (pNode) {

      if (pParent && pParent->type == ARRAY) {
        sprintf(tempname,"%s[%d]", name , ix++  );
      } else if (pSource->Name && *pSource->Name){
        sprintf(tempname,"%s/%s", name , pSource->Name);
      } else {
        strcpy (tempname,name );
      }

      pCloneNode = jx_GetNode  (pSource, tempname);
      pNode->lineNo = pCloneNode ? pCloneNode->lineNo:0;
/*
      if (pNode->Name && *pNode->Name && pNode->type != ARRAY) {
        sprintf(tempname,"%s/%s%s", name , pNode->Name, (pParent->type == ARRAY)? "[0]":"");
        pCloneNode = jx_GetNode  (pSource, tempname);
        pNode->lineNo = pCloneNode ? pCloneNode->lineNo:0;
      } else {
        sprintf(tempname,"%s" , name );
      }
*/

      if (pNode->pNodeChildHead) {
        pjWrite->level ++;
        jx_CloneNodeFormat (pNode->pNodeChildHead, pSource, pjWrite, tempname , pNode);
        pjWrite->level --;
      }

      pNode = pNode->pNodeSibling;
   }

}
/* ---------------------------------------------------------------------------
   --------------------------------------------------------------------------- */
void jx_NodeCloneAndReplace (PJXNODE pDest , PJXNODE pSource)
{
    PJXNODE  pNewNode = jx_NodeClone (pSource);
    jx_NodeMoveAndReplace (pDest, pNewNode);

}
/* ---------------------------------------------------------------------------
   This works great, have to go back and update the "cloneFormat" logic to do similar
   --------------------------------------------------------------------------- */
void  jx_MergeList (PJXNODE pDest, PJXNODE pSource, PJWRITE pjWrite, PUCHAR name, PJXNODE pParent, MERGEOPTION merge)
{
   PJXNODE  p;
   UCHAR tempname[256];
   PJXNODE pDestNode , pEdt ;
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

        pDestNode = jx_GetNode  (pDest, relName);
        if (pDestNode != NULL) {
           if (merge == MO_MERGE_REPLACE || merge == MO_MERGE_MATCH) {
              jx_NodeSet(pDestNode , pSource->Value);
           }
        } else {
           if (merge == MO_MERGE_REPLACE || merge == MO_MERGE_NEW ) {
              pEdt = jx_SetValueByName  (pDest , relName, pSource->Value, pSource->type);
              pEdt->isLiteral = pSource->isLiteral;
           }
        }
      }

      if (pSource->pNodeChildHead) {
        pjWrite->level ++;
        jx_MergeList (pDest , pSource->pNodeChildHead,pjWrite, tempname , pSource, merge  );
        pjWrite->level --;
      }
      // Merging only take the first occurent where the object object names has a match
      // pSource = (pjWrite->level == 0) ? NULL: pSource->pNodeSibling;
      pSource = pSource->pNodeSibling;
   }
}
/* --------------------------------------------------------------------------- */
PJXNODE  jx_InsertByName (PJXNODE pDest , PUCHAR name , PJXNODE pSource )
{
    PJXNODE pNode;

    if ( pSource->type == OBJECT || pSource->type == ARRAY ) {
       pNode  =  jx_NodeCopy (pDest, pSource , RL_LAST_CHILD);
       pNode->Name = memStrDup(name);
    } else {
       pNode  = jx_SetValueByName  (pDest , name , pSource->Value , pSource->type);
       pNode->isLiteral = pSource->isLiteral;
    }
    return pNode;
}
/* --------------------------------------------------------------------------- */
PJXNODE  jx_CopyValue (PJXNODE pDest , PUCHAR destName , PJXNODE pSource , PUCHAR sourceName)
{
    PJXNODE pRes;

    pSource = jx_GetNode  (pSource  , sourceName );
    if (pSource == NULL) return NULL;


    pDest = jx_GetOrCreateNode (pDest, destName);
    if (pDest  == NULL) return NULL;

    if ( pSource->type == OBJECT || pSource->type == ARRAY ) {
       jx_NodeCloneAndReplace (pDest  , pSource);

    } else {
       jx_NodeSet (pDest ,pSource->Value);
       pDest->isLiteral = pSource->isLiteral;
    }

    return pDest ;
}
/* --------------------------------------------------------------------------- */
static void  jx_MergeObj  (PJXNODE pDest, PJXNODE pSource, PJWRITE pjWrite, MERGEOPTION merge)
{
   PJXNODE  p;
   UCHAR tempname[256];
   PJXNODE pDestNode , pEdt ;
   int ix =0;

   while (pSource) {

      if (pSource->Name && *pSource->Name){
        pDestNode = jx_GetNode  (pDest, pSource->Name);
        if (pDestNode) {
           if (merge == MO_MERGE_REPLACE) {
              jx_NodeDelete (pDestNode);
              jx_InsertByName (pDest , pSource->Name , pSource );
           } else {
              if (pSource->pNodeChildHead && pSource->type == OBJECT) {
                 jx_MergeObj  (pDestNode ,  pSource->pNodeChildHead , pjWrite, merge);
              }
           }
        } else {
           jx_InsertByName (pDest , pSource->Name , pSource );
        }
      } else {
        if (pSource->pNodeChildHead ) {
           // PJXNODE pNewDest = pDest->pNodeChildHead ?  pDest->pNodeChildHead : pDest; // Handle roots !! TODO !!
           PJXNODE pNewDest = pDest;
           jx_MergeObj  (pNewDest,  pSource->pNodeChildHead , pjWrite, merge);
        }
      }
      pSource = pSource->pNodeSibling;
   }
}
/* ---------------------------------------------------------------------------
   --------------------------------------------------------------------------- */
void  jx_MergeObjects (PJXNODE pDest, PJXNODE pSource , MERGEOPTION merge)
{
   PJXNODE  p;
   UCHAR tempname[256];
   PJXNODE pDestNode , pEdt ;
   PJXNODE pSourceNode;
   int ix =0;

   if (pDest ==NULL ||pSource == NULL) return;

   pSourceNode =  pSource->pNodeChildHead;
   while (pSourceNode) {

      pDestNode = jx_GetNode  (pDest, pSourceNode->Name);
      if (pDestNode) {
         if (merge == MO_MERGE_REPLACE) {
            jx_NodeDelete (pDestNode);
            jx_InsertByName (pDest , pSourceNode->Name , pSourceNode );
         } else {
            if (pSourceNode->type == OBJECT) {
               jx_MergeObjects  (pDestNode ,  pSourceNode , merge);
            }
         }
      } else {
         jx_InsertByName (pDest , pSourceNode->Name , pSourceNode );
      }
      pSourceNode = pSourceNode->pNodeSibling;
   }
}
/* ---------------------------------------------------------------------------
   Obsolete- use MergeObjects
   --------------------------------------------------------------------------- */
void jx_NodeMerge(PJXNODE pDest, PJXNODE pSource, SHORT replace)
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
  jx_MergeObj (pDest, pSource, &jWrite, merge);
}
/* --------------------------------------------------------------------------- */
void  jx_LoadRecursiveList (PJXNODE pNode, PJXITERATOR pIter, BOOL first)
{
   while (pNode) {
      if (pIter->length >= pIter->size) {
        pIter->size += 256;
        pIter->list = realloc (pIter->list , sizeof(PJXNODE) * pIter->size);
      }
      pIter->list [pIter->length] = pNode;
      pIter->length++;
      jx_LoadRecursiveList (pNode->pNodeChildHead , pIter, FALSE);
      pNode = first ? NULL : pNode->pNodeSibling;
   }
}
/* ---------------------------------------------------------------------------
   Delete nodes which are NULL
   --------------------------------------------------------------------------- */
void  jx_NodeSanitize(PJXNODE pNode)
{

   while (pNode) {
      PJXNODE pNext = pNode->pNodeSibling;
      if (pNode->Value != NULL && strcmp (pNode->Value , "null") == 0
      ||  pNode->Value == NULL && pNode->type == VALUE) {
         jx_NodeDelete(pNode);
      } else {
         jx_NodeSanitize(pNode->pNodeChildHead);
      }
      pNode = pNext;
   }
}
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

   if (pNode->pNodeParent == NULL
   &&  pNode->Name       == NULL) {
     if (pNode->pNodeChildHead != NULL) {
       // TODO!! This root Nodeens empty in some case; the first child is actually the root
       pNode = pNode->pNodeChildHead;
     }
   }
   if (pNode == NULL) return;

   sprintf(mode , "wb,codepage=%d", Ccsid);
   f = fopen ( strTrim(FileName) , mode );
   if (f == NULL) return;

   Iconv = OpenXlate(OutputCcsid , Ccsid );


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
   jx_WriteXmlStmfNodeList (f , &Iconv , pNode);
   fclose(f);
   iconv_close(Iconv);
}
/* ---------------------------------------------------------------------------
   --------------------------------------------------------------------------- */
void jx_Dump(PJXNODE  pNode)
{
   if (pNode == NULL) {
      return;
   }

   printf("%s\n" , jxMessage) ;
   jx_DumpNodeList(pNode);
   printf("\n") ;
}
// ---------------------------------------------------------------------------
PUCHAR detectEncoding(PJXCOM pJxCom, PUCHAR pIn)
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
        InputCcsid = 277;
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
        if (*p == jobBraBeg || *p == jobCurBeg || *p == jobQuot || *p == jobApos
        ||  isdigit(*p)
        ||  BeginsWith(p , "true" )
        ||  BeginsWith(p , "false")
        ||  BeginsWith(p , "null" )) {
           pJxCom->isJson = TRUE;
           InputCcsid = 0;
           done = TRUE;
           break;
        }
    }
  }

  // Bump back to rigt after "<" or what made it stop
  p--;
  if (p && pJxCom->isJson) {
    /*  .... Avoid to use the ccsid from the file - this can be anything ....
    if (InputCcsid == 0 && pJxCom->File && lstat(pJxCom->FileName, &statbuf) == 0) {
       InputCcsid = statbuf.st_ccsid;
    } else if (isAscii && InputCcsid == 0) {
       InputCcsid = 1208;
    } .... */
    // Assume 1208 for any ascii JSON and set with EBCDIC ccsid on the file
    if (isAscii && InputCcsid < 900) {
       InputCcsid = 1208;
    }
  } else if (p && isXml && ! isAscii) {
      InputCcsid = 0;  // Is EBCDIC
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
    jx_SetMessage( "Unsupported /unknown charset or encoding for file %s ", pJxCom->FileName);
    pJxCom->State = XML_EXIT_ERROR;
    return outbuf;
  }

  // Convert const to current ccsid
  initconst( OutputCcsid);  // Init const freom 1252 to current output ccsid

  pJxCom->UseIconv = (InputCcsid != OutputCcsid);

  if ( pJxCom->UseIconv) {
    pJxCom->Iconv = OpenXlate(InputCcsid  , OutputCcsid);
  }

  // printf("\n iccs: %d, occs: 5d\n ", InputCcsid  , OutputCcsid);
  return outbuf;
}
// ---------------------------------------------------------------------------
static PJXNODE  SelectParser (PJXCOM pJxCom)
{
   PJXNODE pRoot;
   CheckBufSize(pJxCom);
   pJxCom->pNodeRoot = pRoot = NewNode (NULL, NULL, OBJECT);
   pJxCom->pFileBuf = NULL;
   pJxCom->State = XML_FIND_START_TOKEN;
   pJxCom->LineCount = 1;
   pJxCom->pNodeWorkRoot = pJxCom->pNodeRoot;
   pJxCom->Comment = memAlloc(COMMENT_SIZE);
   * pJxCom->Comment = '\0';

   if (pJxCom->isJson) {
      jxError = jx_ParseJson (pJxCom);
   } else {
      jxError = jx_ParseXml (pJxCom);
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
void jx_NodeAppendChild(PJXNODE pRoot, PJXNODE pNewChild)
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
static PJXNODE previousSibling(PJXNODE p)
{
  PJXNODE t;
  if (p->pNodeParent == NULL) return NULL; // I am the root
  t = p->pNodeParent->pNodeChildHead;
  while (t) {
    if (t->pNodeSibling == p) return(t);
    t = t->pNodeSibling;
  }
  return ( NULL);
}

// ---------------------------------------------------------------------------
static PJXNODE DupNode(PJXNODE pSource)
{
   PXMLATTR pAttrTemp;
   PJXNODE  pNode;

   // A copy of null is null
   if (pSource == NULL) return NULL;

   // Dupling a nodex which is a string simply kicks in the parser
   if (pSource->signature != NODESIG) {
      pNode = jx_ParseString((PUCHAR) pSource, "");
      return pNode;
   }

   pNode = (PJXNODE) memAlloc (sizeof(*pNode));
   memcpy  (pNode , pSource, sizeof(*pNode));

   SegmentNodeAdd(pNode);

   pNode->pAttrList  = NULL;
   pNode->pNodeParent = pNode->pNodeChildHead = pNode->pNodeChildTail = pNode->pNodeSibling = NULL;
   pNode->Name  = memStrDup(pSource->Name);
   pNode->Value = memStrDup(pSource->Value);

   for (pAttrTemp = pSource->pAttrList; pAttrTemp ; pAttrTemp = pAttrTemp->pAttrSibling){
      PXMLATTR  pPrev, pAttr = (PXMLATTR) memAlloc (sizeof(*pAttr));
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
void jx_NodeAddChildTail( PJXNODE pRoot, PJXNODE pChild)
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
PJXNODE jx_NodeUnlink  (PJXNODE  pNode)
{
  PJXNODE pNewRoot, pPrevNode, pParent;

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
void jx_SwapNodes (PJXNODE * ppNode1, PJXNODE * ppNode2)
{
  PJXNODE pNode1 = *ppNode1  , pNode2 =  * ppNode2;
  PJXNODE pTemp1, pTemp2, pPrevNode, pParent = NULL;

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
PJXNODE jx_NodeMoveInto (PJXNODE  pDest, PUCHAR name , PJXNODE pSource)
{

   PJXNODE  pTempNode;

   if (pDest == pSource
   ||  pDest == NULL) {
     return pDest;
   }

   // If no destination given, then it is actually a replace og the
   // destimnation node - with respect to the memmory locaitons
   if (*name == '\0') {
      jx_NodeMoveAndReplace (pDest , pSource);
      return pDest;
   }

   pSource = jx_NodeUnlink(pSource); // Now I am my own root
   jx_NodeRename(pSource , name);


   pTempNode  = jx_GetNode  (pDest, name );
   if (pTempNode == NULL) {
   // if (pSource->type == VALUE) {
   //    jx_NodeSet (pDest , pSource->Value);
   //    jx_NodeDelete (pSource);
   //    return pDest;
   // }
      jx_NodeAddChildTail (pDest, pSource);

      // Since we have a name - we must be an object
      // required if we were a value i.e. produce by
      // locateOrCreate / getorCreate or we were a value by ie. setStr
      if (pDest->type != ARRAY ) {
         pDest->type = OBJECT;
      }
      freeNodeValue(pDest);

   } else {
      // replace, by adding a new with same name and the remove the original. Will keep the same position
      jx_NodeAddSiblingAfter(pTempNode, pSource);
      jx_NodeDelete (pTempNode);
   }

   return pSource;

}
// ---------------------------------------------------------------------------
void jx_NodeMoveAndReplace (PJXNODE  pDest, PJXNODE pSource)
{

   if (pDest == pSource
   ||  pDest == NULL) {
     return;
   }

   pSource = jx_NodeUnlink(pSource);      // Now I am my own root
   jx_NodeRename(pSource , pDest->Name);  // I need the same name of the node i gonna replace

   // replace, by adding a new with same name and the remove the original. Will keep the same position
   jx_NodeAddSiblingAfter(pDest, pSource);
   jx_NodeDelete (pDest);
}
// ---------------------------------------------------------------------------
void jx_NodeAddChildHead( PJXNODE pRoot, PJXNODE pChild)
{
   pChild->pNodeParent = pRoot;

   if (pChild->pNodeParent->type == ARRAY) {
     pChild->pNodeParent->Count ++;
   }

   if (pChild->pNodeParent->pNodeChildHead == NULL) {
      pChild->pNodeParent->pNodeChildHead = pChild;
      pChild->pNodeParent->pNodeChildTail = pChild;
   } else {
      PJXNODE pTemp;
      pTemp = pChild->pNodeParent->pNodeChildHead;
      pChild->pNodeParent->pNodeChildHead = pChild;
      pChild->pNodeSibling = pTemp;
//    pChild->Seq = pChild->pNodeParent->pNodeChildTail->Seq + 1; // Increment Sibling number to do ... renumber
   }
}
// ---------------------------------------------------------------------------
void jx_NodeAddSiblingBefore( PJXNODE pRef, PJXNODE pSibling)
{
    PJXNODE pPrev = previousSibling(pRef);

    if (pPrev == NULL) {
        jx_NodeAddChildHead( pRef->pNodeParent, pSibling);
        return;
    }
    pSibling->pNodeParent  = pRef->pNodeParent;
    pSibling->pNodeSibling = pRef;
    pPrev->pNodeSibling    = pSibling;

//  to do ... renumber seq.

}
// ---------------------------------------------------------------------------
void jx_NodeAddSiblingAfter( PJXNODE pRef, PJXNODE pSibling)
{
    if (pRef->pNodeSibling == NULL) {
        jx_NodeAddChildTail ( pRef->pNodeParent, pSibling);
        return;
    }
    pSibling->pNodeParent  = pRef->pNodeParent;
    pSibling->pNodeSibling = pRef->pNodeSibling;
    pRef->pNodeSibling     = pSibling;

//    to do ... renumber seq.
}
// ---------------------------------------------------------------------------
void AddNode(PJXNODE pDest, PJXNODE pSource, REFLOC refloc)
{
   if (pDest   == NULL) return;

   switch ( refloc) {
   case RL_LAST_CHILD:
     jx_NodeAddChildTail (pDest, pSource);
     break;
   case RL_FIRST_CHILD:
     jx_NodeAddChildHead (pDest, pSource);
     break;
   case RL_BEFORE_SIBLING:
     jx_NodeAddSiblingBefore(pDest, pSource);
     break;
   case RL_AFTER_SIBLING:
     jx_NodeAddSiblingAfter(pDest, pSource);
     break;
   }
}
// ---------------------------------------------------------------------------
PJXNODE jx_NodeClone  (PJXNODE pSource)
{
   PJXNODE  pNewNode, pNext;

   if (pSource == NULL) return NULL;

   pNewNode = DupNode(pSource);

   pNext = pSource->pNodeChildHead;
   while (pNext) {
      PJXNODE  pNewChild = jx_NodeClone (pNext);
      jx_NodeAddChildTail (pNewNode , pNewChild);
      pNext=pNext->pNodeSibling;
   }
   return pNewNode;
}
// ---------------------------------------------------------------------------
PJXNODE jx_NodeCopy (PJXNODE pDest, PJXNODE pSource, REFLOC refloc)
{
   PJXNODE  pNewNode, pNode;

   if (pDest   == NULL) return;
   if (pSource == NULL) return;

   pNewNode = jx_NodeClone  (pSource);
   AddNode(pDest, pNewNode, refloc);
   return pNewNode;

}
// ---------------------------------------------------------------------------
PJXNODE NewNode  (PUCHAR Name , PUCHAR Value, NODETYPE type)
{
   PJXNODE  pNode;
   static int id = 0;

   pNode = (PJXNODE) memAlloc (sizeof(*pNode));
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
   pNode->Handle = id++;
   pNode->Value  = memStrDup(Value);
   SegmentNodeAdd(pNode);
   return pNode;
}
// ---------------------------------------------------------------------------
PJXNODE jx_NodeAdd (PJXNODE pDest, REFLOC refloc, PUCHAR Name , PUCHAR Value, NODETYPE type)
{
   PJXNODE  pNewNode  = NewNode  (Name , Value, type);
   AddNode(pDest, pNewNode, refloc);
   return pNewNode;
}
// ---------------------------------------------------------------------------
PJXNODE jx_NewObject (PJXNODE pDest)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PJXNODE pParent = pDest == NULL || pParms->OpDescList->NbrOfParms == 0 ? NULL:pDest;

   // If we just produce JSON with out having parsed anything
   if (pDest == NULL) {
      initconst(0);  // Init CCSID for current job
   }

   return jx_NodeAdd (pParent, RL_LAST_CHILD, NULL  , NULL , OBJECT);
/*
   if (pDest == NULL || pParms->OpDescList->NbrOfParms == 0) {
     return ( PJXNODE) jx_ParseString("{}","");
   } else {
     return jx_NodeAdd (pDest, RL_LAST_CHILD, NULL  , NULL , OBJECT);
   }
*/
}
// ---------------------------------------------------------------------------
PJXNODE jx_NewArray (PJXNODE pDest)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PJXNODE pParent = pDest == NULL || pParms->OpDescList->NbrOfParms == 0 ? NULL:pDest;

   // If we just produce JSON with out having parsed anything
   if (pDest == NULL) {
      initconst(0);  // Init CCSID for current job
   }

   return jx_NodeAdd (pParent, RL_LAST_CHILD, NULL  , NULL , ARRAY);

/*
   // from "C" return null in number of parms
   if (pDest == NULL || pParms->OpDescList->NbrOfParms == 0) {
     return ( PJXNODE) jx_ParseString("[]","");
   } else {
     return jx_NodeAdd (pDest, RL_LAST_CHILD, NULL  , NULL , ARRAY);
   }
*/
}
// ---------------------------------------------------------------------------
void jx_NodeSet (PJXNODE pNode , PUCHAR Value)
{
   if (pNode == NULL) return;

   // Remake me as a value node...
   if (pNode->type != VALUE ) {
       jx_FreeChildren (pNode);
       pNode->type = VALUE;
   }
   freeNodeValue(pNode);

   if (Value) {
     pNode->Value = memStrTrimDup(Value);
   }
}
// ---------------------------------------------------------------------------
void jx_NodeSetAsPointer (PJXNODE pNode , PUCHAR Value)
{
   if (pNode == NULL) return;

   // Remake me as a pointer node node...
   freeNodeValue(pNode);     // If i was a value - - drop it
   jx_FreeChildren (pNode);  // Ensure we are only a value
   pNode->Value     = Value;
   pNode->type      = POINTER_VALUE;
   pNode->isLiteral = true; // no escaping and no conversion
}
// ---------------------------------------------------------------------------
void jx_NodeDelete(PJXNODE pNode)
{
   PJXNODE  pTemp;

   if (pNode == NULL) return;

   jx_NodeUnlink (pNode);
   jx_FreeChildren (pNode);
   jx_NodeFree(pNode);
}

// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
void jx_SetCcsid(int pInputCcsid, int pOutputCcsid)
{
  InputCcsid  = pInputCcsid;
  OutputCcsid = pOutputCcsid;
}
// ---------------------------------------------------------------------------
// delim was originally only 5.
// ---------------------------------------------------------------------------
void jx_SetDelimiters(PJXDELIM pDelim)
{
  PUCHAR delim = (PUCHAR) pDelim;

  // delim was originally only 5.
  memcpy(delimiters , pDelim , 5);
  Slash       = delim [0];
  BackSlash   = delim [1];
  Masterspace = delim [2];
  BraBeg      = delim [3];
  BraEnd      = delim [4];
}
// ---------------------------------------------------------------------------
// New wrapper  - Missing in old "SetDelimiters" - now the string is NULL
// terminated to we can just build more on as we go
// ---------------------------------------------------------------------------
void jx_SetDelimiters2(PJXDELIM pDelim)
{
  int i;
  PUCHAR p = (PUCHAR) pDelim;
  for (i=0; i< sizeof(delimiters) && *p   ; i++,p++) {
     UCHAR c = delimiters [i] = *p;
     switch (i) {
        case 0 : Slash       = c; break;
        case 1 : BackSlash   = c; break;
        case 2 : Masterspace = c; break;
        case 3 : BraBeg      = c; break;
        case 4 : BraEnd      = c; break;
        case 5 : Blank       = c; break;
        case 6 : Dot         = c; break;
        case 7 : CurBeg      = c; break;
        case 8 : CurEnd      = c; break;
        case 9 : Apos        = c; break;
        case 10: Quot        = c; break;
     }
  }
}
// ---------------------------------------------------------------------------
PJXDELIM jx_GetDelimiters(void)
{
  return   (PJXDELIM)   &delimiters;
}
// ---------------------------------------------------------------------------
// Note: Options is depricated ...
// ---------------------------------------------------------------------------
PJXNODE jx_ParseString(PUCHAR Buf, PUCHAR pOptions)
{
   PJXNODE pRoot;
   PJXCOM pJxCom;

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
       return (PJXNODE) Buf;
   }

   jxMessage[0] = '\0';

   pJxCom = memAlloc (sizeof(JXCOM));
   memset(pJxCom , 0, sizeof(JXCOM));

   // Peek the first, tp detect the encoding
   Buf = detectEncoding(pJxCom, Buf);
   if (pJxCom->UseIconv) {
     int inlen = strlen(Buf);
     int templen;
     PUCHAR temp = memAlloc(inlen);

     if (pJxCom->LittleEndian) {
       swapEndian(Buf , inlen);
       templen = xlate(pJxCom, temp , Buf , inlen);
       swapEndian(Buf , inlen);
     } else {
       templen = xlate(pJxCom, temp , Buf , inlen);
     }
     pJxCom->StreamBuf = temp;
     pJxCom->StreamBuf [templen] = '\0';
     pRoot = SelectParser (pJxCom);
     memFree (&temp);

   } else {
     pJxCom->StreamBuf =  Buf;
     pRoot = SelectParser (pJxCom);
   }

   InputCcsid = 0;
   OutputCcsid = 0;
   // DEBUGGER TODO !!!
   #ifdef MEMDEBUG
      printf("\n\nParse String: %p - %-90.90s\n " , pRoot  , tempStr);
      memStat();
   #endif

   return (pRoot);
}
/* ---------------------------------------------------------------------------
   --------------------------------------------------------------------------- */
PJXNODE jx_parseStringCcsid(PUCHAR buf, int ccsid)
{
   PJXNODE pRoot;
   JXDELIM storeDelimiters; 

   storeDelimiters = * jx_GetDelimiters();
   InputCcsid = ccsid;
   jx_setDelimitersByCcsid (ccsid);
   pRoot = jx_ParseString(buf,"");
   jx_SetDelimiters2(&storeDelimiters);
   return pRoot;
}

// ---------------------------------------------------------------------------
/* ----------------------- OLD !!
PJXNODE jx_ParseFile(PUCHAR FileName, PUCHAR pOptions)
{

   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   // from "C" return null in number of parms
   PUCHAR  Options =  (pParms->OpDescList == NULL
                   ||  pParms->OpDescList->NbrOfParms == 0
                   ||  pParms->OpDescList->NbrOfParms >= 2 && pOptions) ? pOptions : "";

   UCHAR buf [128];
   int l;
   PJXNODE pRoot;
   JXDELIM curDelim;
   JXDELIM curCcsidDelim;
   PJXCOM pJxCom ;
   PUCHAR pFirstChar;
   BOOL isJson;
   BOOL overrideCharset = false;

   jxMessage[0] = '\0';
   memset (buf , 0 ,sizeof(buf));

   pJxCom = memAlloc (sizeof(JXCOM));
   memset(pJxCom , 0, sizeof(JXCOM));

   if (BeginsWith(Options , "encoding=")) {
      if (BeginsWith(Options+9 , "utf-8")) {
         InputCcsid = 1208;
         overrideCharset = true;
      } else if (BeginsWith(Options+9 , "windows-1252")) {
         InputCcsid = 1252;
         overrideCharset = true;
      }
   }

   pJxCom->FileName = FileName;
   pJxCom->File = fopen(strTrim(pJxCom->FileName), "rb");

   if (pJxCom->File == NULL) {
      jx_SetMessage( "File %s not open", pJxCom->FileName);
      jxError = true;
      memFree (&pJxCom);
      return NULL;
   }
   l = fread(buf, 1 , sizeof(buf) -1  , pJxCom->File);
   buf[l] = '\0';
   pFirstChar = buf;

   // Skip unicode / utf file type signatur
   if (buf[0] == 0xff && buf[1] == 0xfe) {  // Unicode
     fseek( pJxCom->File , 2, SEEK_SET);
   //InputCcsid = 1200; // Unicode by signature
   }
   else if (buf[0] == 0xef && buf[1] == 0xbb  && buf[2] == 0xbf) { // utf8
     fseek( pJxCom->File , 3, SEEK_SET);
     InputCcsid = 1208;  // UTF-8 By signature
   }
   else {
     fseek( pJxCom->File , 0, SEEK_SET);
   }
   detectEncoding(pJxCom , buf, overrideCharset);

// skipBlanks = NULL != strstr(Options , "skipblanks=no");
   curDelim = *jx_GetDelimiters();
   Xlatestr ((PUCHAR) &curCcsidDelim , "/\\@[] .{}\'\"" , 277 , 0);
   jx_SetDelimiters2(&curCcsidDelim);
   pRoot = SelectParser (pJxCom);
   jx_SetDelimiters2(&curDelim);

   InputCcsid = 0;
   OutputCcsid = 0;

   // DEBUGGER TODO !!!
   #ifdef MEMDEBUG
      printf("\n\nParse File: %p - %-90.90s\n " , pRoot  , FileName);
      memStat();
   #endif

   return (pRoot);
}
**********/
// ---------------------------------------------------------------------------
PJXNODE jx_ParseFile(PUCHAR FileName, PUCHAR pOptions)
{

   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   // from "C" return null in number of parms
   PUCHAR  Options =  (pParms->OpDescList == NULL
                   ||  pParms->OpDescList->NbrOfParms == 0
                   ||  pParms->OpDescList->NbrOfParms >= 2 && pOptions) ? pOptions : "";

   PUCHAR  streamBuf;
   PJXNODE pRoot;
   PUCHAR  pFirstChar;
   LONG    fileSize;
   LONG    len ;
   FILE  * f;
   struct  stat statbuf;


   jxMessage[0] = '\0';

   f  = fopen(strTrim(FileName), "rb");
   if (f  == NULL) {
      jx_SetMessage( "File %s not open", FileName);
      jxError = true;
      return NULL;
   }

   // Get the default input ccsid from the file system ( It might be wrong because it is set to default)
   fstat(fileno(f), &statbuf);
   InputCcsid = statbuf.st_ccsid;

   // Locate end to find the size of the file
   fseek( f , 0L, SEEK_END);
   fileSize = ftell( f );
   fseek( f , 0L, SEEK_SET);

   // read it all
   streamBuf = memAlloc (fileSize+1);
   len = fread(streamBuf, 1 , fileSize  , f );
   fclose(f);

   if (len != fileSize) {
      jx_SetMessage( "File %s was not read", FileName);
      jxError = true;
      memFree (&streamBuf);
      return NULL;
   }

   // make it a string
   streamBuf[len] = '\0';
   pFirstChar = streamBuf;
   
   pRoot = jx_parseStringCcsid(pFirstChar,0);
   memFree (&streamBuf);

   return (pRoot);
}

/* ---------------------------------------------------------------------------
   --------------------------------------------------------------------------- */
void jx_CloneFormat(PJXNODE pNode, PJXNODE pSource)
{
  JWRITE jWrite;
  memset(&jWrite , 0 , sizeof(jWrite));
  if (pSource->signature != NODESIG) {
    PJXNODE pc = jx_ParseFile((PUCHAR) pSource, "");
    jx_CloneNodeFormat(pNode,  pc , &jWrite, "", NULL);
    jx_FreeSiblings(pc);
  } else {
    jx_CloneNodeFormat(pNode, pSource, &jWrite, "", NULL);
  }
}
/* --------------------------------------------------------------------------- *\
   Following routines are for manipulatin with the Xml-Tree inscance
\* --------------------------------------------------------------------------- */
PJXNODE jx_GetNodeParent(PJXNODE pNode)
{
   if (pNode == NULL) return NULL;
   return(pNode->pNodeParent);
}
/* ---------------------------------------------------------------------------
   go to the top to find the root
   --------------------------------------------------------------------------- */
PJXNODE  jx_GetRoot (PJXNODE pNode)
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
PJXNODE jx_lookupByXpath (PJXNODE pRootNode, PUCHAR * ppName)
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
   pEnd = strchr (compVal , BraEnd);
   if (pEnd == NULL) return NULL;
   compLen = pEnd - compVal;
   *ppName =  *ppName + (pEnd - Name);

   if (*keyName == Masterspace) {

      // Find by atribute value
      PJXNODE pNodeTemp = pRootNode;
      substr(keyName , Name+1 , nameLen-1);

      while (pNodeTemp && pNodeTemp->signature == NODESIG) {
         PXMLATTR pAtr = jx_AttributeLookup  (pNodeTemp, keyName);
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
      PJXNODE pNodeTemp = pRootNode == NULL? NULL:pRootNode->pNodeChildHead;
      while (pNodeTemp && pNodeTemp->signature == NODESIG) {
         PJXNODE pNode = jx_GetNode  (pNodeTemp, keyName);
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

PUCHAR jx_NodeName (PJXNODE pNode,BOOL SkipNameSpace)
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
PJXNODE  jx_FindNodeAtIndex(PJXNODE pNode , PUCHAR Key , int index , BOOL SkipNameSpace)
{
   int i =0;
   PUCHAR CurName;

   while (pNode) {

      CurName = jx_NodeName (pNode, SkipNameSpace);
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
void jx_GetKeyFromName (PUCHAR tempKey , PBOOL SkipNameSpace , PUCHAR KeyName , PUCHAR SearchName)
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
void jx_GetKeyFromName (PUCHAR tempKey , PBOOL SkipNameSpace , PUCHAR prevKey)
{
   *SkipNameSpace = (* prevKey  == '*');
   if (*SkipNameSpace) {
      prevKey+= 2; // Skip the *:
   } else {
      *SkipNameSpace = (strchr(prevKey, ':') == NULL);
   }
   strcpy (tempKey , prevKey);
}
/* ---------------------------------------------------------------------------
   Find node by name, by parsing a name string and traverse the tree
   The Node can be the casted to the xml root
   --------------------------------------------------------------------------- */
static BOOL isNextDelimiter(UCHAR c)
{
   return c == BackSlash || c  == Slash || c == Dot;
}
/* ---------------------------------------------------------------------------
   name contains [UBOUND]
   --------------------------------------------------------------------------- */
BOOL jx_isUbound (PUCHAR name)
{
   if (name[0] != BraBeg)  return false;
   if (memicmp(name+1  , "UBOUND" , 6) != 0) return false;
   if (name[7] != BraEnd)  return false;
   return true;
}
/* ---------------------------------------------------------------------------
   Set the counter
   --------------------------------------------------------------------------- */
PJXNODE jx_CountChildren(PJXNODE pNode)
{
    PJXNODE p;

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
static PJXNODE jx_ReturnNode (PJXNODE pNode, BOOL asCounter)
{
    if (pNode) pNode->doCount = asCounter;
    jx_traceNode("GetNode return", pNode);
    return pNode;
}
/* ---------------------------------------------------------------------------
   Return the node with name match
   --------------------------------------------------------------------------- */
static PJXNODE jx_lookUpSiblingByName(PJXNODE pNode , PUCHAR keyName)
{
   PUCHAR curName;
   BOOL   SkipNameSpace;

   SkipNameSpace = (* keyName == '*');
   if (SkipNameSpace) {
      keyName += 2; // Skip the *:
   } else {
      SkipNameSpace = (strchr(keyName , ':') == NULL);
   }

   // Locate name match
   while (pNode) {
      curName = jx_NodeName (pNode,SkipNameSpace);

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
static PJXNODE jx_CalculateUbound(PJXNODE pNode , PUCHAR key , BOOL SkipNameSpace)
{

   PJXNODE pNodeTemp = pNode;

   // JSON has an array type
   if (pNode == NULL) return NULL;

   // JSON can count faster:
   if (pNode->type == ARRAY || pNode->type == OBJECT) {
      jx_CountChildren(pNode);
      return jx_ReturnNode (pNode, true ); // Done !! return the current node with the counter updated
   }

   pNode->Count = 0;

   while (pNodeTemp) {
      // Skip namespace ? - when namespace is a *:
      PUCHAR CurName = jx_NodeName (pNodeTemp, SkipNameSpace);
      if (CurName && stricmp(key , CurName) == 0) {
         pNode->Count ++;
      }
      pNodeTemp=pNodeTemp->pNodeSibling;
   }
   return jx_ReturnNode (pNode, true ); // Done !! return the current node with the counter updated
}
/* ---------------------------------------------------------------------------
   Use index subscription to locate the node
   --------------------------------------------------------------------------- */
static PJXNODE jx_lookupByIndex(PJXNODE pNode , PUCHAR tempKey , int Index, BOOL SkipNameSpace)
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
      return jx_FindNodeAtIndex(pNode , tempKey , Index , SkipNameSpace);
   }
}
/* ---------------------------------------------------------------------------
   Get the numeric portion between two memory locations
   This has to be conservative: if not every characters
   is numeric we return -1 for not fully numeric
   --------------------------------------------------------------------------- */
int jx_getNumericKey (PUCHAR pStr, PUCHAR pEnd)
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
/* ---------------------------------------------------------------------------
   Find node by name, by parsing a name string and traverse the tree
   --------------------------------------------------------------------------- */
PJXNODE jx_GetNode  (PJXNODE pNode, PUCHAR Name)
{
   PUCHAR  pStart   = Name;
   PJXNODE pNodeTemp = NULL;
   BOOL    Found = FALSE;
   int     Len=0, l , i, StartIx;
   LONG    index;
   PUCHAR  p, pName, pEnd = "";
   PJXNODE refNode;
   UCHAR   refName [256];

   if (pNode == NULL
   ||  pNode->signature != NODESIG) {
   	return NULL;
   }

   // You can change the "debug" in a debugsession to dump the source node
   jx_traceNode ( "GetNode " , pNode);

   // Only "/" in the name ... that is my self
   if (Name == NULL || *Name == '\0'  ) {
      return jx_ReturnNode (pNode, false); // Done !! Just want the root
   }
   // Ubound on the root node
   if (jx_isUbound(Name)) {
      jx_CountChildren(pNode);
      return jx_ReturnNode (pNode, true ); // Done !! return the current node with the counter updated
   }

   if (isNextDelimiter(*Name)) {
      pNode = jx_GetRoot(pNode);
      Name++; // Skip root
      // dont do this - list will break since it will use the firs child on the list .. see later:
      // if (*Name == '\0') return jx_ReturnNode (pNode, false);; // Done
   }


   // By default we are searching for Nodeents in objects hench Start with the
   // First child and match; if OK the take the next level etc
   // However - the level can be restored to the object for ie [UBOUND] or index lookup like: [123]
   if (*Name != BraBeg) {
      pNode = pNode->pNodeChildHead;
      // .. but we can do it here: baically: "/" gives the first child to the root
      if (*Name == '\0') return jx_ReturnNode (pNode, false);; // Done
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
      if (*pEnd == BraBeg) {
         pEnd = strchr ( pName , BraEnd);
      } else {
         pEnd = findchr(pName , delimiters , sizeof(delimiters));
      }

      // No Bytes remaining => End of name = rest of string
      if ( pEnd == NULL ) {
         pEnd = pName + strlen(pName);
      }

      // Break at empty arrays: []  otherwise the "set value will find the array root !!
      // Empty arrays does not exists but is rather an indications of a new array element has to be appended
      else if (pEnd[0] == BraBeg && pEnd[1] == BraEnd) {
         return NULL;
      }

      Len = pEnd - pName;

      // Check for anonymous object and array in the root  TODO this need to be allowed
      if (*pName == BraBeg && Len == 0) {
         pName ++;
         continue;
      }

      // Check for special names: Subscriptions and Ubound like yy/xx[UBOUND]
      // Note: This uses the refrecene name "refName" which is the last "real name" from the parser
      if ( pName > pStart && *(pName-1)  == BraBeg) {

         UCHAR  tempKey [256];
         BOOL   SkipNameSpace;
         jx_GetKeyFromName (tempKey , &SkipNameSpace , refName);


         if (memicmp (pName , "UBOUND" , 6) == 0) {
            return jx_CalculateUbound(refNode, tempKey, SkipNameSpace);
         }

         // .. If the name is numeric, it is a subscription
         index = jx_getNumericKey (pName , pEnd);

         // When a subscription is found, then locate the occurens
         if (index >= 0) {
            pNode = jx_lookupByIndex(refNode , tempKey, index, SkipNameSpace);
         } else {
            // X-path Nodeent search:
            pNode = jx_lookupByXpath(refNode , &pName);
            pEnd = pName +1;
         }
         if (pNode == NULL) return NULL;

      } else {
         // "Normal" nodes with "normal" names. Store the name for furthere references "refName"
         substr(refName, pName, Len);
         pNode = jx_lookUpSiblingByName(pNode , refName);

      }

      // Current node will be our reference node for subsequent iterations
      refNode = pNode;

      // Skip trailing "]" and blanks
      for (; *pEnd == BraEnd || *pEnd == Blank ; pEnd++);    // the ']'

      // This level found. Iterate on next name
      if (*pEnd > '\0') { // Otherwise past end of string
         if (*pEnd != BraBeg) {

				// Found but empty or dead
				if (pNode == NULL
   			||  pNode->signature != NODESIG) {
   				return NULL;
   			}

            pNode = pNode->pNodeChildHead;
         }
         pName = pEnd +1 ; // Skip the '.' or '/' and set up next iteration

      } else {
         return jx_ReturnNode (pNode, false ); // Done !! return the current node with the counter updated
      }
   }
}
/* ------------------------------------------------------------- */
LGL jx_Has  (PJXNODE pNode, PUCHAR Name)
{
   PJXNODE p = jx_GetNode  (pNode, Name);
   if (p == NULL) return OFF;
   if (p->type == VALUE) {
      if (p->Value == NULL) return OFF;
      if (p->isLiteral && BeginsWith(p->Value, "null")) return OFF;
   }
   return (ON );
}
/* ------------------------------------------------------------- */
LGL jx_IsTrue  (PJXNODE pNode, PUCHAR Name)
{
   PJXNODE p = jx_GetNode  (pNode, Name);
   if (p == NULL) return OFF;
   if (p->type == VALUE) {
     if (p->Value == NULL)  return OFF;
     if (p->Value[0] == 0 ) return OFF;
     if (p->Value[0] == '0' && p->Value[1] == 0 )  return OFF;
     if (p->isLiteral && BeginsWith(p->Value, "false")) return OFF;
   }
   return (ON );
}
/* ------------------------------------------------------------- */
LGL jx_IsNull  (PJXNODE pNode, PUCHAR Name)
{
   PJXNODE p = jx_GetNode  (pNode, Name);
   if (p == NULL) return ON;
   if (p->type == VALUE) {
     if (p->Value == NULL)  return ON;
   }
   return (OFF);
}
/* ------------------------------------------------------------- */
LGL jx_isNode  (PJXNODE pNode)
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
PXMLATTR jx_AttributeLookup   (PJXNODE pNode, PUCHAR Name)
{
   PXMLATTR pAttr;
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
/* -------------------------------------------------------------
   returns the value of the node
   ------------------------------------------------------------- */
PJXNODE jx_GetNodeByName  (PJXNODE  pNode, PUCHAR Ctlstr , ... )
{
   va_list arg_ptr;
   UCHAR Name[1024];
   SHORT l;
   PJXNODE pNodeOut;

/* Build a temp string with the formated data  */
   va_start(arg_ptr, Ctlstr);
   l = vsprintf(Name, Ctlstr, arg_ptr);
   va_end(arg_ptr);

   pNodeOut = jx_GetNode(pNode, Name);
   return (pNodeOut);
}
/* -------------------------------------------------------------
   returns the value of the node
   ------------------------------------------------------------- */
PUCHAR  jx_GetNodeValuePtr  (PJXNODE pNode , PUCHAR DefaultValue)
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
PUCHAR  jx_GetNodeAttrValuePtr  (PJXNODE pNode , PUCHAR AttrName, PUCHAR DefaultValue)
{
   PXMLATTR pAttr;

   pAttr = jx_AttributeLookup   (pNode, AttrName);
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
PXMLATTR jx_NodeAddAttributeValue  (PJXNODE pNode , PUCHAR AttrName, PUCHAR Value)
{

   PXMLATTR pAttrTemp;
   PXMLATTR * ppEnd = &pNode->pAttrList;

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
VOID jx_SetNodeAttrValue  (PJXNODE pNode , PUCHAR AttrName, PUCHAR Value)
{
   PXMLATTR pAttr;

   pAttr = jx_AttributeLookup   (pNode, AttrName);
   if (pAttr == NULL) {
      jx_NodeAddAttributeValue( pNode , AttrName, Value);
      return;
   } else {
      memFree(&pAttr->Value);
      pAttr->Value = memStrDup(Value);
      return;
   }
}
/* ---------------------------------------------------------------------------
   X-path: Find node by name, by parsing a name string and traverse the tree
   It can be relative by giging either a Nodeent or a XML-common pointer
   --------------------------------------------------------------------------- */
PUCHAR jx_GetValuePtr (PJXNODE pNodeRoot, PUCHAR Name, PUCHAR Default)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   // from "C" return null in number of parms
   PUCHAR  dft =  (pParms->OpDescList == NULL
               ||  pParms->OpDescList->NbrOfParms == 0
               ||  pParms->OpDescList->NbrOfParms >= 3) ? Default : "";

   PUCHAR    pNodeKey, pAtrKey;
   PXMLATTR  pAtr;
   PJXNODE   pNode;
   static UCHAR temp [10];

   if (pNodeRoot == NULL) {
     return dft;
   }

   pAtrKey = strchr(Name, Masterspace);

   if (pAtrKey) {
      PUCHAR pExp = strchr(Name, BraBeg);
      if  (pExp == null || pAtrKey  < pExp) {
         *pAtrKey = '\0'; // Terminate the Nodeent
          pAtrKey ++;     // atribute is the next
      }
   }

   pNode = jx_GetNode  (pNodeRoot , Name);
   if (pNode == NULL) return dft;

   if (pAtrKey) {
      pAtr =  jx_AttributeLookup   (pNode, pAtrKey);
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
static void jx_joinArray2vc (PVARCHAR pRes , PJXNODE pNode)
{
    PJXNODE p = pNode->pNodeChildHead;
    int len;
    pRes->Length = 0;
    while (p) {
       PUCHAR v = p->Value;
       if (v  && *v) {
          vccatstr(pRes , v);
       }
       p = p->pNodeSibling;
    }
}
/* --------------------------------------------------------------------------- */
static void str2vcXlate (PJXNODE pNode , PVARCHAR pRes , PUCHAR str)
{
   if (pNode->ccsid == 0) {
      str2vc ( pRes , str);
   } else {
      LONG len = strlen(str);
      PUCHAR out = malloc (len * 2);
      ensureOpenXlate();
      xlateMem (xlate1208toE, out , str, len);
      str2vc ( pRes , out);
      free (out);
   }
}
/* ---------------------------------------------------------------------------
   Take the name after the last  @ - that is the attributename
   --------------------------------------------------------------------------- */
PUCHAR jx_splitAtrFromName (PUCHAR name)
{
   int balance = 0;
   PUCHAR pEnd;

   for (pEnd = name + strlen(name)-1 ; pEnd >= name; pEnd --) {
      if (*pEnd == Masterspace && balance == 0) {
         *pEnd  = '\0';     // Terminate the Node end giving the name to the node only
         return (pEnd +1);  // atribute name is the next. Return that
      }
      else if (*pEnd == BraBeg) {
         balance --;
      }
      else if (*pEnd == BraEnd) {
         balance ++;
      }
   }
   return NULL;
}
/* ---------------------------------------------------------------------------
   X-path: Find node by name, by parsing a name string and traverse the tree
   It can be relative by giging either a Nodeent or a XML-common pointer
   --------------------------------------------------------------------------- */
void jx_CopyValueByNameVC (PVARCHAR pRes, PJXNODE pNodeRoot, PUCHAR Name, PUCHAR Default , BOOL joinString)
{
   PUCHAR    pNodeKey, pAtrKey;
   PXMLATTR  pAtr;
   PJXNODE   pNode;

   // Assume : Not found
   str2vc(pRes , Default);

   if (pNodeRoot == NULL) return;

   pAtrKey = jx_splitAtrFromName (Name);

   pNode = jx_GetNode  (pNodeRoot , Name);
   if (pNode == NULL) return;

   if (pAtrKey) {
      pAtr =  jx_AttributeLookup   (pNode, pAtrKey);
      if (pAtr == NULL)        return;
      if (pAtr->Value == NULL) return;
      str2vc(pRes , pAtr->Value);

   } else if (pNode->doCount) {
      vcprintf( pRes, "%ld" , pNode->Count);

   } else if (joinString &&  pNode->type == ARRAY) {
      jx_joinArray2vc (pRes , pNode);
      if (pRes->Length == 0) { // No data found when joining arrays as string - Now serialize it as usual
         pRes->Length  = jx_AsJsonTextMem (pNode , pRes->String , 32760);
      }

   } else if (pNode->type == OBJECT ||  pNode->type == ARRAY ) {
      pRes->Length  = jx_AsJsonTextMem (pNode , pRes->String, 32760);

   } else if (pNode->Value) {
      str2vcXlate(pNode, pRes , pNode->Value);
   }
}
/* ---------------------------------------------------------------------------
   --------------------------------------------------------------------------- */
void  jx_SetByParseString (PJXNODE pDest , PUCHAR pSourceStr , MERGEOPTION merge , BOOL move)
{
   PJXNODE pSource = NULL;
   PUCHAR  firstNonBlank = pSourceStr;

   // quick trim
   for (;*firstNonBlank == ' '; firstNonBlank++);

   // TODO :  jx_ParseString returns object for any string which is an error; now dont use
   // the paser if it is not an OBJECT or ARRAY
   if ( *firstNonBlank == BraBeg ||  *firstNonBlank == CurBeg) {
      pSource = jx_ParseString(  firstNonBlank , "");
   }

   if (pSource) {
      // TODO !!! Arrays dont work in NodeMerger.. This is a simple workarround
      if (pSource->type == ARRAY) {
         jx_NodeMoveAndReplace (pDest, pSource);
      // jx_NodeFree(pSource); Why delete what we just made .. NLI removed line
         return;
      }

      if (move) {
        jx_NodeMoveAndReplace (pDest, pSource);
        // jx_NodeFree(pSource); Why delete what we just made .. NLI removed line
      } else {
        jx_NodeMerge(pDest, pSource, merge  );
      }
   } else {
      jx_NodeSet (pDest  , pSourceStr);
      pDest->type      = VALUE;
      pDest->isLiteral =  // isdigit (*pSourceStr)  !! No !! the "123 - John" is not a number
                          strcmp(pSourceStr ,"true") == 0
                       || strcmp(pSourceStr ,"false") == 0
                       || strcmp(pSourceStr ,"null") == 0;
   }
}
/* ---------------------------------------------------------------------------
   Insert a node as tail in an array - as copy or move it into
   --------------------------------------------------------------------------- */
PJXNODE  jx_ArrayPush (PJXNODE pDest, PJXNODE pSource , BOOL16 copyP)
{
   PJXNODE  pNewNode;
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   BOOL copy = (pParms->OpDescList->NbrOfParms >= 3) ? copyP : false;

   if (pSource == NULL)  {
   // TODO - rather have NULL as value, that literal null,
   // But this requires to check the serialized .....
   // pNewNode  = NewNode  (NULL  , NULL , VALUE);
      pNewNode  = NewNode  (NULL  , "null" , LITERAL);
   } else if (pSource->signature != NODESIG) {
      if (*(PUCHAR) pSource == BraBeg || *(PUCHAR) pSource == CurBeg ) {
          pNewNode = jx_ParseString((PUCHAR) pSource, "");
      } else {
          pNewNode  = NewNode  (NULL  , (PUCHAR) pSource , VALUE);
      }
   } else if (copy) {
      pNewNode = jx_NodeClone (pSource);
   } else {
      pNewNode = jx_NodeUnlink  (pSource);
   }

   jx_NodeAddChildTail (pDest, pNewNode);

}
/* ---------------------------------------------------------------------------
   Appends an array to the end of another array
   --------------------------------------------------------------------------- */
PJXNODE  jx_ArrayAppend  (PJXNODE pDest, PJXNODE pSource , BOOL16 copyP)
{
   PJXNODE  pNewNode, pNode, pNext;
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   BOOL copy = (pParms->OpDescList->NbrOfParms >= 3) ? copyP : false;

   if (pSource == NULL)  {
   // TODO - rather have NULL as value, that literal null,
   // But this requires to check the serialized .....
   // pNewNode  = NewNode  (NULL  , NULL , VALUE);
      pNewNode  = NewNode  (NULL  , "null" , LITERAL);
   } else if (pSource->signature != NODESIG) {
      if (*(PUCHAR) pSource == BraBeg || *(PUCHAR) pSource == CurBeg ) {
          pNewNode = jx_ParseString((PUCHAR) pSource, "");
      } else {
          pNewNode  = NewNode  (NULL  , (PUCHAR) pSource , VALUE);
      }
   } else if (copy) {
      pNewNode = jx_NodeClone (pSource);
   } else {
      pNewNode = jx_NodeUnlink  (pSource);
   }

    // Arrays - need first child;
   pNode = pNewNode->pNodeChildHead;
   while (pNode) {
      pNext = pNode->pNodeSibling;
      jx_ArrayPush (pDest , pNode , false);
      pNode = pNext;
   }

   return pDest;
}
/* ---------------------------------------------------------------------------
   Slice from element to element in an array

   --------------------------------------------------------------------------- */
PJXNODE  jx_ArraySlice   (PJXNODE pSource , int from , int to, BOOL16 copyP)
{
   PJXNODE  pNewNode, pNode, pNext, pOut;
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   BOOL copy = (pParms->OpDescList->NbrOfParms >= 2) ? copyP : false;
   int i =0;
   BOOL  deleteAfter = false;

   if (pSource == NULL)  return null;

   if (pSource->signature != NODESIG) {
      if (*(PUCHAR) pSource == BraBeg || *(PUCHAR) pSource == CurBeg ) {
         pSource = jx_ParseString((PUCHAR) pSource, "");
      }
      if (pSource == NULL)  return null;
      deleteAfter = true;
      copy = false;
   }

   pOut = jx_NewArray(NULL);

   // first locate first element;
   pNode = pSource->pNodeChildHead;
   for (i=0; pNode && i < from ; i++) {
      pNode = pNode->pNodeSibling;
   }

   // now keep on pushing
   for (; pNode && (i < to || to == -1); i++) {
      pNext = pNode->pNodeSibling;
      jx_ArrayPush (pOut , pNode , copy);
      pNode = pNext;
   }

   if (deleteAfter) {
      jx_NodeDelete (pSource);
   }

   return pOut;
}
/* ---------------------------------------------------------------------------
   Find node by name, by parsing a name string and traverse the array list
   --------------------------------------------------------------------------- */
PJXNODE  jx_lookupValue (PJXNODE pNode, PUCHAR expr, BOOL16 ignorecaseP)
{
   PJXNODE  pTemp;
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
/* ---------------------------------------------------------------------------
   Find node by name, by parsing a name string and traverse the array list
   --------------------------------------------------------------------------- */
LONG jx_getLength (PJXNODE pNode)
{
   PJXNODE  pTemp;
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
PJXNODE jx_CreateSubNodes  (PJXNODE pNodeRoot , PUCHAR Path )
{

   UCHAR    tempName [256];
   PUCHAR   pName = tempName;
   PUCHAR   pEnd;
   PJXNODE  pParentNode, pNodeTemp;
   BOOL     isNewArray = false;

   strcpy(tempName, Path);

   if  (pName[0] == BraBeg && pName[1] == BraEnd) {   // the empty array: []
     pName += 2;
     pNodeRoot->type = ARRAY;
     pParentNode = jx_NodeAdd (pNodeRoot, RL_LAST_CHILD, NULL , NULL, VALUE);
     isNewArray = true;
   } else if  (*pName == BraBeg) {
     pName ++ ;
     pParentNode = pNodeRoot;
   } else if (findchr(pName , delimiters , sizeof(delimiters)) == pName) {
     pName ++ ;
     pParentNode = jx_GetRoot(pNodeRoot);
   } else {
     pParentNode = pNodeRoot;
   }


   do {
      NODETYPE nodeType = VALUE;
      UCHAR arrix [64];
      pEnd = findchr(pName , delimiters , sizeof(delimiters));
      if (pEnd) {
        if      (*pEnd == BraBeg && pEnd[1] == BraEnd) isNewArray = true;
        else if (isNextDelimiter(*pEnd))               nodeType = OBJECT;
        else if (*pEnd == BraBeg)                      nodeType = ARRAY;
        else if (*pEnd == BraEnd) {
          int len = pEnd - pName;
          sprintf(arrix , "%c%*.*s%c" , BraBeg, len,len, pName , BraEnd);
          pName = arrix;
        }
        *pEnd = '\0'; // temp termination
      }
      if (*pName) {
        pNodeTemp = jx_GetNode  (pParentNode , pName);
        if (pNodeTemp == NULL) {
           freeNodeValue (pParentNode); // Can not have values if we have childrens
           // When i have children, then i must be an object or an array
           if (pParentNode->type != ARRAY) {
              pParentNode->type = OBJECT;
           }
           pNodeTemp = jx_NodeAdd (pParentNode, RL_LAST_CHILD, pName , NULL, isNewArray ? ARRAY : nodeType);
        }

        // The [] syntax  - Add the new entry to the array
        if (isNewArray) {
           freeNodeValue(pNodeTemp);     // Can not have values if we have childrens
           pNodeTemp->type = ARRAY ;     // When i have childrne then i must be an object or array
           pNodeTemp = jx_NodeAdd (pNodeTemp, RL_LAST_CHILD, NULL , NULL, nodeType);
           pName = pEnd + 2;
           if (isNextDelimiter(*pName))  pName++;
           isNewArray = false; // Done with array chekking
        }
        // Todo !! (Not that elegant) - we just eate one byte to much at the [ xx ] index,
        // so push the bracket back again
        // else if (nodeType == ARRAY) {
        //    pName = pEnd;
        //    *pName = BraBeg;
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
PJXNODE  jx_GetOrCreateNode (PJXNODE pNodeRoot, PUCHAR Name)
{

   PJXNODE pDest;

   pDest  = jx_GetNode  (pNodeRoot , Name);

   // Not found? Build the Nodeents
   if (pDest  == NULL) {
      pDest  = jx_CreateSubNodes (pNodeRoot , Name);
   }
   return pDest;
}
/* ---------------------------------------------------------------------------
   X-path: Find node by name, by parsing a name string and traverse the tree
   It can be relative by giving either a Node and a name
   --------------------------------------------------------------------------- */
PJXNODE  jx_SetValueByName (PJXNODE pNodeRoot, PUCHAR Name, PUCHAR Value, NODETYPE typePP)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PUCHAR        pNodeKey, pAtrKey;
   PXMLATTR      pAtr;
   PJXNODE       pParentNode, pNodeTemp;
   NODETYPE      typeP = (pParms->OpDescList->NbrOfParms >= 4) ? typePP : UNKNOWN;
   NODETYPE      type  = typeP & 255;   // Strip the modifiers
   MERGEOPTION   merge = typeP & (MO_MERGE_NEW + MO_MERGE_MATCH + MO_MERGE_REPLACE); // All mergeoptions
   BOOL          move  = (typeP & NT_MOVE ) > 0;
   BOOL          debug = false;

   if (pNodeRoot == NULL) {
      return NULL;
   }

   pAtrKey = strchr(Name, Masterspace);

   if (pAtrKey) {
      PUCHAR pExp = strchr(Name, BraBeg);
      if  (pExp == null || pAtrKey  < pExp) {
         *pAtrKey = '\0'; // Terminate the Nodeent
          pAtrKey ++;     // atribute is the next
      }
   }

   // Get the node or create it if it does not exists
   pParentNode = jx_GetOrCreateNode (pNodeRoot, Name);

   if (pAtrKey) {
      jx_SetNodeAttrValue  (pParentNode , pAtrKey, Value);
      return jx_traceNode("Attributes" ,pParentNode);
   }

   if (pParms->OpDescList->NbrOfParms >= 4) {
      if ( type == PARSE_STRING) {
         jx_SetByParseString (pParentNode , Value, merge , move);
         return jx_traceNode("Parse String", pParentNode);
      }
      if ( type == POINTER_VALUE) {
         jx_NodeSetAsPointer (pParentNode , Value);
         return jx_traceNode("Pointer", pParentNode);
      }
   }

   // The value is an object / or an array already
   if (Value && *Value == NODESIG) {
      // TODO!! Clean this up ... Node copy replace the node value
      // where NodeCloneAndReplace replace the node it self
      // if ( pParms->OpDescList->NbrOfParms >= 4 && (type == CLONE || type == CLONE_OLD)) {
      //    jx_NodeCopy (pParentNode , (PJXNODE) Value, RL_LAST_CHILD);
      //   return jx_traceNode("Node Copy " , pParentNode);

      if (move) {
         jx_NodeMoveAndReplace (pParentNode , (PJXNODE) Value);
         return jx_traceNode("Node Move and Replace " , pParentNode);
      } else {
         jx_NodeCloneAndReplace (pParentNode , (PJXNODE) Value);
         return jx_traceNode("Node Clone and replace" , pParentNode);
      }
   }

   jx_NodeSet (pParentNode , Value);
   if (pParms->OpDescList->NbrOfParms >= 4) {
      if (type == LITERAL) {
        pParentNode->type      = VALUE;
        pParentNode->isLiteral = TRUE;
      } else {
        pParentNode->type = type;
        pParentNode->isLiteral = FALSE;
      }
   }

   return jx_traceNode("Set value" , pParentNode);
}
/* -------------------------------------------------------------
   Set integer by name
   ------------------------------------------------------------- */
PJXNODE  jx_SetIntByName (PJXNODE pNode, PUCHAR Name, LONG Value)
{
   UCHAR  s [32];
   sprintf(s , "%ld" , Value);
   return jx_SetValueByName(pNode , Name , s, LITERAL );
}
/* -------------------------------------------------------------
   Set decimal  by name
   ------------------------------------------------------------- */
PJXNODE  jx_SetDecByName (PJXNODE pNode, PUCHAR Name, FIXEDDEC Value)
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

   return jx_SetValueByName(pNode , Name , s, LITERAL );
}
/* -------------------------------------------------------------
   Set Null by name
   ------------------------------------------------------------- */
PJXNODE  jx_SetNullByName (PJXNODE pNode, PUCHAR Name)
{
   return jx_SetValueByName(pNode , Name , NULL , LITERAL );
}
/* -------------------------------------------------------------
   Set BOOL by name
   ------------------------------------------------------------- */
PJXNODE  jx_SetBoolByName (PJXNODE pNode, PUCHAR Name, LGL Value)
{
   return jx_SetValueByName(pNode , Name , Value == OFF ? "false":"true", LITERAL );
}
/* -------------------------------------------------------------
   Set String by name
   ------------------------------------------------------------- */
PJXNODE  jx_SetStrByName (PJXNODE pNode, PUCHAR Name, PUCHAR Value)
{
   return jx_SetValueByName(pNode , Name , Value , VALUE );
}
/* -------------------------------------------------------------
   Set Parse and evaluate  by name
   ------------------------------------------------------------- */
PJXNODE  jx_SetEvalByName (PJXNODE pNode, PUCHAR Name, PUCHAR Value)
{
   return jx_SetValueByName(pNode , Name , Value , PARSE_STRING );
}
/* -------------------------------------------------------------
   Set BOOL by name
   ------------------------------------------------------------- */
PJXNODE  jx_SetPtrByName (PJXNODE pNode, PUCHAR Name, PUCHAR Value, LGL isStringP)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   BOOL isString  = (pParms->OpDescList->NbrOfParms >= 4 && isStringP == ON);
   PJXNODE pRes = jx_SetValueByName(pNode , Name , Value , POINTER_VALUE );
   pRes->isLiteral = ! isString;
   return pRes;
}
/* -------------------------------------------------------------
   RPG Wrappers
   ------------------------------------------------------------- */
LGL jx_ParseStmfFile (PJXNODE  * ppRoot , PUCHAR FileName , PUCHAR Mode)
{
   BOOL ok;
   PJXNODE pRoot = jx_ParseFile(FileName, Mode);
   *ppRoot = pRoot;
   return ((jxError) ?  OFF: ON );
}
// -------------------------------------------------------------
VARCHAR jx_GetValueVC(PJXNODE pNodeRoot, PUCHAR NameP, PUCHAR DefaultP)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PUCHAR  Default = (pParms->OpDescList->NbrOfParms >= 3) ? DefaultP : "";
   PUCHAR  Name    = (pParms->OpDescList->NbrOfParms >= 2) ? NameP    : "";
   VARCHAR res;
   jx_CopyValueByNameVC ( &res , pNodeRoot, Name , Default , false) ;
   return (res);
}
// -------------------------------------------------------------
VARCHAR jx_GetStrJoinVC(PJXNODE pNodeRoot, PUCHAR NameP, PUCHAR DefaultP)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PUCHAR  Default = (pParms->OpDescList->NbrOfParms >= 3) ? DefaultP : "";
   PUCHAR  Name    = (pParms->OpDescList->NbrOfParms >= 2) ? NameP    : "";
   VARCHAR res;
   jx_CopyValueByNameVC ( &res , pNodeRoot, Name , Default , true ) ;
   return (res);
}

// -------------------------------------------------------------
FIXEDDEC jx_GetValueNum (PJXNODE pNode , PUCHAR Name  , FIXEDDEC dftParm)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   FIXEDDEC dft   =  (pParms->OpDescList->NbrOfParms >= 3) ? dftParm : 0;
   PUCHAR   path  =  (pParms->OpDescList->NbrOfParms >= 2) ? Name  : "";

   PUCHAR  value;

   value = jx_GetValuePtr    (pNode , path , NULL ) ;
   if (value == NULL) {
       return  dft;
   }
   return jx_Num(value);
}
// -------------------------------------------------------------
INT64 jx_GetValueInt (PJXNODE pNode , PUCHAR Name  , INT64 dftParm)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   INT64    dft   =  (pParms->OpDescList->NbrOfParms >= 3) ? dftParm : 0;
   PUCHAR   path  =  (pParms->OpDescList->NbrOfParms >= 2) ? Name  : "";

   PUCHAR  value;

   value = jx_GetValuePtr    (pNode , path , NULL ) ;
   if (value == NULL) {
       return  dft;
   }
   return jx_Num(value);
}
// -------------------------------------------------------------
VARCHAR jx_GetNodeValueVC (PJXNODE pNode , PUCHAR DefaultValue)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PUCHAR dft = (pParms->OpDescList->NbrOfParms >= 2) ? DefaultValue : "";
   PUCHAR value;
   VARCHAR res;

   value =  jx_GetNodeValuePtr  (pNode , dft);
   res.Length = strlen(value);
   memcpy(res.String , value , res.Length);
   return (res);
}
FIXEDDEC jx_GetNodeValueNum (PJXNODE pNode , FIXEDDEC DefaultValue)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   FIXEDDEC dft = (pParms->OpDescList->NbrOfParms >= 2) ? DefaultValue : 0;
   PUCHAR value =  jx_GetNodeValuePtr  (pNode , NULL  );
   if (value == NULL) {
     return dft;
   } else {
      return jx_Num(value);
   }
 }
// -------------------------------------------------------------
PUCHAR  jx_GetNodeNamePtr (PJXNODE pNode)
{
   return (pNode && pNode->Name) ? pNode->Name : "";
}
// -------------------------------------------------------------
VARCHAR jx_GetNodeNameVC (PJXNODE pNode)
{
   VARCHAR res;

   res.Length = 0;
   if (pNode && pNode->Name) {
      res.Length = strlen(pNode->Name);
      memcpy(res.String , pNode->Name , res.Length);
   }
   return (res);
}
// -------------------------------------------------------------
VARCHAR jx_GetNodeAttrValueVC (PJXNODE pNode ,PUCHAR AttrName, PUCHAR DefaultValue)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PUCHAR  dft = (pParms->OpDescList->NbrOfParms >= 3) ? DefaultValue : "";
   VARCHAR res;
   PUCHAR value =  jx_GetNodeAttrValuePtr  ( pNode , AttrName,  dft) ;
   res.Length = strlen(value);
   memcpy(res.String , value , res.Length);
   return (res);
}
// -------------------------------------------------------------
FIXEDDEC jx_GetNodeAttrValueNum (PJXNODE pNode , PUCHAR AttrName, FIXEDDEC DefaultValue)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   FIXEDDEC dft = (pParms->OpDescList->NbrOfParms >= 2) ? DefaultValue : 0;
   PXMLATTR pAttr = jx_AttributeLookup   (pNode, AttrName);

   if (pAttr == NULL
   ||  pAttr->Value == NULL) {
      return ( dft );
   } else {
      return jx_Num(pAttr->Value);
   }
}
// -------------------------------------------------------------
PJXNODE jx_GetNodeNext (PJXNODE pNode)
{
   if (pNode == NULL) {
      return  NULL ;
   } else {
      return   pNode->pNodeSibling ;
   }
}
// -------------------------------------------------------------
PJXNODE jx_GetNodeChild  (PJXNODE pNode)
{
   if (pNode == NULL) {
      return  NULL ;
   } else {
      return  pNode->pNodeChildHead ;
   }
}
// -------------------------------------------------------------
PJXNODE jx_GetNodeChildNo ( PJXNODE pNode , int childNo)
{
   PJXNODE pChild =  jx_GetNodeChild (pNode);
   int i =0;
   while (i < childNo && pChild) {
      pChild  = jx_GetNodeNext(pChild);
      i++;
   }
   return pChild;
}
// -------------------------------------------------------------
PXMLATTR  jx_GetAttrFirst (PJXNODE pNode)
{
   if (pNode == NULL) {
      return (NULL);
   } else {
      return (pNode->pAttrList);
   }
}
// -------------------------------------------------------------
PXMLATTR  jx_GetAttrNext  (PXMLATTR pAttr)
{
   if (pAttr == NULL) {
      return (NULL);
   } else {
      return (pAttr->pAttrSibling);
   }
}
// -------------------------------------------------------------
VARCHAR jx_GetAttrNameVC (PXMLATTR pAttr)
{
   VARCHAR res;

   res.Length = 0;
   if (pAttr) {
      res.Length = strlen(pAttr->Name);
      memcpy(res.String , pAttr->Name , res.Length);
   }
   return (res);
}
// -------------------------------------------------------------
PUCHAR  jx_GetAttrNamePtr (PXMLATTR pAttr)
{
   return (pAttr && pAttr->Name) ? pAttr->Name : null;
}
// -------------------------------------------------------------
PUCHAR  jx_GetAttrValuePtr (PXMLATTR pAttr)
{
   return (pAttr && pAttr->Value) ? pAttr->Value : null;
}
// -------------------------------------------------------------
FIXEDDEC jx_GetAttrValueNum  (PXMLATTR pAttr, FIXEDDEC dftParm)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   FIXEDDEC dft = (pParms->OpDescList->NbrOfParms >= 2) ? dftParm  : 0;
   PUCHAR  value = jx_GetAttrValuePtr (pAttr);
   return  value ? jx_Num(value)  : dft;
}
// -------------------------------------------------------------
VARCHAR jx_GetAttrValueVC (PXMLATTR pAttr, PUCHAR DefaultValue)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PUCHAR  dft = (pParms->OpDescList->NbrOfParms >= 2) ? DefaultValue : "";
   VARCHAR res;

   res.Length = 0;
   if (pAttr &&  pAttr->Value ) {
      res.Length = strlen(pAttr->Value);
      memcpy(res.String , pAttr->Value, res.Length);
   }

   if (res.Length ==0) {
      res.Length = strlen(dft);
      memcpy(res.String , dft, res.Length);
   }
   return (res);
}
// -------------------------------------------------------------
LGL  jx_Error (PJXNODE  pNode)
{
   return ( jxError || pNode == NULL) ? ON : OFF;
}
// -------------------------------------------------------------
PUCHAR jx_ErrStr (PJXNODE pJxNode)
{
   return jxMessage;
}

// -------------------------------------------------------------
VOID jx_SetApiErr (PJXNODE pJxNode, PAPIERR pApiErr)
{
     strcpy (pApiErr->msgid , "CPF9898");
     substr  (pApiErr->msgdta , jxMessage ,pApiErr->size - 25 );  // not inc. the header
     pApiErr->avail  = strlen(pApiErr->msgdta);
}
// -------------------------------------------------------------
VARCHAR1024 jx_Message  (PJXNODE pJxNode)
{
   VARCHAR1024 res;
   str2vc (&res  ,  jxMessage);
   return (res);
}
// -------------------------------------------------------------
PJXNODE jx_GetMessageObject (PUCHAR msgId , PUCHAR msgDta)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PJXNODE pMsg = jx_NewObject(NULL);
   jx_SetBoolByName (pMsg , "success" ,  OFF);
   if (pParms->OpDescList->NbrOfParms > 0)  {
     jx_SetStrByName (pMsg , "msgId" ,  msgId);
     jx_SetStrByName (pMsg , "msgDta",  msgDta);
     // TODO - convert the msgid / msgData to text
   } else  {
     jx_SetStrByName (pMsg , "msg" ,  jxMessage);
   }
   return pMsg;
}
// -------------------------------------------------------------
PJXNODE jx_SuccessTrue ()
{
   PJXNODE pMsg = jx_NewObject(NULL);
   jx_SetBoolByName (pMsg , "success" ,  ON);
   return pMsg;
}
// -------------------------------------------------------------
// was jx_Close2
// Avoid closing an already closed XML
// -------------------------------------------------------------
void jx_Close (PJXNODE * ppNode)
{
   PJXNODE  pRoot  =  jx_GetRoot (*ppNode);
   jx_NodeDelete (pRoot);

   *ppNode = NULL;
}
// -------------------------------------------------------------
// remove all children from an object / array
// -------------------------------------------------------------
void jx_Clear  (PJXNODE pNode)
{
   if (pNode != NULL) {
      jx_FreeChildren(pNode);
   }
}
// -------------------------------------------------------------
void jx_Free  (PJXNODE pNode)
{
   jx_FreeSiblings(pNode);
}
//---------------------------------------------------------------------------
BOOL jx_HasMore(PJXNODE pNode)
{
   return (pNode != NULL);
}
//---------------------------------------------------------------------------
LGL jx_IsJson(PJXNODE pNode)
{
     return  (pNode->signature == NODESIG) ? ON : OFF;
}
//---------------------------------------------------------------------------
LGL jx_MemLeak(VOID)
{
    return  isOn(memLeak());
}
//---------------------------------------------------------------------------
VOID jx_MemStat(VOID)
{
    memStat();
}
//---------------------------------------------------------------------------
INT64 jx_MemUse(VOID)
{
    return memUse();
}

