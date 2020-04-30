/* SYSIFCOPT(*IFSIO) TERASPACE(*YES *TSIFC) STGMDL(*SNGLVL) */
/* ------------------------------------------------------------- *
 * Company . . . : System & Method A/S                           *
 * Design  . . . : Niels Liisberg                                *
 * Function  . . : File reader                                   *
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



extern UCHAR Remark   [4];  // !--
extern UCHAR DocType  [9];  // !DOCTYPE
extern UCHAR EndRemark[4];  // -->
extern UCHAR SlashGT  [3];  // />
extern UCHAR BraBraGT [4];  // ]]>
extern UCHAR Cdata    [10]; // <![CDATA[

extern UCHAR Apos       ;
extern UCHAR Quot       ;
extern UCHAR Question   ;
extern UCHAR EQ         ;
extern UCHAR GT         ;
extern UCHAR LT         ;
extern UCHAR Underscore ;
extern UCHAR Colon      ;
extern UCHAR Dot        ;
extern UCHAR Slash      ;
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


extern UCHAR jobSlash       ;
extern UCHAR jobBackSlash   ;
extern UCHAR jobMasterspace ;
extern UCHAR jobBraBeg      ;
extern UCHAR jobBraEnd      ;
extern UCHAR jobCurBeg      ;
extern UCHAR jobCurEnd      ;
extern UCHAR jobQuot  ;
extern UCHAR jobApos  ;



extern UCHAR e2aTbl[256];
extern UCHAR a2eTbl[256];
extern UCHAR delimiters [11];
extern int   InputCcsid , OutputCcsid;

static LONG  dbgStep=0;
static BOOL  skipBlanks = TRUE;


void jx_setDelimitersByCcsid (int ccsid)
{
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

   if (ccsid == 0) {
      jobSlash       = Slash ;
      jobBackSlash   = BackSlash   ;
      jobMasterspace = Masterspace ;
      jobBraBeg      = BraBeg   ;
      jobBraEnd      = BraEnd   ;
      jobCurBeg      = CurBeg   ;
      jobCurEnd      = CurEnd   ;
      jobQuot        = Quot ;
      jobApos        = Apos;
   }

}

/* ---------------------------------------------------------------------------
   --------------------------------------------------------------------------- */
void initconst(int ccsid)
{
   static int prevccsid = -1;  // can not be negative => force rebuild const

   // already done?
   if ( prevccsid == ccsid) return;
   prevccsid = ccsid;
   jx_setDelimitersByCcsid (ccsid);

}

// ---------------------------------------------------------------------------
void  jx_SkipChars(PJXCOM pJxCom , int skip)
{
   int i;
   for(i=0;i<skip; i++) {
      jx_GetChar(pJxCom);
   }
}
// ---------------------------------------------------------------------------
PUCHAR jx_GetChar(PJXCOM pJxCom)
{
   int i;
   PUCHAR treshold;
   static int len;

   /*
   if (dbgStep > 8170 ) { //       8179)
      int q = 1;
   }
   */

   if (pJxCom->State == XML_EXIT_ERROR) {
     return (pJxCom->pFileBuf == NULL ? "" : pJxCom->pFileBuf );
   }

   if (pJxCom->File == NULL) {
     if (pJxCom->pFileBuf == NULL) {
       pJxCom->pFileBuf =  pJxCom->StreamBuf;
     } else {
       pJxCom->pFileBuf ++;
     }
   }
   else {

      if (pJxCom->pFileBuf == NULL) {
         len = readBlock(pJxCom , pJxCom->FileBuf, sizeof(pJxCom->FileBuf));
         // printf("\nlen: %d\n" , len);
         pJxCom->pFileBuf = pJxCom->FileBuf;
      } else {
      // Increment the buffer pointer
         treshold = pJxCom->FileBuf + len - LOOK_AHEAD_SIZE;
         pJxCom->pFileBuf ++;
         if (pJxCom->pFileBuf > treshold && ! feof(pJxCom->File)) {
            PUCHAR temp = pJxCom->FileBuf + LOOK_AHEAD_SIZE;
            memcpy(pJxCom->FileBuf , treshold , LOOK_AHEAD_SIZE);
            len = readBlock(pJxCom , temp, sizeof(pJxCom->FileBuf) - LOOK_AHEAD_SIZE);
            len += LOOK_AHEAD_SIZE;
            //+1 because the first is allready processed and allow us to LOOK-BACK
            pJxCom->pFileBuf = pJxCom->FileBuf +1;
         }
      }
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
   dbgStep++;
   return (pJxCom->pFileBuf);
}
/* ---------------------------------------------------------------------------
   --------------------------------------------------------------------------- */
UCHAR SkipBlanks (PJXCOM pJxCom)
{
   UCHAR c;

   for(;;) {
      c  = *jx_GetChar(pJxCom);
      if ( pJxCom->State == XML_EXIT
      ||   pJxCom->State == XML_EXIT_ERROR ) {
         return '\0';
      }
      if (c > Blank) {
         pJxCom->pFileBuf --; // step back one...
         return c;
      }
   }
}
/* ---------------------------------------------------------------------------
   --------------------------------------------------------------------------- */
void CheckBufSize(PJXCOM pJxCom)
{
   if (pJxCom->DataIx >= pJxCom->DataSize ||  pJxCom->Data  == NULL) {
      pJxCom->DataSize += DATA_SIZE;
      memRealloc(&pJxCom->Data , pJxCom->DataSize ); // Initial size
   }
}
/* ---------------------------------------------------------------------------
   --------------------------------------------------------------------------- */
void jx_CheckEnd(PJXCOM pJxCom)
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
   if (BeginsWith (pJxCom->pFileBuf ,SlashGT))  {  // Check for short form   />
      pJxCom->pNodeWorkRoot = pJxCom->pNodeWorkRoot->pNodeParent;
      pJxCom->Level --;
      pJxCom->State = XML_FIND_START_TOKEN;
   }
}

/* ---------------------------------------------------------------------------
   --------------------------------------------------------------------------- */
int readBlock(PJXCOM pJxCom , PUCHAR buf, int size)
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

