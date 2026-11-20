// CMD:CRTCMOD
/* ------------------------------------------------------------- */
/* SYSIFCOPT(*IFSIO) OPTION(*EXPMAC *SHOWINC)                    */
/* Module  . . . : loadpgm                                       */
/* Date  . . . . : 14.06.2012                                    */
/* Design  . . . : Niels Liisberg                                */
/* Function  . . : Call programs and service program procedures  */
/*                 described by their PCML                       */
/*                                                               */
/* By     Date       Task    Description                         */
/* NL     14.06.2012         New module                          */
/* NL     20.11.2026         UTF-8: the graph (names, values and */
/*                           the PCML) is UTF-8, the parameter   */
/*                           buffers are in the job CCSID (or    */
/*                           the CCSID the PCML gives a field)   */
/* ------------------------------------------------------------- */
/*
   Encoding rules in this module - read before changing it:

   - Every string literal and character constant in the C code is EBCDIC
     (no #pragma convert). They are only used on the "buffer side": the
     parameter storage the called program sees, and the numeric / date
     helpers in strUtil, which work in the job CCSID.
   - Every name or value that goes into or comes out of a noxDB graph is
     UTF-8. Literal graph names come from the A_xxx constants below, which
     are compiled as CCSID 1252 (ASCII, the same bytes as UTF-8 for them).
   - Values cross the border in copyValueIntoBuffer (UTF-8 -> buffer) and
     newReturnNode (buffer -> UTF-8), nowhere else.
*/
#include <QLEAWI.h>
#include <signal.h>
#include <mih/stsppo.h>
#include <mih/setsppo.h>
#include <mih/MIDTTM.h>
#include <mih/matptr.h>
#include <qwtsetp.h>
#include <miptrnam.h>
#include <qsygetph.h>
#include <qbnrpii.h>
#include <qusec.h>
#include <mih/callpgmv.h>
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <iconv.h>

#include "ostypes.h"
#include "varchar.h"
#include "apierr.h"
#include "parms.h"
#include "trycatch.h"
#include "strUtil.h"
#include "memUtil.h"
#include "xlate.h"
#define NOX_BUILD
#include "noxDbUtf8.h"
#include "timestamp.h"

__thread extern LGL isoTimestamp;
extern iconv_t xlate_job_to_1208;   // noxDbUtf8.c, opened in nox_Initialize
extern iconv_t xlate_1208_to_job;

#define MAX_ARGS     64     // nox_callProc handles up to 64 parameters
#define MAX_DIGITS   63     // packed / zoned
#define SHORT_VALUE  128    // numbers, dates, times, timestamps

// Graph names and PCML vocabulary - UTF-8 (ASCII) bytes
#pragma convert(1252)
static UCHAR A_EMPTY       [] = "";
static UCHAR A_BLANK       [] = " ";
static UCHAR A_DEF         [] = "def";
static UCHAR A_PARMS       [] = "parms";
static UCHAR A_BUFLEN      [] = "buflen";
static UCHAR A_NAME        [] = "name";
static UCHAR A_TYPE        [] = "type";
static UCHAR A_USE         [] = "use";
static UCHAR A_OFFSET      [] = "offset";
static UCHAR A_SIZE        [] = "size";
static UCHAR A_LENGTH      [] = "length";
static UCHAR A_PREC        [] = "prec";
static UCHAR A_PRECISION   [] = "precision";
static UCHAR A_COUNT       [] = "count";
static UCHAR A_DIM         [] = "dim";
static UCHAR A_FORMAT      [] = "format";
static UCHAR A_SEPARATOR   [] = "separator";
static UCHAR A_STRUCT      [] = "struct";
static UCHAR A_USAGE       [] = "usage";
static UCHAR A_INPUTOUTPUT [] = "inputoutput";
static UCHAR A_OUTPUT      [] = "output";
static UCHAR A_BOOLEAN     [] = "boolean";
static UCHAR A_TRUE        [] = "true";
static UCHAR A_FALSE       [] = "false";
static UCHAR A_CCSID       [] = "ccsid";
static UCHAR A_CHARTYPE    [] = "chartype";
static UCHAR A_TWOBYTE     [] = "twobyte";
static UCHAR A_DATEFORMAT  [] = "dateformat";
static UCHAR A_DATESEP     [] = "dateseparator";
static UCHAR A_TIMEFORMAT  [] = "timeformat";
static UCHAR A_TIMESEP     [] = "timeseparator";
static UCHAR A_OUTPUTSIZE  [] = "outputsize";
static UCHAR A_STRING      [] = "string";
static UCHAR A_DATA        [] = "data";
static UCHAR A_PCML        [] = "pcml";
static UCHAR A_PROGRAM     [] = "program";
static UCHAR A_SERVICE     [] = "service";
static UCHAR A_ENTRYPOINT  [] = "entrypoint";
static UCHAR A_STRUCTS     [] = "__structs__";
static UCHAR A_LEN_SUFFIX  [] = "_LENGTH";
static UCHAR A_ANONYMOUS   [] = "___";
static UCHAR A_T_CHAR      [] = "char";
static UCHAR A_T_PACKED    [] = "packed";
static UCHAR A_T_ZONED     [] = "zoned";
static UCHAR A_T_VARCHAR   [] = "varchar";
static UCHAR A_T_DATE      [] = "date";
static UCHAR A_T_TIME      [] = "time";
static UCHAR A_T_TIMESTAMP [] = "timestamp";
static UCHAR A_T_INT       [] = "int";
static UCHAR A_T_BYTE      [] = "byte";
static UCHAR A_S_HYPHEN    [] = "hyphen";
static UCHAR A_S_PERIOD    [] = "period";
static UCHAR A_S_SLASH     [] = "slash";
static UCHAR A_S_BLANK     [] = "blank";
static UCHAR A_S_COMMA     [] = "comma";
static UCHAR A_S_COLON     [] = "colon";
#pragma convert(0)

#define USE_INPUT  'I'
#define USE_BOTH   'B'

//  local prototype:
static void copyNodeIntoBuffer (PUCHAR pParmBuffer ,PNOX_PARMMETA pParentMeta , PNOX_PARMMETA pMeta, PNOXNODE pParmValueNode );

/* ------------------------------------------------------------- *\
   Character conversion
\* ------------------------------------------------------------- */
typedef struct {
   LONG    from;
   LONG    to;
   iconv_t cd;
} XLATECACHE;
#define XLATE_CACHE_SIZE 8
static __thread XLATECACHE xlateCache [XLATE_CACHE_SIZE];
static __thread int        xlateCacheUsed = 0;

// A conversion descriptor; CCSID 0 is the job's. Descriptors stay open for the job.
static iconv_t * getXlate (LONG from, LONG to)
{
   int i;
   if (from == 1208 && to == 0) return &xlate_1208_to_job;
   if (from == 0 && to == 1208) return &xlate_job_to_1208;

   for (i = 0; i < xlateCacheUsed; i++) {
      if (xlateCache[i].from == from && xlateCache[i].to == to) {
         return &xlateCache[i].cd;
      }
   }
   if (xlateCacheUsed >= XLATE_CACHE_SIZE) {
      return NULL;
   }
   xlateCache[xlateCacheUsed].cd = XlateOpen (from, to, FALSE);
   if (xlateCache[xlateCacheUsed].cd.return_value == -1) {
      return NULL;
   }
   xlateCache[xlateCacheUsed].from = from;
   xlateCache[xlateCacheUsed].to   = to;
   return &xlateCache[xlateCacheUsed++].cd;
}
// Convert at most inLen bytes into at most outSize bytes. Returns the bytes written.
static LONG xlateBounded (LONG from, LONG to, PUCHAR out, LONG outSize, PUCHAR in, LONG inLen)
{
   iconv_t * pcd;
   size_t inLeft  = inLen;
   size_t outLeft = outSize;
   char * pIn  = (char *) in;
   char * pOut = (char *) out;

   if (inLen <= 0 || outSize <= 0) return 0;
   if (from == to) {
      LONG len = inLen < outSize ? inLen : outSize;
      memcpy (out , in , len);
      return len;
   }
   pcd = getXlate (from, to);
   if (pcd == NULL) return 0;
   iconv (*pcd, &pIn, &inLeft, &pOut, &outLeft);
   return outSize - outLeft;
}
// zero terminated string, job CCSID -> UTF-8 ( out must hold strlen(in) * 4 + 1 )
static PUCHAR job2utf8 (PUCHAR out, LONG outSize, PUCHAR in)
{
   LONG len = xlateBounded (0, 1208, out, outSize - 1, in, strlen(in));
   out[len] = '\0';
   return out;
}
// zero terminated string, UTF-8 -> job CCSID
static PUCHAR utf82job (PUCHAR out, LONG outSize, PUCHAR in)
{
   LONG len = xlateBounded (1208, 0, out, outSize - 1, in, strlen(in));
   out[len] = '\0';
   return out;
}
// Blank padded char(10) object name in the job CCSID -> trimmed UTF-8
static PUCHAR objName2utf8 (PUCHAR out, LONG outSize, PUCHAR in)
{
   UCHAR temp [11];
   strtrimncpy (temp, in, 10);
   return job2utf8 (out, outSize, temp);
}
// An integer value from the graph
static LONG getIntByName (PNOXNODE pNode, PUCHAR name, LONG dft)
{
   PUCHAR value = pNode ? nox_GetValuePtr (pNode, name, NULL) : NULL;
   return (value && *value) ? a2i (value) : dft;
}
/* ------------------------------------------------------------- *\
   Text fields: UTF-8 <-> the field's CCSID ( 0 = the job's,
   65535 = binary, copied as is )
\* ------------------------------------------------------------- */
static LONG putText (PUCHAR pBuf, LONG bufLen, LONG ccsid, PUCHAR value, BOOL pad)
{
   LONG len;
   if (ccsid == 65535) {
      len = strlen (value);
      if (len > bufLen) len = bufLen;
      memcpy (pBuf, value, len);
   } else {
      len = xlateBounded (1208, ccsid == 0 ? 0 : ccsid, pBuf, bufLen, value, strlen(value));
   }
   if (pad && len < bufLen) {
      UCHAR blank [8];
      LONG  blankLen = (ccsid == 65535) ? 0 : xlateBounded (1208, ccsid, blank, sizeof(blank), A_BLANK, 1);
      if (blankLen <= 0) {
         memset (pBuf + len, 0x40, bufLen - len);
      } else {
         while (len + blankLen <= bufLen) {
            memcpy (pBuf + len, blank, blankLen);
            len += blankLen;
         }
         if (len < bufLen) memset (pBuf + len, 0x00, bufLen - len);
      }
      len = bufLen;
   }
   return len;
}
// buffer -> UTF-8, zero terminated. out must hold len * 4 + 1 bytes
static PUCHAR getText (PUCHAR out, LONG outSize, LONG ccsid, PUCHAR pBuf, LONG len, BOOL rightTrim)
{
   LONG outLen;
   if (ccsid == 65535) {
      outLen = len < outSize - 1 ? len : outSize - 1;
      memcpy (out, pBuf, outLen);
   } else {
      outLen = xlateBounded (ccsid == 0 ? 0 : ccsid, 1208, out, outSize - 1, pBuf, len);
   }
   out [outLen] = '\0';
   if (rightTrim) {
      while (outLen > 0 && (out[outLen-1] == 0x20 || out[outLen-1] == 0x00)) {
         out[--outLen] = '\0';
      }
   }
   return out;
}
/* ------------------------------------------------------------- */
void getLibraryForSysPtr (_SYSPTR proc, UCHAR * lib)
{
   _MPTR_Template_T op;
   op.Obj_Ptr.Template_Size = sizeof(op);
   matptr (&op, proc);
   memcpy (lib , &op.Obj_Ptr.Library_ID.Name , 10);
}
/* ------------------------------------------------------------- */
_SYSPTR nox_loadServiceProgram (PUCHAR lib , PUCHAR srvPgm)
{
   UCHAR srvPgm_  [11];
   UCHAR lib_     [11];
   _SYSPTR pgm;

   sprintf(srvPgm_ ,"%-10.10s", srvPgm);
   sprintf(lib_    ,"%-10.10s", lib);

   try {
      pgm = rslvsp(WLI_SRVPGM , srvPgm_  , lib_  , _AUTH_OBJ_MGMT);
   }
   catch (NULL) {
      pgm = NULL;
   }
   return pgm;
}
/* ------------------------------------------------------------- */
_SYSPTR nox_loadProc (_SYSPTR srvPgm ,  PUCHAR procName)
{
   _SYSPTR proc = NULL;
   int type = 0;
   UINT64 mark;
   int expNo = 0;
   int expLen = 0;
   int acInfoLen;
   Qle_ABP_Info_t acinfo;
   Qus_EC_t       ec;

   if (srvPgm == NULL) return NULL;

   ec.Bytes_Provided = sizeof(ec);
   ec.Bytes_Available = 0;
   acInfoLen = sizeof(acinfo);
   QleActBndPgmLong(&srvPgm, &mark , &acinfo , &acInfoLen , &ec);
   if (ec.Bytes_Available > 0) return NULL;
   proc = QleGetExpLong(&mark , &expNo  , &expLen , procName , &proc , &type , &ec);
   if (ec.Bytes_Available > 0) return NULL;
   return proc;
}
/* ------------------------------------------------------------- */
_SYSPTR nox_loadServiceProgramProc (PUCHAR lib , PUCHAR srvPgm, PUCHAR procName)
{
   _SYSPTR pgm = nox_loadServiceProgram (lib , srvPgm);
   return nox_loadProc (pgm, procName);
}
/* ------------------------------------------------------------- */
_SYSPTR nox_loadProgram (PUCHAR lib , PUCHAR pgm)
{
   UCHAR pgm_  [11];
   UCHAR lib_  [11];
   _SYSPTR pPgm;

   sprintf(pgm_ , "%-10.10s" , pgm);
   sprintf(lib_ , "%-10.10s" , lib);

   try {
      pPgm = rslvsp(WLI_PGM , pgm_  , lib_  , _AUTH_OBJ_MGMT);
   }
   catch (NULL) {
      pPgm = NULL;
   }
   return pPgm;
}
/* ------------------------------------------------------------- *\
   Buffer side helpers - EBCDIC (job CCSID)
\* ------------------------------------------------------------- */
static int min(int a, int b)
{
   return (a<b) ? a : b;
}
/* ------------------------------------------------------------- */
// Keep sign, digits and the first decimal point; at most MAX_DIGITS digits.
// str2packedMem / str2zonedMem work in fixed buffers, so the input is bounded here.
static PUCHAR cleanNumber (PUCHAR out, PUCHAR in)
{
   PUCHAR p = out;
   int  digits = 0;
   BOOL point = FALSE;
   for (; *in ; in++) {
      if (*in >= '0' && *in <= '9') {
         if (digits < MAX_DIGITS) {
            *p++ = *in;
            digits ++;
         }
      } else if (*in == '-' && p == out) {
         *p++ = '-';
      } else if ((*in == '.' || *in == ',') && ! point) {
         *p++ = '.';
         point = TRUE;
      }
   }
   *p = '\0';
   return out;
}
/* ------------------------------------------------------------- */
static void intToMem (PUCHAR out, PUCHAR in, int len, BOOL isSigned)
{
   if (isSigned) {
      long long v = strtoll (in, NULL, 10);
      switch (len) {
         case 8: *(long long *) out = v; break;
         case 4: *(int *)       out = (int) v; break;
         case 2: *(short *)     out = (short) v; break;
         case 1: *(signed char *) out = (signed char) v; break;
      }
   } else {
      unsigned long long v = strtoull (in, NULL, 10);
      switch (len) {
         case 8: *(unsigned long long *) out = v; break;
         case 4: *(unsigned int *)       out = (unsigned int) v; break;
         case 2: *(unsigned short *)     out = (unsigned short) v; break;
         case 1: *(unsigned char *)      out = (unsigned char) v; break;
      }
   }
}
/* ------------------------------------------------------------- */
static PUCHAR fmtInteger (PUCHAR out, PUCHAR in, int len, BOOL isSigned)
{
   if (isSigned) {
      switch (len) {
         case 8: sprintf (out, "%lld", *(long long *) in); break;
         case 4: sprintf (out, "%d"  , *(int *) in);       break;
         case 2: sprintf (out, "%hd" , *(short *) in);     break;
         case 1: sprintf (out, "%d"  , (int) *(signed char *) in); break;
         default: strcpy (out, "0");
      }
   } else {
      switch (len) {
         case 8: sprintf (out, "%llu", *(unsigned long long *) in); break;
         case 4: sprintf (out, "%u"  , *(unsigned int *) in);       break;
         case 2: sprintf (out, "%hu" , *(unsigned short *) in);     break;
         case 1: sprintf (out, "%u"  , (unsigned) *(unsigned char *) in); break;
         default: strcpy (out, "0");
      }
   }
   return out;
}
/* ------------------------------------------------------------- */
// PCML int: precision 15/31/63 is signed, 16/32/64 unsigned (8 for a 1 byte)
static BOOL isSignedInt (PNOX_PARMMETA pMeta)
{
   return (pMeta->precision % 2 != 0);
}
/* ------------------------------------------------------------- */
// Date formats with 2 digit years are 8 long, the others 10
static BOOL isShortDateFormat (PUCHAR format)
{
   return (0 == strcmp (format, "YMD")
   ||      0 == strcmp (format, "DMY")
   ||      0 == strcmp (format, "MDY"));
}
static UCHAR dateSeparator (PNOX_PARMMETA pMeta)
{
   PUCHAR f = pMeta->format;
   if (*f == '\0' || 0 == strcmp (f, "ISO") || 0 == strcmp (f, "JIS")) return '-';
   if (0 == strcmp (f, "EUR")) return '.';
   if (0 == strcmp (f, "USA")) return '/';
   return pMeta->separatorChar ? pMeta->separatorChar : '/';
}
/* ------------------------------------------------------------- */
// noxDB date (ISO yyyy-mm-dd) -> the parameter's date format
static void dateToBuffer (PUCHAR pBuf, PNOX_PARMMETA pMeta, PUCHAR pIn)
{
   UCHAR iso [11];
   UCHAR sep = dateSeparator (pMeta);
   PUCHAR f = pMeta->format;
   PUCHAR y, m, d;

   strcpy (iso , "0001-01-01");
   memcpy (iso , pIn , min (strlen(pIn), 10));
   y = iso; m = iso + 5; d = iso + 8;

   if (0 == strcmp (f, "EUR")) {          // dd.mm.yyyy
      memcpy (pBuf + 0, d, 2); pBuf[2] = sep; memcpy (pBuf + 3, m, 2); pBuf[5] = sep; memcpy (pBuf + 6, y, 4);
   } else if (0 == strcmp (f, "USA")) {   // mm/dd/yyyy
      memcpy (pBuf + 0, m, 2); pBuf[2] = sep; memcpy (pBuf + 3, d, 2); pBuf[5] = sep; memcpy (pBuf + 6, y, 4);
   } else if (0 == strcmp (f, "YMD")) {   // yy/mm/dd
      memcpy (pBuf + 0, y + 2, 2); pBuf[2] = sep; memcpy (pBuf + 3, m, 2); pBuf[5] = sep; memcpy (pBuf + 6, d, 2);
   } else if (0 == strcmp (f, "DMY")) {   // dd/mm/yy
      memcpy (pBuf + 0, d, 2); pBuf[2] = sep; memcpy (pBuf + 3, m, 2); pBuf[5] = sep; memcpy (pBuf + 6, y + 2, 2);
   } else if (0 == strcmp (f, "MDY")) {   // mm/dd/yy
      memcpy (pBuf + 0, m, 2); pBuf[2] = sep; memcpy (pBuf + 3, d, 2); pBuf[5] = sep; memcpy (pBuf + 6, y + 2, 2);
   } else {                               // ISO, JIS: yyyy-mm-dd
      memcpy (pBuf + 0, y, 4); pBuf[4] = sep; memcpy (pBuf + 5, m, 2); pBuf[7] = sep; memcpy (pBuf + 8, d, 2);
   }
}
/* ------------------------------------------------------------- */
// the parameter's date format -> noxDB date (ISO yyyy-mm-dd), zero terminated
static PUCHAR dateFromBuffer (PUCHAR pOut, PNOX_PARMMETA pMeta, PUCHAR pBuf)
{
   PUCHAR f = pMeta->format;
   UCHAR  y [5] , m [3], d [3];

   strcpy (y , "0001"); strcpy (m , "01"); strcpy (d , "01");

   if (0 == strcmp (f, "EUR")) {
      memcpy (d, pBuf + 0, 2); memcpy (m, pBuf + 3, 2); memcpy (y, pBuf + 6, 4);
   } else if (0 == strcmp (f, "USA")) {
      memcpy (m, pBuf + 0, 2); memcpy (d, pBuf + 3, 2); memcpy (y, pBuf + 6, 4);
   } else if (isShortDateFormat (f)) {
      UCHAR yy [3];
      yy[2] = '\0';
      if (*f == 'Y') {
         memcpy (yy, pBuf + 0, 2); memcpy (m, pBuf + 3, 2); memcpy (d, pBuf + 6, 2);
      } else if (*f == 'D') {
         memcpy (d, pBuf + 0, 2); memcpy (m, pBuf + 3, 2); memcpy (yy, pBuf + 6, 2);
      } else {
         memcpy (m, pBuf + 0, 2); memcpy (d, pBuf + 3, 2); memcpy (yy, pBuf + 6, 2);
      }
      // As RPG: 40-99 is 19xx, 00-39 is 20xx
      sprintf (y, "%s%s", (atoi(yy) >= 40) ? "19" : "20" , yy);
   } else {
      memcpy (y, pBuf + 0, 4); memcpy (m, pBuf + 5, 2); memcpy (d, pBuf + 8, 2);
   }
   sprintf (pOut, "%s-%s-%s", y, m, d);
   return pOut;
}
/* ------------------------------------------------------------- */
// hh.mm.ss or hh:mm:ss -> the parameter's time separator
static void timeToBuffer (PUCHAR pBuf, PNOX_PARMMETA pMeta, PUCHAR pIn)
{
   UCHAR sep = pMeta->separatorChar ? pMeta->separatorChar : '.';
   memcpy (pBuf , "00.00.00", 8);
   memcpy (pBuf , pIn , min (strlen(pIn), 8));
   pBuf[2] = pBuf[5] = sep;
}
/* ------------------------------------------------------------- */
// yyyy-mm-dd-hh.mm.ss.ffffff - also takes ISO 8601 (T and :) and stops at a time zone
static void timestampToBuffer (PUCHAR pBuf, PNOX_PARMMETA pMeta, PUCHAR pIn)
{
   UCHAR ts [40];
   int   i;
   strcpy (ts , "0001-01-01-00.00.00.000000000000");
   for (i = 0; i < pMeta->length && i < 32 && pIn[i] ; i++) {
      UCHAR c = pIn[i];
      if (i >= 19 && (c == 'Z' || c == '+' || c == '-')) break;
      ts[i] = c;
   }
   if (ts[10] == 'T' || ts[10] == ' ') ts[10] = '-';
   if (ts[13] == ':') ts[13] = '.';
   if (ts[16] == ':') ts[16] = '.';
   if (ts[19] == ',') ts[19] = '.';
   memcpy (pBuf , ts , pMeta->length);
}
/* ------------------------------------------------------------- */
static PNOX_PARMMETA getParmDefinition( PNOXNODE pNode)
{
   return (PNOX_PARMMETA) nox_GetNodeAttrValuePtr  (pNode , A_DEF , NULL);
}
/* ------------------------------------------------------------- */
// name suffix is ___ then it is Anonymous Array
static BOOL isAnonymousArray (PUCHAR name)
{
   int l = strlen(name);
   return (l > 3 && 0==memcmp(name + l -3 , A_ANONYMOUS, 3 ));
}
/* ------------------------------------------------------------- */
// The UTF-8 value from the graph into the parameter buffer
static void copyValueIntoBuffer(PUCHAR pBuf, PNOX_PARMMETA pMethodParm , PUCHAR  pValue )
{
   UCHAR value [SHORT_VALUE];
   UCHAR clean [SHORT_VALUE];

   if (pValue == NULL) pValue = A_EMPTY;

   switch (pMethodParm->dType) {
      case NOX_DTYPE_CHAR: {
         // Boolean Hack for backwards compability (PCML-V7)
         if (pMethodParm->length == 1 && (0 == strcmp(pValue, A_FALSE) || 0 == strcmp(pValue, A_TRUE))) {
            *pBuf = (0 == strcmp(pValue, A_FALSE)) ? '0' : '1';
         } else {
            putText (pBuf, pMethodParm->length * pMethodParm->charSize, pMethodParm->ccsid, pValue, TRUE);
         }
         return;
      }
      case NOX_DTYPE_VARCHAR: {
         LONG bytes = putText (pBuf + pMethodParm->precision,
            pMethodParm->length * pMethodParm->charSize, pMethodParm->ccsid, pValue, FALSE);
         ULONG chars = bytes / pMethodParm->charSize;
         if (pMethodParm->precision == 4) {
            *(PULONG)  pBuf = chars;
         } else {
            *(PUSHORT) pBuf = chars;
         }
         return;
      }
      case NOX_DTYPE_BOOL: {
         // '' , '0' and 'f'alse are off - in UTF-8
         *pBuf = (*pValue == '\0' || *pValue == 0x30 || *pValue == 0x66) ? '0' : '1';
         return;
      }
      case NOX_DTYPE_NOX_UNKNOWN:
      case NOX_DTYPE_STRUCTURE:
         return;
   }

   // The rest are short values handled in the job CCSID
   utf82job (value , sizeof(value), pValue);

   switch (pMethodParm->dType) {
      case NOX_DTYPE_INT: {
         intToMem (pBuf, value, pMethodParm->length, isSignedInt (pMethodParm));
         break;
      }
      case NOX_DTYPE_BYTE: {
         *pBuf = (UCHAR) atoi (value);
         break;
      }
      case NOX_DTYPE_PACKED: {
         str2packedMem ( pBuf , cleanNumber (clean, value) , pMethodParm->length, pMethodParm->precision);
         break;
      }
      case NOX_DTYPE_ZONED: {
         str2zonedMem ( pBuf , cleanNumber (clean, value) , pMethodParm->length, pMethodParm->precision);
         break;
      }
      case NOX_DTYPE_DATE: {
         dateToBuffer ( pBuf , pMethodParm, value);
         break;
      }
      case NOX_DTYPE_TIME: {
         timeToBuffer ( pBuf , pMethodParm, value);
         break;
      }
      case NOX_DTYPE_TIME_STAMP: {
         timestampToBuffer ( pBuf , pMethodParm, value);
         break;
      }
   }
}
/* ------------------------------------------------------------- */
static void copyNodeValueIntoBuffer (PUCHAR pParmBuffer, PNOX_PARMMETA pDef, PNOXNODE pValueNode)
{
   PUCHAR pValue = pValueNode ? nox_GetValuePtr (pValueNode , pDef->name , A_EMPTY) : A_EMPTY;
   copyValueIntoBuffer (pParmBuffer, pDef,  pValue );
}
/* ------------------------------------------------------------- */
// An array with a <array>_LENGTH sibling: when the payload does not give the length,
// it is the number of elements the payload has ( at most the dimension ).
// pMembers: the parms / structure members, pBase: where their offsets count from
static void fillArrayLengths (PUCHAR pBase, PNOXNODE pMembers, PNOXNODE pValueNode)
{
   PNOXNODE pMember;
   if (pValueNode == NULL) return;
   for (pMember = nox_GetNodeChild (pMembers); pMember ; pMember = nox_GetNodeNext(pMember)) {
      PNOX_PARMMETA pDef = getParmDefinition (pMember);
      PNOX_PARMMETA pLen;
      PNOXNODE pArray, pElement;
      LONG count = 0;
      if (pDef == NULL || pDef->dim <= 0 || pDef->pLengthMeta == NULL) continue;
      pLen = pDef->pLengthMeta;
      if (nox_GetValuePtr (pValueNode, pLen->name, NULL) != NULL) continue;  // given
      pArray = isAnonymousArray (pDef->name) ? pValueNode : nox_GetNode (pValueNode, pDef->name);
      for (pElement = nox_GetNodeChild (pArray); pElement && count < pDef->dim ; pElement = nox_GetNodeNext (pElement)) {
         count ++;
      }
      switch (pLen->length) {
         case 8: *(long long *) (pBase + pLen->offset) = count; break;
         case 4: *(int *)       (pBase + pLen->offset) = count; break;
         case 2: *(short *)     (pBase + pLen->offset) = count; break;
      }
   }
}
/* ------------------------------------------------------------- */
// Each member of a structure at its own offset
static void copyStructIntoBuffer (PUCHAR pStructBuffer, PNOX_PARMMETA pStructMeta, PNOXNODE pValueNode)
{
   PNOXNODE pMetaElements = nox_GetNodeChild (pStructMeta->pStructure);
   while (pMetaElements) {
      PNOX_PARMMETA pDef = getParmDefinition (pMetaElements);
      if (pDef) {
         if (pDef->pStructure || pDef->dim > 0) {
            copyNodeIntoBuffer (pStructBuffer + pDef->offset, pStructMeta, pDef, pValueNode);
         } else {
            copyNodeValueIntoBuffer (pStructBuffer + pDef->offset, pDef, pValueNode);
         }
      }
      pMetaElements = nox_GetNodeNext(pMetaElements);
   }

   fillArrayLengths (pStructBuffer, pStructMeta->pStructure, pValueNode);
}
/* ------------------------------------------------------------- */
static void copyNodeIntoBuffer (PUCHAR pParmBuffer , PNOX_PARMMETA pParentMeta , PNOX_PARMMETA pMeta ,  PNOXNODE pParmValueNode )
{
   if (pMeta->dim > 0 ) {
      PNOXNODE pArray = isAnonymousArray (pMeta->name) ? pParmValueNode : nox_GetNode (pParmValueNode , pMeta->name);
      PNOXNODE pArrayElement = nox_GetNodeChild (pArray);
      int i;
      for (i=0; i < pMeta->dim && pArrayElement; i++) {
         if (pMeta->pStructure) {
            copyStructIntoBuffer (pParmBuffer, pMeta, pArrayElement);
         } else {
            copyValueIntoBuffer (pParmBuffer, pMeta , nox_GetNodeValuePtr (pArrayElement , A_EMPTY));
         }
         pParmBuffer += pMeta->size;
         pArrayElement = nox_GetNodeNext(pArrayElement);
      }
      // Elements not given: blank / zero as an empty value gives
      for (; i < pMeta->dim ; i++) {
         if (pMeta->pStructure) {
            copyStructIntoBuffer (pParmBuffer, pMeta, NULL);
         } else {
            copyValueIntoBuffer (pParmBuffer, pMeta , A_EMPTY);
         }
         pParmBuffer += pMeta->size;
      }
   } else if (pMeta->pStructure) {
      PNOXNODE pValueNode = nox_GetNode ( pParmValueNode , pMeta->name);
      // If the payload has no element for the top level structure, then map the root payload to it
      if ( pValueNode == NULL && pParentMeta == NULL) {
         pValueNode = pParmValueNode;
      }
      copyStructIntoBuffer (pParmBuffer, pMeta, pValueNode);
   } else {
      copyNodeValueIntoBuffer ( pParmBuffer, pMeta, pParmValueNode);
   }
}
/* ------------------------------------------------------------- */
static PNOXNODE getInterface (PNOX_METHOD pMethod)
{
   return (pMethod->pProc == NULL) ? pMethod->pPgm : pMethod->pProc;
}
/* ------------------------------------------------------------- */
static int buildArgBufferArray (PNOX_METHOD pMethod, PNOXNODE pParms, PVOID argArray [MAX_ARGS] , PUCHAR * ppArgBuffer)
{
   int      args = 0;
   LONG     bufTotlen;
   PUCHAR   pParmBuffer;
   PNOXNODE pInterface, pParmObj;

   pInterface = getInterface (pMethod);
   bufTotlen  = getIntByName (pInterface , A_BUFLEN , 0) ;

   pParmBuffer = memAllocClear (bufTotlen > 0 ? bufTotlen : 1);
   *ppArgBuffer = pParmBuffer;

   pParmObj = nox_GetNodeChild(nox_GetNode ( pInterface , A_PARMS));
   while (pParmObj) {
      PNOX_PARMMETA pMeta = getParmDefinition (pParmObj);
      PUCHAR pBuf = pParmBuffer + pMeta->offset;
      if (args >= MAX_ARGS) return -1;
      argArray [args++] = pBuf;
      copyNodeIntoBuffer (pBuf, NULL , pMeta ,  pParms);
      pParmObj = nox_GetNodeNext(pParmObj);
   }
   fillArrayLengths (pParmBuffer, nox_GetNode ( pInterface , A_PARMS), pParms);
   return args;
}
/* ------------------------------------------------------------- */
// The parameter buffer -> a new UTF-8 graph node
static PNOXNODE newReturnNode (PNOX_PARMMETA pMethodParm, PUCHAR pParmBuffer )
{
   UCHAR    data  [SHORT_VALUE];
   UCHAR    value [SHORT_VALUE * 4];
   PNOXNODE pNode;

   switch (pMethodParm->dType) {
      case NOX_DTYPE_CHAR: {
         LONG   bytes = pMethodParm->length * pMethodParm->charSize;
         LONG   size  = bytes * 4 + 1;
         PUCHAR text  = memAlloc (size);
         getText (text, size, pMethodParm->ccsid, pParmBuffer, bytes, TRUE);
         pNode = NewNode (pMethodParm->name , text , pMethodParm->graphDataType);
         memFree (&text);
         return pNode;
      }
      case NOX_DTYPE_VARCHAR: {
         LONG   chars = (pMethodParm->precision == 4) ? *(PULONG) pParmBuffer : *(PUSHORT) pParmBuffer ;
         LONG   bytes;
         LONG   size;
         PUCHAR text;
         if (chars > pMethodParm->length) chars = pMethodParm->length;
         bytes = chars * pMethodParm->charSize;
         size  = bytes * 4 + 1;
         text  = memAlloc (size);
         getText (text, size, pMethodParm->ccsid, pParmBuffer + pMethodParm->precision, bytes, FALSE);
         pNode = NewNode (pMethodParm->name , text , pMethodParm->graphDataType);
         memFree (&text);
         return pNode;
      }
      case NOX_DTYPE_BOOL: {
         return NewNode (pMethodParm->name , (*pParmBuffer == '1') ? A_TRUE : A_FALSE , NOX_LITERAL);
      }
      case NOX_DTYPE_BYTE: {
         sprintf ( data , "%u" , (unsigned) *(PUCHAR) pParmBuffer);
         break;
      }
      case NOX_DTYPE_INT: {
         fmtInteger (data , pParmBuffer , pMethodParm->length , isSignedInt (pMethodParm));
         break;
      }
      case NOX_DTYPE_PACKED: {
         fmtPacked(data  , pParmBuffer , pMethodParm->length  , pMethodParm->precision , '.');
         break;
      }
      case NOX_DTYPE_ZONED: {
         fmtZoned (data  , pParmBuffer , pMethodParm->length  , pMethodParm->precision, '.');
         break;
      }
      case NOX_DTYPE_DATE: {
         dateFromBuffer  ( data , pMethodParm, pParmBuffer);
         break;
      }
      case NOX_DTYPE_TIME: {
         substr (data, pParmBuffer, 8);
         data[2] = data[5] = '.';
         break;
      }
      case NOX_DTYPE_TIME_STAMP: {
         substr  ( data  ,  pParmBuffer , min (pMethodParm->length, sizeof(data) - 1));
         if (isoTimestamp == ON) {
            ts_ibm2iso8601(data);
         }
         break;
      }
      default: {
         *data = '\0';
      }
   }
   job2utf8 (value, sizeof(value), data);
   return NewNode (pMethodParm->name , value , pMethodParm->graphDataType );
}
/* ------------------------------------------------------------- */
// If we have a length parameter, that is:
// A sibling to the array with the name suffixed by _LENGTH,
// then take its value as the current length - otherwise it is the "dim" value that counts
/* ------------------------------------------------------------- */
static LONG getCurrentLength(PNOX_PARMMETA pMethodParm, PUCHAR pStartBuffer)
{
   PNOX_PARMMETA pLenMeta = pMethodParm->pLengthMeta;
   LONG len = pMethodParm->dim;
   if (pLenMeta && pStartBuffer) {
      switch (pLenMeta->length) {
         case  8: len = *(long long *) (pStartBuffer + pLenMeta->offset); break;
         case  4: len = *(int *      ) (pStartBuffer + pLenMeta->offset); break;
         case  2: len = *(short int *) (pStartBuffer + pLenMeta->offset); break;
      }
   }
   // Never beyond the storage
   if (len < 0 || len > pMethodParm->dim) len = pMethodParm->dim;
   return len;
}
/* ------------------------------------------------------------- */
static void  setReturnObject (PNOXNODE pReturnObject, PNOXNODE pParmObj , PUCHAR pParmBuffer, PUCHAR pParentBuffer, BOOL isArray )
{
   PNOX_PARMMETA pMethodParm = getParmDefinition (pParmObj);
   int i;

   if (pMethodParm == NULL) return;

   if (pMethodParm->dim > 0 && isArray == FALSE) {
      LONG currentLength = getCurrentLength(pMethodParm, pParentBuffer);
      PNOXNODE pTarget;
      if (isAnonymousArray(pMethodParm->name)) {
         pTarget = pReturnObject;
      } else {
         pTarget = nox_NewArray();
         nox_NodeRename (pTarget , pMethodParm->name);
      }
      if (pMethodParm->pStructure) {
         PNOXNODE pStructObj = nox_GetNodeChild(pMethodParm->pStructure);
         for (i = 0 ; i< currentLength ; i++) {
            setReturnObject ( pTarget , pStructObj , pParmBuffer, pParmBuffer, TRUE);
            pParmBuffer += pMethodParm->size;
         }
      } else {
         for (i = 0 ; i< currentLength ; i++) {
            nox_NodeInsertChildTail  ( pTarget , newReturnNode (pMethodParm, pParmBuffer));
            pParmBuffer += pMethodParm->size;
         }
      }
      if (pTarget != pReturnObject) {
         nox_NodeInsertChildTail (pReturnObject , pTarget );
      }
   } else if (isArray) {
      // One element of an array of structures: pParmObj is the first member
      PNOXNODE pReturnStruct = nox_NewObject();
      for (; pParmObj ; pParmObj = nox_GetNodeNext(pParmObj)) {
         PNOX_PARMMETA pStructParm = getParmDefinition (pParmObj);
         if (pStructParm) {
            setReturnObject ( pReturnStruct , pParmObj, pParmBuffer + pStructParm->offset, pParmBuffer, FALSE);
         }
      }
      nox_NodeInsertChildTail (pReturnObject , pReturnStruct );
   } else if (pMethodParm->pStructure) {
      PNOXNODE pStructObj = nox_GetNodeChild(pMethodParm->pStructure);
      PNOXNODE pReturnStruct = isAnonymousArray(pMethodParm->name) ? nox_NewArray() : nox_NewObject();
      nox_NodeRename (pReturnStruct , pMethodParm->name);
      for (; pStructObj ; pStructObj = nox_GetNodeNext(pStructObj)) {
         PNOX_PARMMETA pStructParm = getParmDefinition (pStructObj);
         if (pStructParm) {
            setReturnObject ( pReturnStruct , pStructObj, pParmBuffer + pStructParm->offset, pParmBuffer, FALSE);
         }
      }
      nox_NodeInsertChildTail (pReturnObject , pReturnStruct );
   } else if ( pMethodParm->dontRender == FALSE) {
      nox_NodeInsertChildTail (pReturnObject , newReturnNode (pMethodParm,  pParmBuffer));
   }
}
/* ------------------------------------------------------------- */
static PNOXNODE buildReturnObject (PNOX_METHOD  pMethod, PVOID argArray [MAX_ARGS], PUCHAR pArgBuffer)
{
   PNOXNODE pReturnObject = nox_NewObject();
   PNOXNODE pInterface = getInterface (pMethod);
   PNOXNODE pParmObj = nox_GetNodeChild(nox_GetNode ( pInterface , A_PARMS));
   int argIx;

   for (argIx= 0; pParmObj ;  argIx++, pParmObj = nox_GetNodeNext(pParmObj)) {
      PNOX_PARMMETA pMethodParm = getParmDefinition (pParmObj);
      if (pMethodParm->use == USE_BOTH) {
         setReturnObject (pReturnObject , pParmObj, argArray [argIx], pArgBuffer, FALSE);
      }
   }
   return pReturnObject;
}

/* --------------------------------------------------------------------------- *\
<?xml version="1.0" encoding="UTF-8" ?>
<pcml version="8.0">
  <struct name="employee_t">
    <data name="id" type="int" length="4" precision="31" usage="inherit"/>
    <data name="name" type="char" length="50" usage="inherit"/>
    <data name="age" type="int" length="4" precision="31" usage="inherit"/>
    <data name="income" type="packed" length="9" precision="2" usage="inherit"/>
    <data name="birthDate" type="date" dateformat="ISO" dateseparator="hyphen" usage="inherit"/>
    <data name="birthTime" type="time" timeformat="ISO" timeseparator="period" usage="inherit"/>
    <data name="updated" type="timestamp" usage="inherit"/>
    <data name="isMale" type="char" length="1" boolean="true" usage="inherit"/>
  </struct>
  <program name="complex" entrypoint="COMPLEX">
    <data name="id" type="int" length="4" precision="31" usage="input"/>
    <data name="employee" type="struct" struct="employee_t" usage="inputoutput"/>
  </program>
  <program name="nameAge" entrypoint="NAMEAGE">
    <data name="Name" type="char" length="10" usage="input"/>
    <data name="Text" type="char" length="200" usage="inputoutput"/>
    <data name="Age" type="packed" length="5" precision="0" usage="inputoutput"/>
  </program>
</pcml>
\* --------------------------------------------------------------------------- */

/* --------------------------------------------------------------------------- *\
    Call the program / procedure resolved by the system pointer
    parms: a graph, or a JSON string in the job CCSID
\* --------------------------------------------------------------------------- */
static PNOXNODE  call    (PNOX_METHOD pMethod , PNOXNODE parms, ULONG options)
{
   PNOXNODE pReturnObject;
   PNOXNODE pParms;
   BOOL     freeAfter = FALSE;
   PUCHAR   pArgBuffer = NULL;
   PVOID    argArray[MAX_ARGS];
   int      args;

   if (pMethod->userMethod == NULL) {
      nox_SetMessage ("%s %s/%s not found or not authorized",
         pMethod->userMethodIsProgram ? "Program" : "Procedure",
         pMethod->library,
         pMethod->userMethodIsProgram ? pMethod->program : pMethod->procedure);
      return NULL;
   }
   if (getInterface (pMethod) == NULL) {
      nox_SetMessage ("No PCML for %s/%s %s - compile it with ctl-opt pgminfo(*PCML:*MODULE)",
         pMethod->library, pMethod->program,
         pMethod->userMethodIsProgram ? "" : pMethod->procedure);
      return NULL;
   }

   if (parms != NULL && parms->signature != NOX_NODESIG) {
      LONG   size = strlen ((PUCHAR) parms) * 4 + 1;
      PUCHAR utf8 = memAlloc (size);
      job2utf8 (utf8, size, (PUCHAR) parms);
      pParms = nox_ParseString (utf8);
      memFree (&utf8);
      freeAfter = TRUE;
   } else {
      pParms = parms;
   }

   args = buildArgBufferArray ( pMethod, pParms, argArray, &pArgBuffer);
   if (args < 0) {
      nox_SetMessage ("%s/%s has more than %d parameters", pMethod->library, pMethod->program, MAX_ARGS);
      memFree (&pArgBuffer);
      if (freeAfter) nox_NodeDelete (pParms);
      return NULL;
   }

   if ( pMethod->userMethodIsProgram) {
      nox_callPgm ( pMethod->userMethod , argArray , args );
   } else {
      nox_callProc (pMethod->userMethod , argArray , args);
   }

   pReturnObject = buildReturnObject (pMethod, argArray, pArgBuffer);

   memFree (&pArgBuffer);
   if (freeAfter) {
      nox_NodeDelete (pParms);
   }
   return pReturnObject;
}
/* --------------------------------------------------------------------------- *\
    Retrieve the PCML of each module of a program / service program
    ( QBNRPII: https://www.ibm.com/docs/en/i/7.3?topic=ssw_ibm_i_73/apis/qbnrpii.html )
    Returns the number of PCML documents parsed into ppRoots ( UTF-8 graphs ),
    -1 on error. libFound gets the library the object was found in (job CCSID).
\* --------------------------------------------------------------------------- */
static int retrievePcml (PUCHAR library, PUCHAR program, BOOL isProgram, PUCHAR libFound, PNOXNODE ** ppRoots)
{
   Qbn_PGII0100_t * ppgi;
   Qbn_Interface_Entry_t * pet = NULL;
   Qus_EC_t ec;
   UCHAR    libpgm [20];
   LONG     bufSize = 65536;
   PUCHAR   buffer;
   int      i, count = 0;
   PNOXNODE * pRoots;

   *ppRoots = NULL;
   padncpy ( libpgm      , program , 10 );
   padncpy ( libpgm +10  , library , 10 );

   for (;;) {
      buffer = memAllocClear (bufSize);
      memset (&ec , 0 , sizeof(ec));
      ec.Bytes_Provided = sizeof(ec);
      QBNRPII (
         buffer ,                           /* Receiver variable           */
         bufSize,                           /* Length of receiver variable */
         "RPII0100",                        /* Format name                 */
         libpgm ,                           /* Qualified object name       */
         isProgram ? "*PGM      " : "*SRVPGM   ", /* Object Type          */
         "*ALLBNDMOD          ",            /* Qualified bound module name */
         &ec                                /* Error code                  */
      );
      if (ec.Bytes_Available > 0) {
         nox_SetMessage ("%7.7s retrieving the PCML of %10.10s/%10.10s", ec.Exception_Id, libpgm + 10, libpgm);
         memFree (&buffer);
         return -1;
      }
      ppgi = (Qbn_PGII0100_t *) buffer;
      if (ppgi->Bytes_Available <= bufSize) break;
      bufSize = ppgi->Bytes_Available + 1024;
      memFree (&buffer);
   }

   memcpy (libFound , ppgi->Obj_Lib_Name, 10);
   if (*libFound <= ' ') memcpy (libFound, libpgm + 10 , 10);
   libFound[10] = '\0';

   pRoots = memAllocClear (sizeof(PNOXNODE) * (ppgi->Number_Entries + 1));
   for (i=0; i < ppgi->Number_Entries; i++) {
      LONG   len, size, utf8Len;
      PUCHAR utf8;
      PNOXNODE pRoot;

      LONG   entryOffset = (i == 0) ? ppgi->Offset_First_Entry : pet->Offset_Next_Entry;
      if (entryOffset <= 0 || entryOffset + sizeof(Qbn_Interface_Entry_t) > bufSize) break;
      pet = (Qbn_Interface_Entry_t *) (buffer + entryOffset);
      len = pet->Interface_Info_Length_Ret;
      if (len <= 0 || pet->Offset_Interface_Info + len > bufSize) continue;

      size = len * 4 + 1;
      utf8 = memAlloc (size);
      utf8Len = xlateBounded (pet->Interface_Info_CCSID, 1208, utf8, size - 1, buffer + pet->Offset_Interface_Info, len);
      utf8 [utf8Len] = '\0';
      pRoot = nox_ParseString (utf8);
      memFree (&utf8);
      if (pRoot) {
         pRoots[count++] = pRoot;
      }
   }
   memFree (&buffer);
   *ppRoots = pRoots;
   return count;
}
/* --------------------------------------------------------------------------- */
static void freePcml (PNOXNODE * pRoots, int count)
{
   int i;
   for (i=0; i < count ; i++) {
      nox_NodeDelete (pRoots[i]);
   }
   memFree (&pRoots);
}
/* --------------------------------------------------------------------------- */
// The <pcml> element of a parsed PCML document
static PNOXNODE pcmlElement (PNOXNODE pRoot)
{
   PNOXNODE p = nox_GetNode (pRoot , A_PCML);
   if (p == NULL && pRoot && pRoot->Name && 0 == strcmp (pRoot->Name, A_PCML)) {
      p = pRoot;
   }
   return p;
}
/* --------------------------------------------------------------------------- *\
    Get the pcml from the program  ( UTF-8 graph, as the PCML is )
     https://www.ibm.com/docs/en/i/7.3?topic=syntax-pcml-data-tag
\* --------------------------------------------------------------------------- */
PNOXNODE  nox_ProgramMeta ( PUCHAR library , PUCHAR program)
{
   PNOXNODE * pRoots;
   PNOXNODE pResult;
   UCHAR    libFound [11];
   int i, count = retrievePcml (library, program, TRUE, libFound, &pRoots);
   if (count <= 0) {
      if (pRoots) memFree (&pRoots);
      return NULL;
   }
   // A program has one PCML for its entry module; keep the first
   pResult = pRoots[0];
   for (i=1; i < count ; i++) nox_NodeDelete (pRoots[i]);
   memFree (&pRoots);
   return pResult;
}
/* --------------------------------------------------------------------------- *\
    Get the pcml from a service program: all its modules merged into one <pcml>
\* --------------------------------------------------------------------------- */
PNOXNODE  nox_ProcedureMeta ( PUCHAR library , PUCHAR program , PUCHAR procedure)
{
   PNOXNODE * pRoots;
   PNOXNODE pResult, pPcml;
   UCHAR    libFound [11];
   int i, count = retrievePcml (library, program, FALSE, libFound, &pRoots);
   if (count <= 0) {
      if (pRoots) memFree (&pRoots);
      return NULL;
   }
   pResult = pRoots[0];
   pPcml   = pcmlElement (pResult);
   for (i=1; i < count ; i++) {
      PNOXNODE pFrom = pcmlElement (pRoots[i]);
      PNOXNODE pChild = nox_GetNodeChild (pFrom);
      while (pPcml && pChild) {
         PNOXNODE pNext = nox_GetNodeNext (pChild);
         nox_NodeInsertChildTail (pPcml, nox_NodeUnlink (pChild));
         pChild = pNext;
      }
      nox_NodeDelete (pRoots[i]);
   }
   memFree (&pRoots);
   return pResult;
}
/* --------------------------------------------------------------------------- *\
    Meta graph building - all names and values are UTF-8
\* --------------------------------------------------------------------------- */
static PUCHAR parmMetaValue (PNOXNODE pNode , PUCHAR key)
{
   PUCHAR value = nox_GetAttrValuePtr ( nox_AttributeLookup (  pNode, key));
   return value ? value : A_EMPTY;
}
/* ------------------------------------------------------------- */
static int  parmMetaValueInt (PNOXNODE pNode , PUCHAR key, int dftvalue)
{
   PUCHAR value = nox_GetAttrValuePtr ( nox_AttributeLookup (  pNode, key));
   return (value && *value) ? a2i(value) : dftvalue;
}
/* ------------------------------------------------------------- */
// The parameter definition lives in the "def" attribute of its node.
// NOX_PARMMETA begins with x'00' so it serializes as "", and it is freed with the graph
static void setParmDefinition (PNOXNODE pNode, PNOX_PARMMETA pMeta)
{
   PNOXATTR pAttr;
   nox_SetNodeAttrValue (pNode , A_DEF , A_EMPTY);
   pAttr = nox_AttributeLookup (pNode, A_DEF);
   memFree (&pAttr->Value);
   pAttr->Value = (PUCHAR) pMeta;
}
/* ------------------------------------------------------------- */
// A one character code (job CCSID) as a UTF-8 value
static void setCharByName (PNOXNODE pNode, PUCHAR name, UCHAR c)
{
   UCHAR e [2], a [8];
   e[0] = c;
   e[1] = '\0';
   nox_SetValueByName (pNode, name, job2utf8 (a, sizeof(a), e), NOX_VALUE);
}
/* ------------------------------------------------------------- */
static NOX_DTYPE convertDataType (PUCHAR type)
{
   if      (0 == strcmp(type , A_T_CHAR     )) return NOX_DTYPE_CHAR;
   else if (0 == strcmp(type , A_T_PACKED   )) return NOX_DTYPE_PACKED;
   else if (0 == strcmp(type , A_T_ZONED    )) return NOX_DTYPE_ZONED;
   else if (0 == strcmp(type , A_T_VARCHAR  )) return NOX_DTYPE_VARCHAR;
   else if (0 == strcmp(type , A_T_DATE     )) return NOX_DTYPE_DATE;
   else if (0 == strcmp(type , A_T_TIME     )) return NOX_DTYPE_TIME;
   else if (0 == strcmp(type , A_T_TIMESTAMP)) return NOX_DTYPE_TIME_STAMP;
   else if (0 == strcmp(type , A_T_INT      )) return NOX_DTYPE_INT;
   else if (0 == strcmp(type , A_T_BYTE     )) return NOX_DTYPE_BYTE;
   else if (0 == strcmp(type , A_STRUCT     )) return NOX_DTYPE_STRUCTURE;
   else return NOX_DTYPE_NOX_UNKNOWN;
}
/* ------------------------------------------------------------- */
// PCML separator name -> the separator character in the job CCSID ( 0 = none given )
static UCHAR convertSeparator (PUCHAR pSeparator)
{
   if (*pSeparator == '\0')                 return '\0';
   if (0 == strcmp (pSeparator , A_S_HYPHEN)) return '-';
   if (0 == strcmp (pSeparator , A_S_PERIOD)) return '.';
   if (0 == strcmp (pSeparator , A_S_SLASH )) return '/';
   if (0 == strcmp (pSeparator , A_S_BLANK )) return ' ';
   if (0 == strcmp (pSeparator , A_S_COMMA )) return ',';
   if (0 == strcmp (pSeparator , A_S_COLON )) return ':';
   return '\0';
}
/* --------------------------------------------------------------------------- *\
   Create a new method parameter definition from a PCML <data> element
\* --------------------------------------------------------------------------- */
static PNOX_PARMMETA newMethodParm ( PNOXNODE pParmMeta)
{
   PUCHAR usage;
   PNOX_PARMMETA pMethodParm  = memAllocClear (sizeof(NOX_PARMMETA));

   strncpy (pMethodParm->name , parmMetaValue ( pParmMeta, A_NAME), PROC_NAME_MAX - 1);
   if (0 == strcmp (parmMetaValue ( pParmMeta, A_BOOLEAN), A_TRUE)) {
      pMethodParm->dType  = NOX_DTYPE_BOOL;
   } else {
      pMethodParm->dType  = convertDataType(parmMetaValue ( pParmMeta, A_TYPE));
   }
   usage = parmMetaValue ( pParmMeta, A_USAGE);
   pMethodParm->use       = (0 == strcmp(usage , A_INPUTOUTPUT) || 0 == strcmp(usage , A_OUTPUT)) ? USE_BOTH : USE_INPUT;
   pMethodParm->length    = parmMetaValueInt ( pParmMeta, A_LENGTH, 0);
   pMethodParm->precision = parmMetaValueInt ( pParmMeta, A_PRECISION, 0);
   pMethodParm->dim       = parmMetaValueInt ( pParmMeta, A_COUNT, 0);
   pMethodParm->ccsid     = parmMetaValueInt ( pParmMeta, A_CCSID, 0);
   pMethodParm->charSize  = (0 == strcmp (parmMetaValue ( pParmMeta, A_CHARTYPE), A_TWOBYTE)) ? 2 : 1;
   pMethodParm->size      = pMethodParm->length;
   pMethodParm->graphDataType = NOX_VALUE;
   if (pMethodParm->dim < 0) pMethodParm->dim = 0;
   return pMethodParm;
}
/* --------------------------------------------------------------------------- */
static LONG getTotalStructSize(PNOXNODE pStructure)
{
   LONG totalSize = 0 ;
   PNOXNODE pElements;
   for (pElements = nox_GetNodeChild ( pStructure ) ; pElements ; pElements =  nox_GetNodeNext  (pElements )) {
      PNOX_PARMMETA pMeta = getParmDefinition (pElements);
      if  (pMeta) {
         totalSize += (pMeta->dim > 0) ? pMeta->size * pMeta->dim : pMeta->size;
      }
   }
   return totalSize;
}
/* --------------------------------------------------------------------------- */
static PNOXNODE buildMethodParmObject ( PNOX_PARMMETA pMethodParm, PUCHAR structName)
{
   PNOXNODE  pParmObject = nox_NewObject ();

   // The internal binary definition structure pointer saved in the graph
   setParmDefinition (pParmObject , pMethodParm);

   nox_SetValueByName(pParmObject  , A_NAME  , pMethodParm->name   , NOX_VALUE);
   if (pMethodParm->pStructure) {
      pMethodParm->length = pMethodParm->size =  getTotalStructSize (pMethodParm->pStructure);
      setCharByName     (pParmObject  , A_USE   , pMethodParm->use);
      nox_SetIntByName  (pParmObject  , A_OFFSET, pMethodParm->offset);
      nox_SetIntByName  (pParmObject  , A_SIZE  , pMethodParm->size);
      if (pMethodParm->dim > 0) {
         nox_SetIntByName  (pParmObject  , A_DIM ,  pMethodParm->dim);
      }
      nox_SetValueByName(pParmObject  , A_STRUCT , structName , NOX_VALUE);
   } else {
      setCharByName     (pParmObject  , A_TYPE  , pMethodParm->dType);
      setCharByName     (pParmObject  , A_USE   , pMethodParm->use);
      nox_SetIntByName  (pParmObject  , A_OFFSET, pMethodParm->offset);
      nox_SetIntByName  (pParmObject  , A_SIZE  , pMethodParm->size);
      nox_SetIntByName  (pParmObject  , A_LENGTH, pMethodParm->length);
      nox_SetIntByName  (pParmObject  , A_PREC  , pMethodParm->precision);
      if (*pMethodParm->format) {
         UCHAR format [64];
         nox_SetValueByName(pParmObject  , A_FORMAT, job2utf8 (format, sizeof(format), pMethodParm->format) , NOX_VALUE);
      }
      if (pMethodParm->separatorChar) {
         setCharByName  (pParmObject  , A_SEPARATOR,  pMethodParm->separatorChar);
      }
      if (pMethodParm->ccsid) {
         nox_SetIntByName  (pParmObject  , A_CCSID ,  pMethodParm->ccsid);
      }
      if (pMethodParm->dim > 0) {
         nox_SetIntByName  (pParmObject  , A_DIM ,  pMethodParm->dim);
      }
   }
   return pParmObject;
}
/* --------------------------------------------------------------------------- *\
   The <data> elements of a <struct> or <program>
\* --------------------------------------------------------------------------- */
static PNOXNODE buildParmElements(PNOXNODE pPcmlProgram, PNOXNODE pStructs, PLONG offset, PLONG size)
{
   PNOXNODE pParms    = nox_NewArray ();
   PNOXNODE pParmMeta;

   for (pParmMeta = nox_GetNodeChild (pPcmlProgram); pParmMeta; pParmMeta = nox_GetNodeNext(pParmMeta)) {
      PNOXNODE      pParm;
      PNOX_PARMMETA pMethodParm;
      PUCHAR        structName = A_EMPTY;
      LONG          totSize;

      BOOL          isInlineStruct;

      if (pParmMeta->Name == NULL) continue;
      isInlineStruct = (0 == strcmp (pParmMeta->Name, A_STRUCT));
      if (! isInlineStruct && 0 != strcmp (pParmMeta->Name, A_DATA)) continue;

      pMethodParm = newMethodParm ( pParmMeta);
      if (isInlineStruct) {
         pMethodParm->dType = NOX_DTYPE_STRUCTURE;
      }

      switch ( pMethodParm->dType) {

         case NOX_DTYPE_STRUCTURE: {
            PNOXNODE pChild1 = nox_GetNodeChild ( pParmMeta);
            PNOXNODE pChild2 = nox_GetNodeNext  ( pChild1 );

            // VARCHAR in PCML before V7: <struct name="x" outputsize="42"> ( or <data type="struct"> )
            // with <data name="length" type="int" length="2"/> and <data name="string"/>
            if ((pChild1 && pChild2)
            && ( 0 == strcmp (parmMetaValue ( pChild1, A_NAME) , A_LENGTH)
            &&   0 == strcmp (parmMetaValue ( pChild2, A_NAME) , A_STRING))) {
               pMethodParm->dType = NOX_DTYPE_VARCHAR;
               pMethodParm->precision = parmMetaValueInt ( pChild1, A_LENGTH, 2);
               pMethodParm->size = parmMetaValueInt ( pParmMeta, A_OUTPUTSIZE, 0);
               if (pMethodParm->size <= pMethodParm->precision) {
                  // An input only varchar has no outputsize - its declared length is not in the PCML.
                  // The callee reads only the current length, so give it the room the prefix allows
                  pMethodParm->size = pMethodParm->precision + ((pMethodParm->precision == 4) ? 1048576 : 65535);
               }
               pMethodParm->length = pMethodParm->size - pMethodParm->precision;
               pMethodParm->ccsid    = parmMetaValueInt ( pChild2, A_CCSID, pMethodParm->ccsid);
               pMethodParm->graphDataType = NOX_VALUE;
            } else if (isInlineStruct) {
               // Not a layout we know: keep its room so the next parameters stay in place
               pMethodParm->dType = NOX_DTYPE_NOX_UNKNOWN;
               pMethodParm->size  = parmMetaValueInt ( pParmMeta, A_OUTPUTSIZE, 0);
            } else {
               structName = parmMetaValue ( pParmMeta , A_STRUCT);
               pMethodParm->pStructure  = nox_GetNode  (pStructs , structName);
            }
            break;
         }
         case NOX_DTYPE_CHAR:{
            pMethodParm->size = pMethodParm->length * pMethodParm->charSize;
            break;
         }
         case NOX_DTYPE_VARCHAR: {
            if (pMethodParm->precision == 0) {
               pMethodParm->precision = 2;
            }
            pMethodParm->size = pMethodParm->precision + pMethodParm->length * pMethodParm->charSize;
            break;
         }
         case NOX_DTYPE_INT:
         case NOX_DTYPE_BYTE:
         case NOX_DTYPE_BOOL:
         case NOX_DTYPE_ZONED: {
            pMethodParm->graphDataType = NOX_LITERAL;
            break;
         }
         case NOX_DTYPE_PACKED: {
            pMethodParm->graphDataType = NOX_LITERAL;
            pMethodParm->size = pMethodParm->length / 2 + 1;
            break;
         }
         case NOX_DTYPE_DATE:  {
            utf82job (pMethodParm->format, sizeof(pMethodParm->format), parmMetaValue ( pParmMeta, A_DATEFORMAT));
            pMethodParm->separatorChar = convertSeparator(parmMetaValue ( pParmMeta, A_DATESEP));
            pMethodParm->length = pMethodParm->size = isShortDateFormat (pMethodParm->format) ? 8 : 10;
            break;
         }
         case NOX_DTYPE_TIME:  {
            utf82job (pMethodParm->format, sizeof(pMethodParm->format), parmMetaValue ( pParmMeta, A_TIMEFORMAT));
            pMethodParm->separatorChar = convertSeparator(parmMetaValue ( pParmMeta, A_TIMESEP));
            pMethodParm->length = pMethodParm->size = 8 ;
            break;
         }
         case NOX_DTYPE_TIME_STAMP: {
            if ( *parmMetaValue ( pParmMeta, A_PRECISION) == '\0') {
               pMethodParm->precision = 6;
            }
            if (pMethodParm->precision > 12) pMethodParm->precision = 12;
            pMethodParm->length = (pMethodParm->precision > 0) ? 20 + pMethodParm->precision : 19;
            pMethodParm->size = pMethodParm->length;
            break;
         }
         default:
            break;
      }

      pMethodParm->offset = *offset;

      pParm = buildMethodParmObject (pMethodParm, structName);

      // Setup for next iteration
      totSize = pMethodParm->dim > 0 ? pMethodParm->size * pMethodParm->dim : pMethodParm->size;
      *offset += totSize;
      *size   += totSize;

      nox_ArrayPush ( pParms , pParm , FALSE);
   }
   return pParms;
}
/* --------------------------------------------------------------------------- *\
   Find _LENGTH nodes - map and set attributes
\* --------------------------------------------------------------------------- */
static void setArrayLengthNodes (PNOXNODE pElements)
{
   UCHAR nodeName [PROC_NAME_MAX + 16];
   PNOXNODE pNode;
   for (pNode = nox_GetNodeChild (pElements); pNode ; pNode = nox_GetNodeNext (pNode)) {
      PNOX_PARMMETA pParm = getParmDefinition (pNode);
      PNOXNODE pLookupNode;
      if (pParm == NULL || pParm->dim <= 0) continue;
      strcpy (nodeName , pParm->name);
      strcat (nodeName , A_LEN_SUFFIX);
      for (pLookupNode = nox_GetNodeChild (pElements); pLookupNode ; pLookupNode = nox_GetNodeNext (pLookupNode)) {
         PNOX_PARMMETA pLookupParm = getParmDefinition (pLookupNode);
         if (pLookupParm && 0==strcmp(pLookupParm->name , nodeName)) {
            pLookupParm->dontRender = TRUE;
            pParm->pLengthMeta = pLookupParm;
            break;
         }
      }
   }
}
/* --------------------------------------------------------------------------- *\
   One module's <struct> elements into pStructs ( name -> array of members )
\* --------------------------------------------------------------------------- */
static void buildStructures ( PNOXNODE pStructs , PNOXNODE pPcml)
{
   PNOXNODE pPcmlStruct;
   for (pPcmlStruct = nox_GetNodeChild (pPcml); pPcmlStruct ; pPcmlStruct = nox_GetNodeNext(pPcmlStruct)) {
      LONG offset = 0;
      LONG size   = 0;
      PNOXNODE pElements;
      if (pPcmlStruct->Name == NULL || 0 != strcmp(pPcmlStruct->Name, A_STRUCT)) continue;
      pElements = buildParmElements(pPcmlStruct , pStructs , &offset, &size);
      setArrayLengthNodes (pElements);
      nox_NodeMoveInto (pStructs, parmMetaValue ( pPcmlStruct, A_NAME), pElements );
   }
}
/* --------------------------------------------------------------------------- *\
   One module's <program> elements: entry points with their parameters
\* --------------------------------------------------------------------------- */
static BOOL buildParameters ( PNOXNODE pProgram , PNOXNODE pPcml , PNOXNODE pStructs, BOOL isProgram )
{
   PNOXNODE pPcmlProgram;
   for (pPcmlProgram = nox_GetNodeChild (pPcml); pPcmlProgram ; pPcmlProgram = nox_GetNodeNext(pPcmlProgram)) {
      LONG     offset = 0;
      LONG     size   = 0;
      PNOXNODE pParms;

      if (pPcmlProgram->Name == NULL || 0 != strcmp(pPcmlProgram->Name, A_PROGRAM)) continue;

      pParms = buildParmElements(pPcmlProgram , pStructs , &offset, &size);
      setArrayLengthNodes (pParms);

      if (isProgram ) { // *PGM - the first program element is the entry point
         nox_SetIntByName ( pProgram , A_BUFLEN , size);
         nox_NodeMoveInto ( pProgram , A_PARMS , pParms);
         return TRUE;
      } else {
         PNOXNODE pProcedure = nox_NewObject();
         nox_SetValueByName ( pProcedure , A_ENTRYPOINT , parmMetaValue ( pPcmlProgram, A_ENTRYPOINT), NOX_VALUE);
         nox_SetIntByName   ( pProcedure , A_BUFLEN , size);
         nox_NodeMoveInto   ( pProcedure , A_PARMS  , pParms);
         nox_NodeMoveInto   ( pProgram , parmMetaValue ( pPcmlProgram, A_NAME), pProcedure);
      }
   }
   return FALSE;
}
/* --------------------------------------------------------------------------- *\
   Convert pcml to uniform json used for both programs and service programs:
   { "LIB": { "program"|"service": { "PGM": { "__structs__":{..}, "buflen":n, "parms":[..] } } } }
   ( for a service program each procedure is an object with buflen and parms )
\* --------------------------------------------------------------------------- */
static PNOXNODE applicationMeta ( PUCHAR library , PUCHAR program , BOOL isProgram)
{
   PNOXNODE * pRoots;
   PNOXNODE pResultObject, pLib, pObjectType, pProgram, pStructs;
   UCHAR    libFound [11];
   UCHAR    name [64];
   BOOL     found = FALSE;
   int      i, count;

   count = retrievePcml (library, program, isProgram, libFound, &pRoots);
   if (count <= 0) {
      if (pRoots) memFree (&pRoots);
      if (count == 0) {
         nox_SetMessage ("No PCML in %10.10s/%10.10s - compile it with ctl-opt pgminfo(*PCML:*MODULE)", library, program);
      }
      return NULL;
   }

   pProgram = nox_NewObject();
   pStructs = nox_NewObject();

   for (i=0; i < count ; i++) {
      PNOXNODE pPcml = pcmlElement (pRoots[i]);
      PNOXNODE pModuleStructs = nox_NewObject();
      PNOXNODE pStruct;
      if (pPcml == NULL) {
         nox_NodeDelete (pModuleStructs);
         continue;
      }
      // Each module's parameters refer to that module's structures
      buildStructures ( pModuleStructs , pPcml);
      if (!found) {
         found = buildParameters ( pProgram , pPcml , pModuleStructs, isProgram);
      }
      // Gather them; a name already taken by another module keeps that module's struct only
      // in the definitions that refer to it ( the nodes stay where they are, only moved )
      pStruct = nox_GetNodeChild (pModuleStructs);
      while (pStruct) {
         PNOXNODE pNext = nox_GetNodeNext (pStruct);
         if (nox_GetNode (pStructs , pStruct->Name) == NULL) {
            nox_NodeInsertChildTail (pStructs, nox_NodeUnlink (pStruct));
         }
         pStruct = pNext;
      }
      // Structures with a duplicate name are still referenced: keep them alive with the result
      if (nox_GetNodeChild (pModuleStructs)) {
         UCHAR moduleKey [32];
         sprintf (moduleKey, "%s%d", "__structs__", i);
         nox_NodeMoveInto (pProgram, job2utf8 (name, sizeof(name), moduleKey), pModuleStructs);
      } else {
         nox_NodeDelete (pModuleStructs);
      }
   }
   freePcml (pRoots, count);

   if (nox_GetNodeChild (pStructs)) {
      nox_NodeMoveInto (pProgram, A_STRUCTS, pStructs);
   } else {
      nox_NodeDelete (pStructs);
   }

   pObjectType   = nox_NewObject();
   pLib          = nox_NewObject();
   pResultObject = nox_NewObject();
   nox_NodeMoveInto ( pObjectType   , objName2utf8 (name, sizeof(name), program) , pProgram);
   nox_NodeMoveInto ( pLib          , isProgram ? A_PROGRAM : A_SERVICE , pObjectType);
   nox_NodeMoveInto ( pResultObject , objName2utf8 (name, sizeof(name), libFound) , pLib);
   return pResultObject;
}
/* --------------------------------------------------------------------------- *\
   procedure: *NULL or *PGM for a program, otherwise a service program
\* --------------------------------------------------------------------------- */
PNOXNODE  nox_ApplicationMeta ( PUCHAR library , PUCHAR program , PUCHAR procedure)
{
   BOOL isProgram = (procedure == NULL || 0 == strcmp (procedure , "*PGM"));
   return applicationMeta (library, program, isProgram);
}
/* --------------------------------------------------------------------------- */
// { lib: { program|service: { pgm: {...} } } } -> the pgm object
static PNOXNODE metaObject (PNOXNODE pMeta)
{
   return nox_GetNodeChild (nox_GetNodeChild (nox_GetNodeChild (pMeta)));
}
/* --------------------------------------------------------------------------- */
// A procedure by its PCML name or entry point, any case
static PNOXNODE findProcedure (PNOXNODE pPgm, PUCHAR procedureUtf8)
{
   PNOXNODE pProc;
   for (pProc = nox_GetNodeChild (pPgm); pProc ; pProc = nox_GetNodeNext (pProc)) {
      if (pProc->Name == NULL || pProc->type != NOX_OBJECT) continue;
      if (0 == strncmp (pProc->Name, A_STRUCTS, 11)) continue;
      if (0 == a_stricmp (pProc->Name , procedureUtf8)
      ||  0 == a_stricmp (nox_GetValuePtr (pProc, A_ENTRYPOINT, A_EMPTY), procedureUtf8)) {
         return pProc;
      }
   }
   return NULL;
}
/* --------------------------------------------------------------------------- *\
    Call a program
\* --------------------------------------------------------------------------- */
PNOXNODE  nox_CallProgram (PUCHAR library , PUCHAR program, PNOXNODE parmsP, ULONG optionsP)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PNOXNODE parms   = (pParms->OpDescList == NULL || pParms->OpDescList->NbrOfParms >= 3 ) ? parmsP : NULL;
   ULONG   options  = (pParms->OpDescList == NULL || pParms->OpDescList->NbrOfParms >= 4 ) ? optionsP : 0;
   NOX_METHOD pgm;
   PNOXNODE pResult;

   memset ( &pgm , 0 , sizeof(pgm));
   strtrimncpy (pgm.library   , library , 10);
   strtrimncpy (pgm.program   , program  , 10);
   strcpy      (pgm.procedure , "*PGM");
   pgm.userMethodIsProgram = TRUE;
   pgm.userMethod = nox_loadProgram ( pgm.library, pgm.program);
   if (pgm.userMethod) {
      pgm.pMetaNode  = applicationMeta (pgm.library , pgm.program , TRUE);
      pgm.pPgm       = metaObject (pgm.pMetaNode);
      if (pgm.pPgm && nox_GetNode (pgm.pPgm, A_PARMS) == NULL && getIntByName (pgm.pPgm, A_BUFLEN, -1) < 0) {
         pgm.pPgm = NULL; // no entry point in the PCML
      }
   }
   pgm.pProc = NULL;

   pResult = call (&pgm, parms , options);
   nox_NodeDelete( pgm.pMetaNode );
   return pResult;
}
/* --------------------------------------------------------------------------- *\
    Call a service program procedure
\* --------------------------------------------------------------------------- */
PNOXNODE  nox_CallProcedure (PUCHAR library, PUCHAR srvPgm, PUCHAR procedure, PNOXNODE parmsP, ULONG optionsP)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PNOXNODE parms   = (pParms->OpDescList == NULL || pParms->OpDescList->NbrOfParms >= 4 ) ? parmsP : NULL;
   ULONG   options  = (pParms->OpDescList == NULL || pParms->OpDescList->NbrOfParms >= 5 ) ? optionsP : 0;
   NOX_METHOD pgm;
   PNOXNODE pResult;
   UCHAR    procUtf8 [PROC_NAME_MAX * 4 + 1];

   memset ( &pgm , 0 , sizeof(pgm));
   strtrimncpy (pgm.library   , library , 10);
   strtrimncpy (pgm.program   , srvPgm , 10);
   strtrimncpy (pgm.procedure , procedure ? procedure : "" , PROC_NAME_MAX );
   pgm.userMethodIsProgram = FALSE;
   pgm.userMethod = nox_loadServiceProgramProc ( pgm.library, pgm.program , pgm.procedure);
   if (pgm.userMethod) {
      pgm.pMetaNode  = applicationMeta (pgm.library , pgm.program , FALSE);
      pgm.pPgm       = metaObject (pgm.pMetaNode);
      pgm.pProc      = findProcedure (pgm.pPgm, job2utf8 (procUtf8, sizeof(procUtf8), pgm.procedure));
      if (pgm.pProc == NULL) {
         pgm.pPgm = NULL;  // so the call reports the missing PCML
      }
   }

   pResult = call (&pgm, parms , options);
   nox_NodeDelete( pgm.pMetaNode);
   return pResult;
}
