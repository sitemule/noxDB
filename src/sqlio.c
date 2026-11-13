// CMD:CRTCMOD
/* ------------------------------------------------------------- */
/* Program . . . : sqlio                                         */
/* Design  . . . : Niels Liisberg                                */
/* Function  . . : SQL database I/O                              */
/*                                                               */
/*  SQLCLI documentation:

https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_73/cli/rzadphdapi.htm?lang=da
                                                                */
/* By     Date       PTF     Description                         */
/* NL     21.10.2006         New program                         */
/* NL     16.10.2014         Added to NOXDB library            */
/* ------------------------------------------------------------- */

#include <unistd.h>
#include <wchar.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <decimal.h>
#include <stdarg.h>
#include <ctype.h>
#include <recio.h>
#include <errno.h>
#include <limits.h>
#include <QTQICONV.h>

#include "ostypes.h"
#include "varchar.h"
#include "e2aa2e.h"
#include "xlate.h"
#include "strutil.h"
#include "minmax.h"
#include "parms.h"
#define NOX_BUILD
#include "noxDbUtf8.h"
#include "memUtil.h"
#include "timestamp.h"
#include "sndpgmmsg.h"
#include <mih/matpgmnm.h>


// Until 7.5
#ifndef SQL_BOOLEAN
#define SQL_BOOLEAN            16
#endif

// IBM i SQL CLI option for service programs that can leave the call stack.
// It is not present in older SQL CLI headers, but is supported by Db2 for i.
#ifndef SQL_ATTR_INVOKING_PGM
#define SQL_ATTR_INVOKING_PGM  10037
#endif

// Globals: TODO !!! remove to make code reintrant
__thread extern UCHAR jxMessage[512];
__thread extern BOOL  jxError;
__thread extern LGL   isoTimestamp;
PNOX_SQLCONNECT pLastConnnection = NULL;

extern iconv_t xlate_1200_to_1208;

// !!!!! NOTE every constant in this module is in ASCII
#pragma convert(1252)

/* ------------------------------------------------------------- */
SQLINTEGER nox_sqlCode(PNOX_SQLCONNECT pCon)
{
   return pCon->sqlCode;
}
/* ------------------------------------------------------------- */
static SQLINTEGER getSqlCode(SQLHSTMT hStmt)
{
   SQLCHAR        buffer[SQL_MAX_MESSAGE_LENGTH + 1];
   SQLCHAR        sqlstate[SQL_SQLSTATE_SIZE + 1];
   SQLSMALLINT    length;
   SQLINTEGER     sqlCode;

   SQLError(SQL_NULL_HENV, SQL_NULL_HDBC, hStmt,
      sqlstate,
      &sqlCode,
      buffer,
      SQL_MAX_MESSAGE_LENGTH + 1,
      &length
   );
   return sqlCode;
}
/* ------------------------------------------------------------- */
// Additional data descibing the error can optionally
// be set and found in the envvar MESSAGES_LIST
/* ------------------------------------------------------------- */
static void messageList (PNOXNODE pError)
{

   PUCHAR message;
   message = getenv ("MESSAGES_LIST");
   if (message && *message > ' ') {
      nox_SetValueByName(pError ,  "messages", message, NOX_PARSE_STRING );
      putenv("MESSAGES_LIST=");
   }
}
/* ------------------------------------------------------------- */
/* Convert "in" (zero terminated) with cd into "out" of outSize   */
/* bytes - cut when longer, always zero terminated                */
/* ------------------------------------------------------------- */
extern iconv_t xlate_1208_to_job;   // noxDbUtf8.c, opened in nox_Initialize
extern iconv_t xlate_job_to_1208;
static PUCHAR xlateBounded (iconv_t cd, PUCHAR out, LONG outSize, PUCHAR in)
{
   size_t inLeft  = strlen(in);
   size_t outLeft = outSize - 1;
   char * pIn  = (char *) in;
   char * pOut = (char *) out;
   iconv (cd, &pIn, &inLeft, &pOut, &outLeft);  // stops when out is full
   *pOut = '\0';
   return out;
}
/* ------------------------------------------------------------- */
/* The SQL message texts come in UTF-8 (the connection is in      */
/* UTF-8 mode); jxMessage - nox_Message, the job log - is in the  */
/* job CCSID. stra2e is a 1252 table: each Danish letter in a     */
/* message became two characters                                  */
/* ------------------------------------------------------------- */
static PUCHAR utf8ToJob (PUCHAR out, LONG outSize, PUCHAR in)
{
   return xlateBounded (xlate_1208_to_job, out, outSize, in);
}
/* ------------------------------------------------------------- */
// The error object: msg in the job CCSID, stmt as sent (UTF-8)
static PNOXNODE errorObject(PNOX_SQLCONNECT pCon, PUCHAR msg, PUCHAR sqlstmt)
{
   UCHAR    msgUtf8 [512 * 3 + 1];   // msg: jxMessage / errMsg, job CCSID, 512 at most
   PNOXNODE pError = nox_NewObject();
   nox_SetBoolByName (pError , "success" ,  OFF);
   nox_SetAsciiByName (pError , "msg"    ,  xlateBounded (xlate_job_to_1208, msgUtf8, sizeof(msgUtf8), msg));
   if (sqlstmt) {
      nox_SetAsciiByName  (pError , "stmt"    ,  sqlstmt);
   }
   messageList (pError);
   // the job log messages behind the error (sqldiag.c) - "messages" is NoxDbApi's MESSAGES_LIST
   if (pCon && pCon->pDiag) {
      nox_NodeMoveInto (pError, "joblog", nox_NodeClone(pCon->pDiag));
   }

   return pError;
}
// NOX_GRACEFUL_ERROR: the error of the function that failed
PNOXNODE static sqlErrorObject(PNOX_SQLCONNECT pCon, PUCHAR sqlstmt)
{
   return errorObject (pCon, jxMessage, sqlstmt);
}
/* ------------------------------------------------------------- */
// Exported: the error object of the last statement on this connection - the same
// object NOX_GRACEFUL_ERROR gives - for functions that only return an indicator
// (nox_sqlExec, nox_sqlUpdate, nox_sqlInsert ...). {"success":true} when it did not fail
PNOXNODE nox_sqlErrorObject (PNOX_SQLCONNECT pCon)
{
   PNOXNODE pOk;
   if (pCon && pCon->hasError == ON) {
      return errorObject (pCon, pCon->errMsg, pCon->errStmt);
   }
   pOk = nox_NewObject();
   nox_SetBoolByName (pOk , "success" , ON);
   return pOk;
}
/* ------------------------------------------------------------- */
// Read the error into sqlCode / sqlState / jxMessage and collect the job log
// messages behind it - the statement stays open (the caller owns it)
/* ------------------------------------------------------------- */
static void sqlError (PNOX_SQLCONNECT pCon, PNOX_SQL pSQL)
{
   SQLSMALLINT length;
   ULONG l;
   int rc;

   SQLHANDLE     handle;
   SQLSMALLINT   hType = SQL_HANDLE_ENV;

   SQLHENV       henv  = SQL_NULL_HENV;
   SQLHDBC       hdbc  = SQL_NULL_HDBC;
   SQLHSTMT      hstmt = pSQL && pSQL->pstmt? pSQL->pstmt->hstmt : SQL_NULL_HSTMT;
   UCHAR         sqlState[SQL_SQLSTATE_SIZE + 1]; // 5 + zero terminator (#148)
   UCHAR         sqlMsgDta[SQL_MAX_MESSAGE_LENGTH + 1];
   PUCHAR        psqlState  = sqlState;
   SQLINTEGER*   psqlCode   = &pCon->sqlCode;
   PUCHAR        psqlMsgDta = sqlMsgDta;

   if (pSQL && pSQL->pstmt) {
      hType  =  SQL_HANDLE_STMT;
      handle =  pSQL->pstmt->hstmt;
   } else if ( pCon) {
      if (pCon->hdbc) {
         hType  =  SQL_HANDLE_DBC;
         handle =  pCon->hdbc;
      } else {
         hType  =  SQL_HANDLE_ENV;
         handle =  pCon->henv;
      }
      psqlState  = pCon->sqlState;
      psqlCode   = &pCon->sqlCode;
      psqlMsgDta = pCon->sqlMsgDta;
   }

   length = 0;
   rc = SQLGetDiagRec(hType , handle, 1, psqlState, psqlCode, psqlMsgDta,  sizeof(sqlMsgDta), &length);
   if (rc == SQL_SUCCESS || rc == SQL_SUCCESS_WITH_INFO) {
      // jxMessage is in the job CCSID, the message text only - as nox_sqlExecDirectTrace has it
      if (length > SQL_MAX_MESSAGE_LENGTH) length = SQL_MAX_MESSAGE_LENGTH;
      psqlMsgDta[length] = '\0';
      utf8ToJob (jxMessage , sizeof(jxMessage) , psqlMsgDta);
   } else {
      // no diagnostic record (already read by someone else): never print the empty buffers
      UCHAR temp [64];
      a_sprintf (temp , "SQL error %ld - no diagnostic record" , (long) *psqlCode);
      stra2e (jxMessage , temp);
   }
   nox_sqlDiagCollect (pCon, pSQL ? pSQL->sqlstmt : NULL);
   jxError = true;
}
/* ------------------------------------------------------------- */
// Read the error and close the statement
static int check_error (PNOX_SQLCONNECT pCon, PNOX_SQL pSQL)
{
   sqlError (pCon, pSQL);
   nox_sqlClose (&pSQL); // Free the data
   return 0;
}
/* ------------------------------------------------------------- */
static int sqlEscape (PUCHAR out  , PUCHAR in)
{
    PUCHAR p = out;
    UCHAR  fnyt = '\'';
    int len;

    *p++ = fnyt;
    for (;*in; in++) {
      if (*in == fnyt) {
         *p++ = fnyt;
      }
      *p++ = *in;
      }
   *p++ = fnyt;
   *p   = '\0';
   len = p - out;
   return len;
}
/* ------------------------------------------------------------- */
static int insertMarkerValue (PUCHAR buf , PUCHAR marker, PNOXNODE parms)
{
   int len =0;
   PNOXNODE pNode;
   PUCHAR value;

   pNode = nox_GetNode   ( parms , marker);
   if (pNode) {
      value = nox_GetValuePtr  ( pNode , "" , NULL );
      if (value == NULL) {
         strcpy(buf, "null");
         len = strlen(buf);
      } else if (pNode->isLiteral) {
         strcpy(buf, value);
         len = strlen(buf);
      } else {
         len = sqlEscape (buf , value);
      }
   } else {
      // TODO !! Experimental  - not found gives an empty string
      // Then statement will not fail
      strcpy(buf, "''");
      len = 2;
   }

   return len;
}
/* ------------------------------------------------------------- */
LGL nox_sqlStartTransaction (PNOX_SQLCONNECT pCon)
{
   int rc;
   LONG   attrParm;

   pCon->transaction = true;

   attrParm = SQL_FALSE;
   rc = SQLSetConnectAttr(pCon->hdbc, SQL_ATTR_AUTOCOMMIT, &attrParm, 0) ;

   attrParm = SQL_TXN_REPEATABLE_READ;
   // attrParm = SQL_TXN_READ_UNCOMMITTED; // does not work for updates !!! can noet bes pr- statemnet
   rc = SQLSetConnectAttr (pCon->hdbc, SQL_ATTR_COMMIT , &attrParm  , 0);

   return (rc==0) ? OFF:ON;
}
/* ------------------------------------------------------------- */
static LGL nox_sqlCommitOrRollback(PNOX_SQLCONNECT pCon , int type)
{

   int rc1;
   int rc2;
   int rc3;
   LONG   attrParm;


   pCon->transaction = false;

   rc1 = SQLTransact (
      SQL_HANDLE_DBC,
      pCon->hdbc,
      type
   );

   if (rc1!=0) {
      //check_error (NULL);
   }

   attrParm = SQL_TXN_NO_COMMIT; // does not work with BLOBS
   rc2 = SQLSetConnectAttr (pCon->hdbc, SQL_ATTR_COMMIT , &attrParm  , 0);

   attrParm = SQL_TRUE;
   rc3 = SQLSetConnectAttr(pCon->hdbc, SQL_ATTR_AUTOCOMMIT, &attrParm, 0) ;

   return (rc1==0) ? OFF:ON;

   return OFF;
}
/* ------------------------------------------------------------- */
LGL nox_sqlCommit(PNOX_SQLCONNECT pCon)
{
   return nox_sqlCommitOrRollback(pCon, SQL_COMMIT_HOLD);
}
/* ------------------------------------------------------------- */
LGL nox_sqlRollback(PNOX_SQLCONNECT pCon)
{
   return nox_sqlCommitOrRollback(pCon, SQL_ROLLBACK_HOLD);
}
/* ------------------------------------------------------------- */
int nox_sqlExecDirectTrace(PNOX_SQLCONNECT pCon, PNOX_SQL pSQL , int hstmt, PUCHAR sqlstmt)
{

   int rc, rc2;
   BOOL doClose = FALSE;
   SQLSMALLINT   length   = 0;
   LONG          lrc;
   PUCHAR        psqlState  = "";
   PNOX_TRACE     pTrc = &pCon->sqlTrace;

   pCon->sqlCode = 0; // TODO re-entrant !!
   memset ( pCon->sqlState , ' ' , 5);
   ts_nowstr(pTrc->tsStart); // TODO !!! not form global
   rc = SQLExecDirect( hstmt, sqlstmt, SQL_NTS);
   if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
      doClose = TRUE;
      jxError = TRUE;
      rc2= SQLGetDiagRec(SQL_HANDLE_STMT,hstmt,1,pCon->sqlState,&pCon->sqlCode, pTrc->text,sizeof(pTrc->text), &length);
      pTrc->text[length] = '\0';
      utf8ToJob (jxMessage , sizeof(jxMessage) , pTrc->text );
      joblog (jxMessage);
      nox_sqlDiagCollect (pCon, sqlstmt);
   }
   pTrc->text [length] = '\0';
   ts_nowstr(pTrc->tsEnd); // TODO !!! not form global
   nox_traceInsert ( pSQL , sqlstmt , pCon->sqlState);

   if (doClose) {
      nox_sqlClose (&pSQL); // Free the data
   }
   return rc; // we have an error
}
/* ------------------------------------------------------------- */
// TODO !! Note the public - changed behaviour : marker are now: ${ value }
PUCHAR strFormat (PUCHAR out, PUCHAR in , PNOXNODE parms)
{
   PUCHAR p, pMarker, res = out;
   PNOXNODE pParms = parms;
   int markerLen ;
   UCHAR marker [64];


   if (parms == NULL) {
      strcpy(out , in);
      return out;
   }

   if (OFF == nox_isNode (parms)) {
      pParms =  nox_ParseString((PUCHAR) parms);
   }

   while (*in) {
      if (in[0] == '$' && in[1] == '{' ) {
         in += 2; // Skip ${
         pMarker = in;
         for (;*in && *in != '}' ; in++);
         markerLen = in - pMarker ;
         if (markerLen >= sizeof(marker)) markerLen = sizeof(marker) - 1;
         if (markerLen > 0) {
            substr(marker , pMarker , markerLen );
            a_trim_both(marker);
            out += insertMarkerValue (out , marker, pParms );
         }
         if (*in == '}') in++; // skip the termination
      } else {
         *(out++) = *(in++);
      }
   }
   *(out++) =  '\0';

   if (OFF == nox_isNode (parms)) {
      nox_NodeDelete (pParms);
   }

   return res;
}
/* ------------------------------------------------------------- */
/* The length strFormat writes for "in" with the ${ } markers     */
/* filled in from pParms (a node) - not counting the terminator.  */
/* An escaped value is counted with all its quotes doubled, so    */
/* this is an upper bound.                                        */
/* ------------------------------------------------------------- */
static LONG strFormatLength (PUCHAR in , PNOXNODE pParms)
{
   PUCHAR pMarker, value;
   PNOXNODE pNode;
   int markerLen ;
   UCHAR marker [64];
   LONG len = 0;

   if (pParms == NULL) return strlen(in);

   while (*in) {
      if (in[0] == '$' && in[1] == '{' ) {
         in += 2; // Skip ${
         pMarker = in;
         for (;*in && *in != '}' ; in++);
         markerLen = in - pMarker ;
         if (markerLen >= sizeof(marker)) markerLen = sizeof(marker) - 1;
         if (markerLen > 0) {
            substr(marker , pMarker , markerLen );
            a_trim_both(marker);
            pNode = nox_GetNode ( pParms , marker);
            if (pNode == NULL) {
               len += 2;                       // ''
            } else {
               value = nox_GetValuePtr ( pNode , "" , NULL );
               if (value == NULL) {
                  len += 4;                    // null
               } else if (pNode->isLiteral) {
                  len += strlen(value);
               } else {
                  len += 2 * strlen(value) + 2; // quoted, quotes doubled
               }
            }
         }
         if (*in == '}') in++; // skip the termination
      } else {
         len++;
         in++;
      }
   }
   return len;
}
/* ------------------------------------------------------------- */
/* strFormat into a buffer of its own, big enough for the result  */
/* plus "extra" bytes the caller appends. Free it with memFree    */
/* ------------------------------------------------------------- */
static PUCHAR strFormatAlloc (PUCHAR in , PNOXNODE parms, LONG extra)
{
   PNOXNODE pParms = parms;
   PUCHAR out;

   if (parms != NULL && OFF == nox_isNode (parms)) {
      pParms = nox_ParseString((PUCHAR) parms);
   }

   out = memAlloc (strFormatLength (in , pParms) + extra + 1);
   strFormat (out , in , pParms);

   if (pParms != parms) {
      nox_NodeDelete (pParms);
   }
   return out;
}
/* ------------------------------------------------------------- */
static PNOX_SQL nox_sqlNewStatement(PNOX_SQLCONNECT pCon, PNOXNODE pSqlParms, BOOL exec, BOOL scroll)
{
   PNOX_SQL pSQL;
   PNOX_SQLSTMT pStmt;
   SHORT i;
   int rc;
   LONG   attrParm;

   if (pCon == NULL) return NULL;
   pCon->sqlCode = 0;
   nox_sqlDiagStart (pCon);

   pSQL = memAllocClear(sizeof(NOX_SQL));
   pSQL->pCon = pCon;
   pSQL->rowcount = -1;
   pSQL->pstmt        = memAlloc(sizeof(NOX_SQLSTMT));
   pSQL->pstmt->hstmt = 0;
   pSQL->pstmt->exec  = exec;

   // allocate  and initialize with defaults
   rc = SQLAllocStmt(pCon->hdbc, &pSQL->pstmt->hstmt);
   if (rc != SQL_SUCCESS ) {
      check_error (pCon, pSQL);
      return NULL; // we have an error
   }

   if (exec) {
      // This need to allow update
      attrParm = SQL_INSENSITIVE;
      rc = SQLSetStmtAttr  (pSQL->pstmt->hstmt, SQL_ATTR_CURSOR_SENSITIVITY , &attrParm  , 0);
      if (rc != SQL_SUCCESS ) {
         check_error (pCon, pSQL);
         return NULL; // we have an error
      }

   } else {
      if (scroll) {
         attrParm = SQL_TRUE;
         rc = SQLSetStmtAttr  (pSQL->pstmt->hstmt, SQL_ATTR_CURSOR_SCROLLABLE , &attrParm  , 0);
         if (rc != SQL_SUCCESS ) {
            check_error (pCon, pSQL);
            return NULL; // we have an error
         }
      }

      attrParm = SQL_TRUE;
      rc = SQLSetStmtAttr  (pSQL->pstmt->hstmt, SQL_ATTR_EXTENDED_COL_INFO , &attrParm  , 0);
      if (rc != SQL_SUCCESS ) {
         check_error (pCon, pSQL);
         return NULL; // we have an error
      }


      attrParm = SQL_CONCUR_READ_ONLY;
      rc = SQLSetStmtAttr  (pSQL->pstmt->hstmt, SQL_ATTR_CONCURRENCY , &attrParm  , 0);
      if (rc != SQL_SUCCESS ) {
         check_error (pCon, pSQL);
         return NULL; // we have an error
      }
   }
   return pSQL;
}
/* ------------------------------------------------------------- */
// ------------------------------------------------------------------
// https://www.ibm.com/docs/en/i/7.4?topic=program-null-capable-fields

// ------------------------------------------------------------------
static PUCHAR  getSysNameForColumn ( PUCHAR sysColumnName, PUCHAR columnText, SQLHSTMT hstmt , SQLSMALLINT columnNo)
{
   SQLRETURN     rc;
   SQLSMALLINT   len1=0, len2=0, len3=0;
   SQLINTEGER    numlen;

   UCHAR column [256];
   UCHAR table  [256];
   UCHAR schema [256];

   rc = SQLColAttribute (hstmt, columnNo , SQL_DESC_BASE_SCHEMA , schema, sizeof(schema), &len1 , &numlen);
   rc = SQLColAttribute (hstmt, columnNo , SQL_DESC_BASE_TABLE  , table , sizeof(table) , &len2 , &numlen);
   rc = SQLColAttribute (hstmt, columnNo , SQL_DESC_BASE_COLUMN , column, sizeof(column), &len3 , &numlen);

   if (len1 == 0 || len2 == 0 || len3 == 0 ) {
      return NULL;
   }

   schema [len1] = '\0';
   table  [len2] = '\0';
   column [len3] = '\0';

   // need to convert all the Db2 data from ascii to EBCDIC
   stra2e (schema  , schema );
   stra2e (table   , table );
   stra2e (column  , column );

   PUCHAR pSysName =  getSystemColumnName ( sysColumnName, columnText, schema , table , column);

   // need to convert all the meta data  from EBCDIC to ascii
   stre2a (sysColumnName , sysColumnName );
   stra2e (columnText    , columnText );

   return pSysName;

}

/* -------------------------------------------------------------
   Locates the part after last parenthesis
   ------------------------------------------------------------- */
PUCHAR finalSQLPart (PUCHAR stmt)
{
   PUCHAR end = stmt;
   PUCHAR temp;
   for (;;) {
      temp = strchr ( end  , ')');
      if (temp == NULL) break;
      end = temp + 1 ;
   }
   return end;
}
BOOL findHasLimit  (PUCHAR sqlStmt)
{
   PUCHAR p = a_stristr(sqlStmt, "limit ");
   if (p && *(p -1) == ' ') {
      UCHAR temp [10];
      substr ( temp , p+6, 3);
      if ( a_str_to_dec ( temp , ',' ) > 0) {
         return true;
      }
   }
   return false;
}
/* ------------------------------------------------------------- */
/* Poyfill for regex                                             */
/* ------------------------------------------------------------- */
BOOL findHasOffset  (PUCHAR sqlStmt)
{
   PUCHAR p = a_stristr(sqlStmt, "offset ");
   if (p && *(p -1) == ' ') {
      UCHAR temp [10];
      substr ( temp , p+6, 3);
      if ( a_str_to_dec ( temp , ',' ) > 0) {
         return true;
      }
   }
   return false;
}
/* ------------------------------------------------------------- */
/* Poyfill for regex                                             */
/* ------------------------------------------------------------- */
BOOL findHasFetch  (PUCHAR sqlStmt)
{
   PUCHAR p = a_stristr(sqlStmt, "fetch ");
   if (p && *(p -1) == ' ') {
      PUCHAR p2 = a_stristr(p , "first ");
      if (p2 && *(p2 -1) == ' ') {
            return true;
      }
   }
   return false;
}


/* ------------------------------------------------------------- */
/* A query: select, with (common table expression) or (select ...)*/
/* - not call, values, insert, update, delete, merge ...          */
/* ------------------------------------------------------------- */
static BOOL isQuery (PUCHAR stmt)
{
   PUCHAR p = stmt;
   for (;*p == '(' || (*p > '\0' && *p <= ' '); p++);
   if (0 == memicmp (p , "select" , 6) && (p[6] <= ' ' || p[6] == '*' || p[6] == '(')) return true;
   if (0 == memicmp (p , "with"   , 4) &&  p[4] <= ' ') return true;
   return false;
}
/* ------------------------------------------------------------- */
/* The clauses that end a query and must stay last: returns where */
/* the first of them starts (or NULL); *pIsolation when one of    */
/* them sets the isolation ("with cs", "for update" ...)          */
/* ------------------------------------------------------------- */
static PUCHAR findTrailingClause (PUCHAR lookFrom, BOOL * pIsolation)
{
   static const struct { PUCHAR text; BOOL isolation; } clauses [] = {
      { " for update"     , true  },
      { " for read only"  , false },
      { " for fetch only" , false },
      { " optimize for"   , false },
      { " skip locked"    , false },
      { " use and keep"   , true  },
      { " with nc"        , true  },
      { " with ur"        , true  },
      { " with cs"        , true  },
      { " with rs"        , true  },
      { " with rr"        , true  },
   };
   PUCHAR first = NULL;
   int i;

   *pIsolation = false;
   for (i = 0; i < sizeof(clauses) / sizeof(clauses[0]); i++) {
      PUCHAR p = a_stristr (lookFrom , clauses[i].text);
      if (p) {
         UCHAR after = p [strlen(clauses[i].text)];
         if (after > ' ') continue;   // e.g. " with urgency" - not the clause
         if (clauses[i].isolation) *pIsolation = true;
         if (first == NULL || p < first) first = p;
      }
   }
   return first;
}
/* ------------------------------------------------------------- */

PNOX_SQL nox_sqlOpen(PNOX_SQLCONNECT pCon, PUCHAR sqlstmt , PNOXNODE pSqlParmsP, LONG formatP , LONG startP , LONG limitP)
{

   PUCHAR sqlTempStmt;
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PNOXNODE pSqlParms =  (pParms->OpDescList->NbrOfParms >= 2 ) ? pSqlParmsP : NULL;
   LONG   format      =  (pParms->OpDescList->NbrOfParms >= 3 ) ? formatP : 0;
   LONG   start       =  (pParms->OpDescList->NbrOfParms >= 4 ) ? startP : NOXDB_FIRST_ROW; // begining
   LONG   limit       =  (pParms->OpDescList->NbrOfParms >= 5 ) ? limitP : NOXDB_ALL_ROWS; // all rows
   LONG   attrParm;
   LONG   i;
   UCHAR  typeName [256];
   LONG   tprc;
   PNOX_SQL pSQL;
   SQLINTEGER  dummyInt , isTrue,descLen;
   SQLSMALLINT len ,dummyShort;
   BOOL scroll = pParms->OpDescList->NbrOfParms <= 3; // Typicall from CALL from RPG
   int rc;

   jxError = false; // Assume OK

   // quick trim - advance the pointer until data:
   for  (;*sqlstmt > '\0' && *sqlstmt <= ' '; sqlstmt++);

   pSQL = nox_sqlNewStatement (pCon, NULL, false, scroll);
   if  ( pSQL == NULL) return NULL;

   if ( pCon->options.hexSort == ON ) {
      LONG attrParm = SQL_FALSE ;
      rc = SQLSetEnvAttr  (pCon->henv, SQL_ATTR_JOB_SORT_SEQUENCE , &attrParm  , 0);
   }

   // build the final sql statement - in a buffer sized from the statement and the values
   // filled in, with room for what is appended below: " limit n " " offset n " " with ur"
   // (the trailing clause is moved, not added)
   sqlTempStmt = strFormatAlloc (sqlstmt , pSqlParms , 64);

   //// huxi !! need uncomitted read for blob fields
   // and IBM i does not support statement attribute to set the pr statement. :/
   // so we simply append the "with ur" uncommited read options
   // Only a query gets "limit" / "offset" and "with ur". An INSERT / UPDATE / DELETE / MERGE
   // sent here (e.g. through a "sql to json" service) must run as written: "with ur" makes Db2
   // run it with isolation CS under commitment control, and with autocommit off it then stays
   // uncommitted and keeps its rows locked until the job ends
   if (isQuery (sqlTempStmt)) {
      PUCHAR lookFrom = finalSQLPart (sqlTempStmt);
      PUCHAR trailer;
      UCHAR  tail [256];
      BOOL hasLimit  ;
      BOOL hasOffset ;
      BOOL hasFetch  ;
      BOOL hasIsolation;
      PUCHAR end;

      // Before we begin adding to the statement  - ensure is does not end with a ;
      for (end = sqlTempStmt + strlen(sqlTempStmt) -1  ; end > sqlTempStmt; end--) {
         if (*end == ';') *end = ' ';
         if (*end > ' ') break;
      }
      *(end + 1) = '\0';

      hasLimit  = findHasLimit  (lookFrom);
      hasOffset = findHasOffset (lookFrom);
      hasFetch  = findHasFetch  (lookFrom);

      // "limit" and "offset" go before a trailing "for update", "optimize for", "with cs" ...
      trailer = findTrailingClause (lookFrom, &hasIsolation);
      *tail = '\0';
      if (trailer && strlen(trailer) < sizeof(tail)) {
         strcpy (tail , trailer);
         *trailer = '\0';
      }

      if (limit > 0 && ! hasFetch && ! hasLimit) {
         a_sprintf (sqlTempStmt + strlen(sqlTempStmt)," limit %ld ", limit);
      }
      // Note !! Offset is "Number if rows to skip" therefor the -1 from the "start"
      if (start > 1 && ! hasOffset) {
         a_sprintf (sqlTempStmt + strlen(sqlTempStmt)," offset %ld ", start - 1);
      }
      strcat (sqlTempStmt , tail);

      //// huxi !! need uncomitted read for blob fields
      // and IBM i does not support statement attribute to set the pr statement. :/
      // so we simply append the "with ur" uncommited read options - unless the statement
      // has its own isolation or is "for update" (that needs a lock)
      if (pCon->transaction == false && ! hasIsolation) {
         strcat ( sqlTempStmt , " with ur");
      }
   }
   pSQL->sqlstmt = strdup(sqlTempStmt);
   memFree ((PVOID *) &sqlTempStmt);

   rc = nox_sqlExecDirectTrace(pCon, pSQL , pSQL->pstmt->hstmt, pSQL->sqlstmt);
   if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
      // is checked in abowe    check_error (pSQL);
      return NULL; // we have an error
   }

   // Number of rows? .. No does not work :(
   /*
   SQLGetDiagField(SQL_HANDLE_STMT,pSQL->pstmt->hstmt, 0 ,SQL_DIAG_ROW_COUNT,&pSQL->rowcount,0, NULL);
   */

   /*
   // Row count is only affected row in a "delete" or "update" ..TODO find a solution for select
   rc = SQLRowCount (pSQL->pstmt->hstmt, &pSQL->rowcount);
   if (rc != SQL_SUCCESS ) {
      check_error (pSQL);
      return NULL; // we have an error
   }
   */

   rc = SQLNumResultCols (pSQL->pstmt->hstmt, &pSQL->nresultcols);
   if (rc != SQL_SUCCESS ) {
      check_error (pCon, pSQL);
      return NULL; // we have an error
   }
   pSQL->cols = memAlloc (pSQL->nresultcols * sizeof(NOXCOL));

   for (i = 0; i < pSQL->nresultcols; i++) {
       int labelRc;
      UCHAR colText  [256];
      PNOXCOL pCol = &pSQL->cols[i];

      rc = SQLDescribeCol (
         pSQL->pstmt->hstmt,
         i+1,
         pCol->colname,
         sizeof (pCol->colname),
         &pCol->colnamelen,
         &pCol->coltype,
         &pCol->collen,
         &pCol->scale,
         &pCol->nullable
      );

      pCol->colname[pCol->colnamelen] = '\0';
      strcpy (pCol->realname , pCol->colname);

      if (format & (NOX_SYSTEM_NAMES | NOX_COLUMN_TEXT)) {
           if (NULL == getSysNameForColumn ( pCol->sysname , colText , pSQL->pstmt->hstmt , i+1)) {
               strcpy (pCol->sysname , pCol->colname);
               strcpy (colText       , pCol->colname);
           }
      } else {
         *pCol->sysname = '\0';
      }

      if (format & (NOX_COLUMN_TEXT)) {
         strcpy (pCol->text , colText);
      } else {
         *pCol->text = '\0';
      }

      // If all uppercase ( not given name by .. AS "newName") the lowercase
      if (format & (NOX_SYSTEM_NAMES)) {
         if (format & (NOX_SYSTEM_CASE)) {
            strcpy  (pCol->colname , pCol->sysname);
         }  else {
            a_camel_case(pCol->colname, pCol->sysname);
         }
      } else {
         if (format & (NOX_SYSTEM_CASE)) {
            // strcpy  (pCol->colname , pCol->colname);
         }  else {
            a_camel_case(pCol->colname, pCol->colname);
         }
      }
      // } else if (format & (NOX_CAMEL_CASE)) {
      //    a_camel_case(pCol->colname, pCol->colname);
      // } else if (format & (NOX_UPPERCASE)) {
      // It is upper NOW
      // nox_sqlUpperCaseNames(pSQL);

      ///} else if (OFF == nox_IsTrue (pCon->pOptions ,"uppercasecolname")) {
      ///   UCHAR temp [256];
      ///   a_str2upper  (temp , pCol->colname);
      ///   if (strcmp (temp , pCol->colname) == 0) {
      ///      a_str_to_lower  (pCol->colname , pCol->colname);
      ///   }
      ///}

      // is it an ID column ? get the label, if no label then use the column name
      isTrue = SQL_FALSE;
      rc = SQLColAttribute (pSQL->pstmt->hstmt,i+1,SQL_DESC_AUTO_INCREMENT, NULL, 0, NULL ,&isTrue);
      pCol->isId = isTrue == SQL_TRUE;

      // get the label, if no label then use the column name
      // NOTE in ver 5.4 this only return the 10 first chars ...
      labelRc = SQLColAttribute (pSQL->pstmt->hstmt,i+1,SQL_DESC_LABEL, pCol->header, 127,&len,&dummyInt);
      if (labelRc != SQL_SUCCESS ) {
         pCol->header[len] =  '\0';
         righttrim(pCol->header);
      } else {
         // No headers, if none provided
         pCol->header[len] =  '\0';
      }

      // get display length for column
      SQLColAttribute (pSQL->pstmt->hstmt, i+1, SQL_DESC_PRECISION, NULL, 0,NULL, &pCol->displaysize);

      // Pollyfill for pre 7.5
      tprc = SQLColAttribute (pSQL->pstmt->hstmt,i+1,SQL_DESC_TYPE_NAME, typeName , sizeof(typeName),&len,&dummyInt);
      if (tprc == SQL_SUCCESS) {
         typeName [len] =  '\0';
         if (strstr(typeName ,"BOOL") != NULL) {
            pCol->coltype = SQL_BOOLEAN;
         }
      }

      // set column length to max of display length, and column name
      //   length.  Plus one byte for null terminator
      // collen[i] = max(displaysize, collen[i]);
      // collen[i] = max(collen[i], strlen((char *) colname) ) + 1;

      // printf ("%-*.*s", collen[i], collen[i], colname);

      // allocate memory to bind column

      // bind columns to program vars, converting all types to CHAR
      //*SQLBindCol (hstmt, i+1, SQL_C_CHAR, data[i], collen[i], &outlen[i]);

      // NOTE: Timestamp returns 6!! first time for displaysize  -
      if ( pCol->displaysize <  pCol->collen) {
         pCol->displaysize = pCol->collen;
      }

      switch( pCol->coltype) {
         case SQL_BOOLEAN:
            pCol->collen = pCol->collen = 6; // size of "false" + null
            break;

         case SQL_BLOB:
         case SQL_CLOB:
   //           pCol->collen = pCol->displaysize * 2;
   //           pCol->data = (SQLCHAR *) malloc (pCol->collen);
            pCol->collen = 1048576L;  // 1MEGABYTES
   //            pCol->data = (SQLCHAR *) malloc (pCol->collen);  // 1MEGABYTES
   //            rc = SQLBindCol (pSQL->pstmt->hstmt, i+1, SQL_C_BINARY , pCol->data, pCol->collen, &pCol->outlen);
            break;

         case SQL_WCHAR:
         case SQL_WVARCHAR:
         case SQL_GRAPHIC:
         case SQL_VARGRAPHIC:
            pCol->collen = pCol->displaysize * 2;
   //          pCol->data = (SQLCHAR *) malloc (pCol->collen);
   //          rc = SQLBindCol (pSQL->pstmt->hstmt, i+1, pCol->coltype, pCol->data, pCol->collen, &pCol->outlen);
            break;

         // TODO !! FIX - SQLCLI resturn 6 first time for timestamp...
         /*
         case SQL_TIMESTAMP:
         pCol->collen = 27; // and zero termination
         pCol->data = (SQLCHAR *) malloc (pCol->collen);
         rc = SQLBindCol (pSQL->pstmt->hstmt, i+1, SQL_C_CHAR, pCol->data, pCol->collen, &pCol->outlen);
         break;
         */

         default:
            pCol->collen = pCol->displaysize + 3; // + . and , and zero term
   //          pCol->data = (SQLCHAR *) malloc (pCol->collen);
   //          rc = SQLBindCol (pSQL->pstmt->hstmt, i+1, SQL_C_CHAR, pCol->data, pCol->collen, &pCol->outlen);
         break;
      }
      if (pSQL->maxColSize < pCol->collen) {
          pSQL->maxColSize = pCol->collen;
      }

      switch (pCol->coltype ) {
         case SQL_NUMERIC    :
         case SQL_DECIMAL    :
         case SQL_INTEGER    :
         case SQL_SMALLINT   :
         case SQL_FLOAT      :
         case SQL_REAL       :
         case SQL_DOUBLE     :
         case SQL_BIGINT     :
         case SQL_BOOLEAN    :
            pCol->nodeType = NOX_LITERAL;
            break;
         default:
            pCol->nodeType = NOX_VALUE;
      }
   }

   return pSQL;

}

/* ------------------------------------------------------------- */
PNOX_SQL nox_sqlOpenVC(PNOX_SQLCONNECT pCon, PLVARCHAR sqlstmt , PNOXNODE pSqlParmsP, LONG formatP , LONG startP , LONG limitP)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PNOXNODE pSqlParms  =  (pParms->OpDescList->NbrOfParms >= 3 ) ? pSqlParmsP : NULL;
   LONG format =  (pParms->OpDescList->NbrOfParms >= 4 ) ? formatP : 0;
   LONG start  =  (pParms->OpDescList->NbrOfParms >= 5 ) ? startP : 1;
   LONG limit  =  (pParms->OpDescList->NbrOfParms >= 5 ) ? limitP : -1;

   return nox_sqlOpen (pCon, plvc2str(sqlstmt) , pSqlParms, format , start , limit);

}
/* ------------------------------------------------------------- */
PNOXNODE nox_sqlFormatRow  (PNOX_SQL pSQL)
{
   int i;
   PNOXNODE pRow;
   SQLINTEGER buflen, datatype;
   PUCHAR buf = memAlloc (pSQL->maxColSize);


   if ( pSQL->rc == SQL_SUCCESS
   ||   pSQL->rc == SQL_SUCCESS_WITH_INFO ) {
      jxError = false;

      pRow = nox_NewObject();

      for (i = 0; i < pSQL->nresultcols; i++) {

         PNOXCOL pCol = &pSQL->cols[i];
         buflen =0;

         // TODO - Work arround !!! first get the length - if null, the dont try the get data
         // If it has a pointer value, the API will fail..
         // For now BLOB and CLOB does not support "not null with default"
         // SQLGetCol (pSQL->pstmt->hstmt, i+1, SQL_BLOB, NULL , 0, &buflen);
         switch (pCol->coltype) {
         case SQL_BLOB:
         case SQL_CLOB:
         case SQL_WCHAR:
         case SQL_WVARCHAR:
         case SQL_GRAPHIC:
         case SQL_VARGRAPHIC:
            // fix !! UNICODE tends to leave uninitialized data behind
            if ( 0 == (pCol->collen & 0xF0000000 )) {
                  memset( buf, '\0' , pCol->collen);
            }
            // Note: SQLCLI only supports LONG_MAX size of data to be transfered
            // SQLGetCol (pSQL->pstmt->hstmt, i+1, pCol->coltype, buf , memSize(buf), &buflen);
            SQLGetCol (pSQL->pstmt->hstmt, i+1, pCol->coltype, buf , LONG_MAX, &buflen);

            // Note: collen will contain xFFFFFFFF for  type 14 = CLOB
            memset ( buf + buflen, 0 , 2); // Zero term - also UNICODE
            break;
         default:
            // Note: SQLCLI only supports LONG_MAX size of data to be transfered
            SQLGetCol (pSQL->pstmt->hstmt, i+1, SQL_CHAR, buf , memSize(buf), &buflen);
            //SQLGetCol (pSQL->pstmt->hstmt, i+1, SQL_CHAR, buf , LONG_MAX, &buflen);
         }


         // Null data is the same for all types
         if (buflen  ==  SQL_NULL_DATA) {
            nox_NodeInsertNew (pRow , NOX_RL_LAST_CHILD, pCol->colname , NULL,  NOX_LITERAL );
         } else {

            memset ( buf + buflen, 0 , 2); // Zero term - also UNICODE

            switch( pCol->coltype) {
               case SQL_BOOLEAN    :
                  nox_NodeInsertNew (
                     pRow ,
                     NOX_RL_LAST_CHILD,
                     pCol->colname ,
                     (*buf == '1' || *buf == 't') ? "true":"false",
                     pCol->nodeType
                  );
                  break;

               case SQL_WCHAR:
               case SQL_WVARCHAR:
               case SQL_GRAPHIC:
               case SQL_VARGRAPHIC: {
                  PUCHAR temp;
                  PUCHAR pInBuf = buf;
                  LONG   OutLen;      // XlateBuffer gives -1 on an error
                  size_t inbytesleft;

                  if (pCol->coltype ==  SQL_WVARCHAR) {
                  inbytesleft = (* (PSHORT) pInBuf) * 2; // Peak the length, and unicode uses two bytes
                  pInBuf += 2; // skip len
                  } else {
                     for  (inbytesleft = pCol->collen; inbytesleft > 0 ; inbytesleft -= 2) {
                        if ( * (PSHORT) (pInBuf + inbytesleft - 2) > 0x0020) break;
                     }
                  }
                  // UTF-8 takes up to 3 bytes for 2 bytes of UTF-16 (a surrogate pair: 4 for 4)
                  temp = memAlloc (inbytesleft / 2 * 3 + 1);
                  OutLen = XlateBuffer  (xlate_1200_to_1208, temp , pInBuf, inbytesleft);
                  temp[OutLen < 0 ? 0 : OutLen] = '\0';

                  nox_NodeInsertNew (pRow , NOX_RL_LAST_CHILD, pCol->colname , temp,  pCol->nodeType );
                  memFree ((PVOID *) &temp);

                  break;
               }

               case SQL_NUMERIC:
               case SQL_DECIMAL:
               case SQL_FLOAT:
               case SQL_REAL:
               case SQL_DOUBLE: {
                  PUCHAR p = buf;
                  int len;
                  // skip leading blanks
                  for (;*p == ' '; p++);

                  len = a_str_trim_len(p);
                  p[len] = '\0';

                  // Have to fix .00 numeric as 0.00
                  // and -.8  as -0.8
                  if (*p == '.') {
                     memmove (p+1 , p, len+1);
                     *p = '0';
                  } else if (0==memcmp(p, "-.",2)){
                     memmove (p+1 , p, len+1);
                     *(p+1) = '0';

                  }

                  nox_NodeInsertNew (pRow , NOX_RL_LAST_CHILD, pCol->colname , p,  pCol->nodeType );
                  break ;
               }

               case SQL_TIMESTAMP: {
                  PUCHAR p = buf;
                  int len = a_str_trim_len(p);
                  p[len] = '\0';
                  if (isoTimestamp == ON) {
                     ts_ibm2iso8601(p);
                  }
                  nox_NodeInsertNew (pRow , NOX_RL_LAST_CHILD, pCol->colname , p,  pCol->nodeType );
                  break;
               }

               default: {
                  PUCHAR p = buf;
                  int len;

                  if (pCol->coltype != SQL_BLOB
                  &&  pCol->coltype != SQL_CLOB) {
                     len = a_str_trim_len(p);
                     p[len] = '\0';
                  }

                  // trigger new parsing of JSON-objects in columns:
                  // Predicts json data i columns
                  if (pSQL->pCon->options.autoParseContent == ON) {
                     if (*p == BRABEG || *p == CURBEG) {
                     PNOXNODE pNode = nox_ParseString(p);
                     if (pNode) {
                        nox_NodeRename(pNode, pCol->colname);
                        nox_NodeInsertChildTail (pRow, pNode);
                        break;
                     }
                     }
                  }

                  nox_NodeInsertNew (pRow , NOX_RL_LAST_CHILD, pCol->colname , p,  pCol->nodeType );
                  break;
               }
            }
         }
      }
      memFree(&buf);

      return pRow; // Found

   } else {
      if (pSQL->rc != SQL_NO_DATA_FOUND ) {
         // sqlError, not getSqlCode first: SQLError would use up the diagnostic record.
         // Not check_error: that would free pSQL, which the caller still uses and closes
         sqlError (pSQL->pCon, pSQL);
      } else {
         pSQL->pCon->sqlCode = getSqlCode(pSQL->pstmt->hstmt);
      }
   }
   memFree(&buf);
   return NULL; // not found
}
/* ------------------------------------------------------------- */
PNOXNODE nox_sqlFetchRelative (PNOX_SQL pSQL, LONG fromRow)
{
   int rc;
   if (pSQL == NULL) return (NULL);

   pSQL->rc = SQLFetchScroll (pSQL->pstmt->hstmt, SQL_FETCH_RELATIVE , (fromRow < 1) ? 1: fromRow);
   return nox_sqlFormatRow(pSQL);
}
/* ------------------------------------------------------------- */
PNOXNODE nox_sqlFetchNext (PNOX_SQL pSQL)
{
   int rc;
   if (pSQL == NULL) return (NULL);

   // No result set (an INSERT / UPDATE / DELETE ... sent as a query): no rows - not an error
   if (pSQL->nresultcols <= 0) {
      pSQL->rc = SQL_NO_DATA_FOUND;
      pSQL->pCon->sqlCode = 0;
      return (NULL);
   }

   // List next row from the result set
   pSQL->rc = SQLFetch (pSQL->pstmt->hstmt);
   return nox_sqlFormatRow(pSQL);
}
/* ------------------------------------------------------------- */
/****** not used

PNOXNODE nox_sqlFetchFirst (PNOX_SQL pSQL, LONG fromRow)
{
   int rc;
   if (pSQL == NULL) return (NULL);

   if (fromRow > 1) {
      pSQL->rc = SQLFetchScroll (pSQL->pstmt->hstmt, SQL_FETCH_RELATIVE , fromRow);
   } else {
      pSQL->rc = SQLFetch (pSQL->pstmt->hstmt);
   }
   return nox_sqlFormatRow(pSQL);
}
*/
/* ------------------------------------------------------------- */
void nox_sqlClose (PNOX_SQL * ppSQL)
{
   int i;
   int rc;
   PNOX_SQL pSQL = * ppSQL;


   // Do we have an active statement ...
   if (pSQL) {

      if (pSQL->pCon->options.hexSort == ON ) {
         LONG attrParm = SQL_TRUE ;
         rc = SQLSetEnvAttr (pSQL->pCon->henv, SQL_ATTR_JOB_SORT_SEQUENCE , &attrParm  , 0);
         pSQL->pCon->options.hexSort = OFF;
      }

      memFree(&pSQL->cols);
      pSQL->nresultcols = 0; // !! Done

      if (pSQL->pstmt) {
         if (! pSQL->pstmt->exec) {
            // Clean up for read cursor statements:
            rc = SQLCloseCursor(pSQL->pstmt->hstmt);
         }
         rc = SQLFreeHandle (SQL_HANDLE_STMT, pSQL->pstmt->hstmt);
         memFree (&pSQL->pstmt);
      }

      if (pSQL->sqlstmt) {
         free  (pSQL->sqlstmt);
         pSQL->sqlstmt = null;
      }
      memFree(ppSQL);  // Note!! memFree takes the address of the pointer, and nulls it afterwards
      * ppSQL  = NULL;
   }

}
/* ------------------------------------------------------------- */

/* ------------------------------------------------------------- */
void nox_sqlDisconnect (PNOX_SQLCONNECT * ppCon)
{

   PNOX_SQLCONNECT pCon;
   int rc;

   if (ppCon == NULL) {
      pCon = pLastConnnection;
   } else {
      pCon = *ppCon;
   }

   if (pCon == NULL) return;

   iconv_close (pCon->iconv);

   if (pCon->sqlTrace.handle != -1) {
      rc = SQLFreeHandle (SQL_HANDLE_STMT, pCon->sqlTrace.handle);
      pCon->sqlTrace.handle = -1;
   }

   // disconnect from database
   if (pCon->hdbc != -1) {
      SQLDisconnect  (pCon->hdbc);
      SQLFreeConnect (pCon->hdbc);
      pCon->hdbc = -1;
   }

   // free environment handle
   if (pCon->henv != -1) {
      SQLFreeEnv (pCon->henv);
      pCon->henv = -1;
   }

   nox_NodeDelete(pCon->pOptions);
   nox_NodeDelete(pCon->pDiag);
   if (pCon->errStmt) free (pCon->errStmt);

   // The activation group end (initialize.cpp) disconnects pLastConnnection: it must not
   // point to a connection that is gone - that was a second free of the same storage
   if (pCon == pLastConnnection) {
      pLastConnnection = NULL;
   }
   memFree ((PVOID *) &pCon);
   if (ppCon) {
      *ppCon = NULL;
   }

}
/* ------------------------------------------------------------- */
PNOXNODE nox_buildMetaFields ( PNOX_SQL pSQL )
{
   int rc;
   LONG    attrParm;
   PNOXNODE pFields;
   int i;

   if (pSQL == NULL) return(NULL);

   pFields  = nox_NewArray();

   /*****  need to be done before the cursor is closed !!

   attrParm = SQL_TRUE;
   rc = SQLSetStmtAttr  (pSQL->pstmt->hstmt, SQL_ATTR_EXTENDED_COL_INFO , &attrParm  , 0);
   if (rc != SQL_SUCCESS ) {
      check_error (pSQL);
      return NULL; // we have an error
   }
   ******/

   for (i = 1; i <= pSQL->nresultcols; i++) {
      PNOXNODE pField  = nox_NewObject ();
      PNOXCOL  pCol     = &pSQL->cols[i-1];
      PUCHAR  type = "string";
      UCHAR   temp [256];
      SQLINTEGER templen;
      SQLINTEGER descNo;

      // Add name
      nox_NodeInsertNew (pField  , NOX_RL_LAST_CHILD, "name" , pCol->colname,  NOX_VALUE );
      nox_NodeInsertNew (pField  , NOX_RL_LAST_CHILD, "colname"  , pCol->realname, NOX_VALUE );

      if (*pCol->sysname  > ' ') {
         nox_NodeInsertNew (pField, NOX_RL_LAST_CHILD, "sysname", pCol->sysname, NOX_VALUE );
      }

      // Add type
      switch( pCol->coltype) {
         case SQL_BLOB:        type = "blob"           ; break;
         case SQL_CLOB:        type = "clob"           ; break;
         case SQL_CHAR:        type = "char"           ; break;
         case SQL_VARCHAR:     type = "varchar"        ; break;
         case SQL_DATETIME:    type = "datetime"       ; break;
         case SQL_DATE:        type = "date"           ; break;
         case SQL_TIME:        type = "time"           ; break;
         case SQL_TIMESTAMP:   type = "timestamp"      ; break;
         case SQL_WCHAR:       type = "wchar"          ; break;
         case SQL_WVARCHAR:    type = "wvarchar"       ; break;
         case SQL_GRAPHIC:     type = "graphic"        ; break;
         case SQL_VARGRAPHIC:  type = "vargraphic"     ; break;
         case SQL_BOOLEAN    : type = "boolean"        ; break;

         case SQL_BIGINT:
         case SQL_INTEGER:
         case SQL_SMALLINT:
         case SQL_TINYINT:
	 case SQL_NUMERIC:
         case SQL_DECIMAL:
         case SQL_FLOAT:
         case SQL_REAL   :
         case SQL_DOUBLE : {
            if (pCol->scale > 0) {
               type = "dec"     ;
            } else {
               type = "int"     ;
            }
            break;
         }

         default: {
            a_sprintf(temp ,"unknown%d" , pCol->coltype);
            type = temp;
         }
      }
      nox_NodeInsertNew (pField  , NOX_RL_LAST_CHILD, "datatype" , type,  NOX_VALUE );

      a_sprintf(temp , "%d" ,  pCol->coltype);
      nox_NodeInsertNew (pField  , NOX_RL_LAST_CHILD, "sqltype" , temp ,  NOX_LITERAL);

      // Add size
      a_sprintf(temp , "%d" , pCol->displaysize);
      nox_NodeInsertNew (pField  , NOX_RL_LAST_CHILD, "size"     , temp,  NOX_LITERAL  );

      // Add decimal precission
      if  (0==strcmp ( type , "dec" )) {
         a_sprintf(temp , "%d" , pCol->scale);
         nox_NodeInsertNew (pField  , NOX_RL_LAST_CHILD, "prec"     , temp,  NOX_LITERAL  );
      }

      nox_NodeInsertNew (pField  , NOX_RL_LAST_CHILD, "header" , pCol->header, NOX_VALUE  );

      if (*pCol->text > ' ') {
         nox_NodeInsertNew (pField  , NOX_RL_LAST_CHILD, "text"   , pCol->text, NOX_VALUE  );
      }

      // Push to array
      nox_ArrayPush (pFields , pField, FALSE);
   }

   // nox_Debug ("Fields:", pFields);
   return  pFields;

}

/* ------------------------------------------------------------- */
LONG nox_sqlNumberOfRows(PNOX_SQLCONNECT pCon ,PUCHAR sqlstmt)
{

   LONG    rowCount, para = 0;
   PNOXNODE pRow;
   PUCHAR p, w, lastSelect, orderby, from, withur, end;
   PUCHAR str2;

   // replace the coloumn list with a count(*) - TODO !! This will not work on a "with" statment

   // Find the last select ( there can be more when using "with")

   p = sqlstmt;
   w = a_stristr(p, "with ");
   p = a_stristr(p , "select ");

   if (w == NULL || w > p) {
      lastSelect = p;
   } else {
      for(;;) {
         if (w == NULL) break;
         switch (*w) {
            case '(':
               para++;
               break;
            case ')':
               para--;
               if (para == 0) {
                  for (w++; *w == ' '; w++);
                  if ( *w != ',') {
                  lastSelect = a_stristr(w , "select ");
                  goto outer;
                  }
               }
               break;
         }
      w++;
      }
   }
   outer:
   if (lastSelect == NULL) return 0;

   // We need to replace all columns between "select" and  "from"  with the count(*)
   from  = a_stristr(lastSelect , " from ");
   if (from == NULL) return 0;

   // leave out "order by" and "with ur" - if any. The statement itself is not changed:
   // it is often pSQL->sqlstmt
   end = from + strlen(from);
   orderby = a_stristr(from  , " order ");
   if (orderby && orderby < end) end = orderby;
   withur = a_stristr(from  , " with ur");
   if (withur && withur < end) end = withur;

   // rebuild the select statement as a "select count(*) from ..."
   str2 = memAlloc ((lastSelect - sqlstmt) + 32 + (end - from) + 1);
   p = str2;
   memcpy (p , sqlstmt , lastSelect - sqlstmt); // if a "With" exists then grab that
   p += lastSelect - sqlstmt;
   p += cpy (p , "select count(*) as counter" );
   memcpy (p , from , end - from);
   p += end - from;
   *p = '\0';

   // Get that only row
   pRow = nox_sqlResultRow(pCon, str2, NULL,1,0);
   memFree ((PVOID *) &str2);

   rowCount = a2i(nox_GetValuePtr(pRow, "counter", NULL));

   nox_NodeDelete (pRow);

   return rowCount;
}
LONG nox_sqlNumberOfRowsVC(PNOX_SQLCONNECT pCon ,PLVARCHAR sqlstmt)
{
   return nox_sqlNumberOfRows(pCon ,plvc2str(sqlstmt));
}
/* ------------------------------------------------------------- */

/***********
LONG nox_sqlNumberOfRowsDiag(PUCHAR sqlstmt)
{

   LONG    rowCount, para = 0;
   PNOXNODE pRow;
   PUCHAR p, w, lastSelect, orderby, from, withur;
   UCHAR  str2 [32766];

   strcat (str2 , "GET DIAGNOSTICS :v = DB2_NUMBER_ROWS" );

   // Get that only row
   pRow = nox_sqlResultRow(str2, NULL);

   rowCount = atoi(nox_GetValuePtr(pRow, "counter", NULL));

   nox_NodeDelete (pRow);

   return rowCount;
}
*/
/* ------------------------------------------------------------- */
/*
void nox_sqlUpperCaseNames(PNOX_SQL pSQL)
{
   int i;
   for (i = 0; i < pSQL->nresultcols; i++) {
      PNOXCOL pCol = &pSQL->cols[i];
      a_str2upper (pCol->colname , pCol->colname);
   }
}
*/
/* ------------------------------------------------------------- */
LONG nox_sqlColumns (PNOX_SQL pSQL)
{
   if (pSQL == NULL) return -1;
   return (pSQL->nresultcols);
}
/* ------------------------------------------------------------- */
LONG nox_sqlRows (PNOX_SQL pSQL)
{
   if (pSQL == NULL) return -1;
   if (pSQL->rowcount == -1) {
      pSQL->rowcount = nox_sqlNumberOfRows(pSQL->pCon , pSQL->sqlstmt);
   }

   return (pSQL->rowcount);
}
/* ------------------------------------------------------------- */
PNOXNODE nox_sqlResultSet( PNOX_SQLCONNECT pCon ,PUCHAR sqlstmt, PNOXNODE pSqlParms, LONG format, LONG start, LONG limit)
{

   PNOXNODE pRow;
   PNOXNODE pRows;
   PNOXNODE pResult;
   PNOX_SQL  pSQL;
   LONG     i, rc;
   LONG     rowCount=0;
   SHORT    strLen=0;

   start = start < 1 ? 1 : start;

   pSQL = nox_sqlOpen(pCon, sqlstmt , pSqlParms, format, start , limit);
   if ( pSQL == NULL) {
      if (format & NOX_GRACEFUL_ERROR) {
         return sqlErrorObject(pCon, sqlstmt);
      } else {
        return NULL;
      }
   }

   pRows  = nox_NewArray();
   pRow  = nox_sqlFetchNext (pSQL);
   for (rowCount = 1; pRow && (rowCount <=limit || limit == -1); rowCount ++) {
      nox_ArrayPush (pRows , pRow, FALSE);
      pRow  = nox_sqlFetchNext (pSQL);
   }

   // pRow is still set when the limit stopped the loop - that is no error
   if ( pRow == NULL && pSQL->rc != SQL_NO_DATA_FOUND && (format & NOX_GRACEFUL_ERROR) ) {
      nox_NodeDelete (pRows);
      nox_sqlClose (&pSQL);
      return sqlErrorObject(pCon, sqlstmt);
   }


   // need a object as return value
   if (format & (NOX_META | NOX_FIELDS | NOX_TOTALROWS | NOX_APROXIMATE_TOTALROWS)) {
      PNOXNODE pMeta;
      pResult  = nox_NewObject();
      pMeta    = nox_NewObject();
      nox_SetValueByName(pResult  , "success" , "true" , NOX_LITERAL);
      nox_SetValueByName(pResult , "root"    , "rows" , NOX_VALUE);
      if (format & NOX_FIELDS ) {
         PNOXNODE pFields = nox_buildMetaFields (pSQL);
         nox_NodeMoveInto(pMeta , "fields" , pFields);
      }
      if (format & (NOX_TOTALROWS | NOX_APROXIMATE_TOTALROWS)) {
         nox_SetValueByName(pMeta , "totalProperty"   , "totalRows" , NOX_VALUE);

         if (format & NOX_APROXIMATE_TOTALROWS ) {
            if (pRow) { // Yet more rows to come
               pSQL->rowcount = start + limit;
            } else {
               pSQL->rowcount = start + rowCount - 2; // "start" and "rowCount" count has both 1 as option base)
            }
         } else {
            pSQL->rowcount = nox_sqlNumberOfRows(pCon,sqlstmt);
         }
         nox_SetIntByName(pResult , "totalRows" , pSQL->rowcount );

         //SQLGetDiagField(SQL_HANDLE_STMT,
         //    pSQL->pstmt->hstmt,0,DB2_NUMBER_ROWS,&rowCount,SQL_INTEGER,&strLen);


         // SQL_INTEGER
         //rc=SQLGetDiagField(SQL_HANDLE_STMT,pSQL->pstmt->hstmt, 0 ,SQL_DIAG_ROW_COUNT,&rowCount,SQL_INTEGER,&strLen);
         // pSQL->rowcount = rowCount;
      }

      nox_NodeMoveInto (pResult , "metaData" , pMeta);
      nox_NodeMoveInto (pResult , "rows"     , pRows);

   } else {

      // simply return the array of rows
      pResult = pRows;
   }

   nox_NodeDelete (pRow); // the row after the limit, if any
   nox_sqlClose (&pSQL);
   return pResult;

}
// RPG wrapper:
PNOXNODE nox_sqlResultSetVC( PNOX_SQLCONNECT pCon, PLVARCHAR sqlstmt, PNOXNODE pSqlParmsP, LONG formatP, LONG startP, LONG limitP )
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PNOXNODE pSqlParms= (pParms->OpDescList->NbrOfParms >= 3) ? pSqlParmsP : NULL;
   LONG    format    = (pParms->OpDescList->NbrOfParms >= 4) ? formatP    : 0;  // Arrray only
   LONG    start     = (pParms->OpDescList->NbrOfParms >= 5) ? startP     : NOXDB_FIRST_ROW;  // From first row
   LONG    limit     = (pParms->OpDescList->NbrOfParms >= 6) ? limitP     : NOXDB_ALL_ROWS; // All row
   return nox_sqlResultSet( pCon, plvc2str(sqlstmt) , pSqlParms, format , start, limit);
}
/* ------------------------------------------------------------- */
// One row; *pFailed tells an error from "no row". On an error the result is
// the error object with NOX_GRACEFUL_ERROR, else NULL
static PNOXNODE resultRow ( PNOX_SQLCONNECT pCon, PUCHAR sqlstmt, PNOXNODE pSqlParms , LONG format , LONG start, BOOL * pFailed )
{
   PNOXNODE pRow;
   PNOX_SQL  pSQL;

   *pFailed = false;
   pSQL = nox_sqlOpen(pCon , sqlstmt , pSqlParms, format , start , 1 );
   if ( pSQL == NULL) {
      *pFailed = true;
      return (format & NOX_GRACEFUL_ERROR) ? sqlErrorObject(pCon, sqlstmt) : NULL;
   }

   pRow  = nox_sqlFetchNext (pSQL);
   if (pRow == NULL && pSQL->rc != SQL_NO_DATA_FOUND) {
      *pFailed = true;
      nox_sqlClose (&pSQL);
      return (format & NOX_GRACEFUL_ERROR) ? sqlErrorObject(pCon, sqlstmt) : NULL;
   }
   nox_sqlClose (&pSQL);
   return pRow;
}
PNOXNODE nox_sqlResultRow ( PNOX_SQLCONNECT pCon, PUCHAR sqlstmt, PNOXNODE pSqlParms , LONG format , LONG start )
{
   BOOL failed;
   return resultRow (pCon, sqlstmt, pSqlParms, format, start, &failed);
}
// RPG wrapper
// RPG order (headers/noxDbUtf8.rpgle): connection, statement, template, format, start
PNOXNODE nox_sqlResultRowVC ( PNOX_SQLCONNECT pCon, PLVARCHAR sqlstmt, PNOXNODE pSqlParmsP, LONG formatP ,  LONG startP )
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PNOXNODE pSqlParms = (pParms->OpDescList->NbrOfParms >= 3) ? pSqlParmsP : NULL;
   LONG     format    = (pParms->OpDescList->NbrOfParms >= 4) ? formatP    : 0;  // Object only
   LONG     start     = (pParms->OpDescList->NbrOfParms >= 5) ? startP     : 1;  // From first row
   return nox_sqlResultRow ( pCon, plvc2str(sqlstmt), pSqlParms, format, start);
}
/* ------------------------------------------------------------- */
PNOXNODE nox_sqlValuesVC ( PNOX_SQLCONNECT pCon, PLVARCHAR sqlstmt, PNOXNODE pSqlParmsP , LONG formatP)
{

   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PNOXNODE pSqlParms = (pParms->OpDescList->NbrOfParms >= 3) ? pSqlParmsP : NULL;
   LONG    format     = (pParms->OpDescList->NbrOfParms >= 4) ? formatP    : 0;
   PNOXNODE pResult;
   PNOXNODE pChild ;
   BOOL     failed;
   PUCHAR  stmt = plvc2str(sqlstmt);
   PUCHAR  stmtBuf = memAlloc (strlen(stmt) + 16);

   strjoin (stmtBuf , "values (" , stmt , ")");

   pResult = resultRow ( pCon , stmtBuf, pSqlParms , format, 1, &failed);
   memFree ((PVOID *) &stmtBuf);

   // an error: the error object as it is (NOX_GRACEFUL_ERROR) or NULL
   if (failed || pResult == NULL) return pResult;

   pChild  = nox_GetNodeChild (pResult);
   // more that one return values? then array
   // Note: Since we "move" the value into an object it will be poped from the
   // top - so we get the next from the top by the  nox_GetNodeChild (pResult)
   if (nox_GetNodeNext(pChild)) {
      PNOXNODE pNode;
      PNOXNODE pArray = nox_NewArray();
      for (pNode = pChild; pNode; pNode = nox_GetNodeChild (pResult)) {
         nox_ArrayPush (pArray, pNode, false);
      }
      nox_NodeDelete (pResult);
      return pArray;
   } else {
      nox_NodeUnlink (pChild);
      nox_NodeDelete (pResult);
      return pChild; // Only one value
   }

}
/* ------------------------------------------------------------- */
PNOXNODE nox_sqlGetMeta (PNOX_SQLCONNECT pCon, PUCHAR sqlstmt)
{
   int i;
   PNOX_SQL  pSQL  = nox_sqlOpen(pCon, sqlstmt , NULL, 0 , 1 , 0);
   PNOXNODE pMeta = nox_buildMetaFields ( pSQL );
   nox_sqlClose (&pSQL);
   return pMeta;
}
PNOXNODE nox_sqlGetMetaVC (PNOX_SQLCONNECT pCon, PLVARCHAR sqlstmt)
{
   return nox_sqlGetMeta (pCon, plvc2str(sqlstmt));
}
/* ------------------------------------------------------------- */
LGL nox_sqlExec(PNOX_SQLCONNECT pCon,PUCHAR sqlstmt , PNOXNODE pSqlParms)
{

   LONG   attrParm;
   LONG   i;
   int rc;
   //   PNOX_SQL pSQL = nox_sqlNewStatement (pParms->OpDescList->NbrOfParms >= 2 ? pSqlParms  :NULL);
   PNOX_SQL pSQL = nox_sqlNewStatement (pCon, NULL, true, false);

   // run  the  statement in "sqlstr"
   if (pSqlParms) {
      PUCHAR sqlTempStmt = strFormatAlloc (sqlstmt , pSqlParms , 0);
      rc = nox_sqlExecDirectTrace(pCon, pSQL , pSQL->pstmt->hstmt, sqlTempStmt);
      memFree ((PVOID *) &sqlTempStmt);
   } else {
      rc = nox_sqlExecDirectTrace(pCon, pSQL , pSQL->pstmt->hstmt, sqlstmt);
   }
   nox_sqlClose (&pSQL);
   return rc == SQL_SUCCESS ? OFF: ON;
}
// RPG wrapper
LGL nox_sqlExecVC(PNOX_SQLCONNECT pCon,PLVARCHAR sqlstmt , PNOXNODE pSqlParmsP)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PNOXNODE pSqlParms = (pParms->OpDescList->NbrOfParms >= 3) ? pSqlParmsP : NULL;
   return nox_sqlExec(pCon, plvc2str(sqlstmt) , pSqlParms);
}
/* ------------------------------------------------------------- */
/* nox_sqlCall - call a stored procedure (ported from the classic */
/* noxDB jx_sqlCall)                                              */
/* ------------------------------------------------------------- */
// Parameter metadata of a qualified procedure (schema.procedure), one row
// per parameter, names in system case (PARAMETER_NAME ...)
static PNOXNODE procedureMeta (PNOX_SQLCONNECT pCon, PUCHAR procedureName)
{
   UCHAR  sqlStmt [2048];
   UCHAR  schema [129];
   UCHAR  procedure [257];
   PUCHAR split = strchr(procedureName , '.');

   if (split == NULL
   ||  split - procedureName >= sizeof(schema)
   ||  strlen(split + 1)     >= sizeof(procedure)) return NULL;

   substr (schema    , procedureName , split - procedureName);
   strcpy (procedure , split + 1);

   // Note: no CTE / subquery on the catalog views - on 7.3 that takes minutes;
   // the implementations are counted by the caller from SPECIFIC_NAME
   strjoin (sqlStmt,
      "select "
         "a.specific_name specific_name,"
         "parameter_mode,"
         "parameter_name,"
         "data_type,"
         "numeric_scale,"
         "numeric_precision,"
         "character_maximum_length,"
         "data_type_name,"
         "max(ifnull(numeric_precision , 0) + 2, ifnull(character_maximum_length,0)) buffer_length "
      "from qsys2.sysprocs a "          // qualified: any job, any library list
      "left join qsys2.sysparms b "
      "on a.specific_schema = b.specific_schema and a.specific_name = b.specific_name "
      "where a.routine_schema = upper('", schema, "') "
      "and   a.routine_name   = upper('", procedure, "') "
      "order by a.specific_name, b.ordinal_position"
   );
   return nox_sqlResultSet(pCon, sqlStmt, NULL, NOX_SYSTEM_CASE, 1, NOXDB_MAX_PARMS);
}
// ------------------------------------------------------------- */
static SQLSMALLINT text2parmtype (PUCHAR mode)  {
   if  (0 == strcmp (mode , "IN"))  return SQL_PARAM_INPUT;
   if  (0 == strcmp (mode , "OUT")) return SQL_PARAM_OUTPUT;
   return SQL_PARAM_INPUT_OUTPUT;
}
// ------------------------------------------------------------- */
static SQLSMALLINT textType2SQLtype (PUCHAR parmType)  {
   if  (0 == strcmp (parmType , "CHARACTER"))             return(SQL_CHAR);
   if  (0 == strcmp (parmType , "CHARACTER VARYING"))     return(SQL_VARCHAR);
   if  (0 == strcmp (parmType , "INTEGER"))               return(SQL_INTEGER);
   if  (0 == strcmp (parmType , "TIMESTAMP"))             return(SQL_TIMESTAMP);
   if  (0 == strcmp (parmType , "BIGINT"))                return(SQL_BIGINT);
   if  (0 == strcmp (parmType , "DECIMAL"))               return(SQL_DECIMAL);
   if  (0 == strcmp (parmType , "SMALLINT"))              return(SQL_SMALLINT);
   if  (0 == strcmp (parmType , "DATE"))                  return(SQL_DATE);
   if  (0 == strcmp (parmType , "TIME"))                  return(SQL_TIME);
   if  (0 == strcmp (parmType , "REAL"))                  return(SQL_REAL);
   if  (0 == strcmp (parmType , "NUMERIC"))               return(SQL_NUMERIC);
   if  (0 == strcmp (parmType , "DOUBLE PRECISION"))      return(SQL_DOUBLE);
   if  (0 == strcmp (parmType , "BOOLEAN"))               return(SQL_BOOLEAN);
   return(SQL_VARCHAR); // Unsupported type: let the database convert from text
}
// ------------------------------------------------------------- */
static LONG currentLength (PNOX_PROCPARM p, LONG length)
{
   if (p->mode == SQL_PARAM_INPUT
   ||  p->mode == SQL_PARAM_INPUT_OUTPUT) {
      return (p->pData == NULL) ? SQL_NULL_DATA : length;
   }
   return length;
}
// ------------------------------------------------------------- */
// The input parameter by name - not case sensitive (node_Id = NODE_ID)
static PNOXNODE findParm (PNOXNODE pInParms, PUCHAR name)
{
   PNOXNODE pNode;
   if (pInParms == NULL) return NULL;
   for (pNode = pInParms->pNodeChildHead; pNode; pNode = pNode->pNodeSiblingNext) {
      PUCHAR a = pNode->Name, b = name;
      if (a == NULL) continue;
      for (; *a && *b && a_to_lower(*a) == a_to_lower(*b); a++, b++);
      if (*a == '\0' && *b == '\0') return pNode;
   }
   return NULL;
}
// ------------------------------------------------------------- */
static INT64 a2ll (PUCHAR s)
{
   INT64 res = 0;
   BOOL  sign = TRUE;
   for (;*s;s++) {
      if (*s == '-') sign = FALSE;
      if (*s >= '0' && *s <= '9') res = 10 * res + (*s - '0');
   }
   return (sign? res : -res);
}
// ------------------------------------------------------------- */
static double a2f (PUCHAR s)
{
   UCHAR temp [64];
   substr (temp , s , min(strlen(s), sizeof(temp) - 1));
   stra2e (temp , temp);
   return atof (temp);
}
// ------------------------------------------------------------- */
// Call a qualified stored procedure (schema.procedure). Input parameters are
// taken by name from the object pInParms (not case sensitive); input parameters
// not given are left out of the call, so their defaults apply. Returns an object
// with the OUT and INOUT parameters (names in lower case), or NULL on error
// (the message is in nox_Message / nox_GetMessageObject).
// ------------------------------------------------------------- */
PNOXNODE nox_sqlCallStr (PNOX_SQLCONNECT pCon, PUCHAR procedureName , PNOXNODE pInParms)
{
   PNOXNODE      pResult = NULL;
   PUCHAR        stmtBuf;
   PUCHAR        stmt;
   PNOXNODE      pNode;
   UCHAR         temp [256];
   PUCHAR        comma = "";
   PNOX_SQL      pSQL;
   int           rc;
   SQLSMALLINT   i;
   int           impl;
   SQLSMALLINT   fCtype;
   int           numberOfParms = 0;
   PNOXNODE      pProcMeta = procedureMeta (pCon, procedureName);
   PNOX_PROCPARM procParms;
   PNOX_PROCPARM p;

   jxError = false;

   if (pProcMeta == NULL || pProcMeta->pNodeChildHead == NULL) {
      // jxMessage is in the job CCSID (nox_Message)
      PUCHAR msg = memAlloc (strlen(procedureName) + 100);
      strjoin (msg , "Procedure " , procedureName , " is not found or not called qualified (schema.procedure)");
      utf8ToJob (jxMessage , sizeof(jxMessage) , msg);
      memFree ((PVOID *) &msg);
      jxError = true;
      nox_NodeDelete (pProcMeta);
      return NULL;
   }

   // More than one implementation (overloaded): can not decide which to use
   pNode = pProcMeta->pNodeChildHead;
   impl  = 1;
   {
      PNOXNODE pRow;
      PUCHAR   first = nox_GetValuePtr (pNode , "SPECIFIC_NAME" , "");
      for (pRow = pNode->pNodeSiblingNext; pRow; pRow = pRow->pNodeSiblingNext) {
         if (0 != strcmp (first , nox_GetValuePtr (pRow , "SPECIFIC_NAME" , ""))) impl++;
      }
   }
   if (impl > 1) {
      PUCHAR msg = memAlloc (strlen(procedureName) + 100);
      strjoin (msg , "Procedure " , procedureName , " has more than one implementation. Can not decide which to use");
      utf8ToJob (jxMessage , sizeof(jxMessage) , msg);
      memFree ((PVOID *) &msg);
      jxError = true;
      nox_NodeDelete (pProcMeta);
      return NULL;
   }

   procParms = memAllocClear (NOXDB_MAX_PARMS * sizeof(NOX_PROCPARM));
   stmtBuf   = memAlloc (strlen(procedureName) + 64 + nox_getLength(pProcMeta) * 132);
   stmt      = stmtBuf;
   stmt += strjoin (stmt , "call " , procedureName , " (");

   for (i=0; pNode && i < NOXDB_MAX_PARMS; pNode = pNode->pNodeSiblingNext) {
      PNOXNODE pIn;
      p = &procParms[i];
      p->name = nox_GetValuePtr (pNode , "PARAMETER_NAME" , "");
      if (*p->name == '\0') continue;  // no parameters at all
      p->mode    = text2parmtype    (nox_GetValuePtr (pNode , "PARAMETER_MODE" , ""));
      p->sqlType = textType2SQLtype (nox_GetValuePtr (pNode , "DATA_TYPE" , ""));
      pIn = findParm (pInParms , p->name);

      // Input parameters not given are left out - their default applies
      if (p->mode == SQL_PARAM_INPUT && pIn == NULL) continue;

      stmt += strjoin (stmt , comma , p->name , "=>?");
      comma = ",";
      p->pNode = pNode;
      p->pData = (pIn && pIn->Value) ? pIn->Value : NULL;
      i++;
   }
   numberOfParms = i;
   stmt += strjoin (stmt , ")");

   pSQL = nox_sqlNewStatement (pCon, NULL, true, false);
   rc   = SQLPrepare( pSQL->pstmt->hstmt, stmtBuf, SQL_NTS );
   if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
      check_error (pCon, pSQL); // closes pSQL
      jxError = true;
      goto cleanup;
   }

   for (i=0; i < numberOfParms ; i++) {
      int    nullterm = 0;
      LONG   inLen;
      PUCHAR userType;
      p = &procParms[i];
      userType = nox_GetValuePtr (p->pNode , "DATA_TYPE_NAME" , "");
      p->type   = 0 == a2i (nox_GetValuePtr (p->pNode , "NUMERIC_PRECISION" , "0")) ? NOX_VALUE : NOX_LITERAL;
      // Pollyfill for BOOLEAN pre 7.5
      p->isBool = memBeginsWith (userType , "BOOL");

      switch (p->sqlType ) {
         case SQL_CHAR:
         case SQL_VARCHAR:
         case SQL_TIMESTAMP:
         case SQL_DATE:
         case SQL_TIME:
         case SQL_DECIMAL:
         case SQL_NUMERIC:
         case SQL_BOOLEAN:
            fCtype   = SQL_C_CHAR;
            inLen    = p->pData ? strlen(p->pData) : 0;
            p->bufLen = a2i (nox_GetValuePtr (p->pNode , "BUFFER_LENGTH" , "0"));
            // UTF-8: up to 4 bytes per character, and room for what was given
            p->buffer = memAllocClear (max(p->bufLen * 4 , inLen) + 2);
            p->inLen  = currentLength (p, inLen);
            if (p->inLen != SQL_NULL_DATA) {
               // Pollyfill for BOOLEAN pre 7.5
               if (p->isBool) {
                  strcpy (p->buffer , (0 == strcmp (p->pData, "true") ? "1":"0"));
                  p->inLen = 1;
               } else {
                  memcpy (p->buffer , p->pData , inLen);
               }
            }
            p->bufLen = max(p->bufLen * 4 , inLen);
            nullterm = 1;
            break;
         case SQL_SMALLINT:
            fCtype = SQL_C_SHORT;
            p->buffer = memAllocClear (sizeof(SHORT));
            p->inLen  = currentLength (p, p->pData ? sizeof(SHORT):0);
            p->bufLen = sizeof(SHORT);
            if (p->pData) * (SHORT *) p->buffer = a2i(p->pData);
            break;
         case SQL_INTEGER:
            fCtype = SQL_C_LONG;
            p->buffer = memAllocClear (sizeof(LONG));
            p->inLen  = currentLength (p, p->pData ? sizeof(LONG):0);
            p->bufLen = sizeof(LONG);
            if (p->pData) * (LONG *) p->buffer = a2i(p->pData);
            break;
         case SQL_BIGINT:
            fCtype = SQL_C_BIGINT;
            p->buffer = memAllocClear (sizeof(INT64));
            p->inLen  = currentLength (p, p->pData ? sizeof(INT64):0);
            p->bufLen = sizeof(INT64);
            if (p->pData) * (INT64 *) p->buffer = a2ll(p->pData);
            break;
         case SQL_REAL:
            fCtype = SQL_C_FLOAT;
            p->buffer = memAllocClear (sizeof(float));
            p->inLen  = currentLength (p, p->pData ? sizeof(float):0);
            p->bufLen = sizeof(float);
            if (p->pData) * (float *) p->buffer = a2f(p->pData);
            break;
         case SQL_DOUBLE:
         default:
            fCtype = SQL_C_DOUBLE;
            p->buffer = memAllocClear (sizeof(double));
            p->inLen  = currentLength (p, p->pData ? sizeof(double):0);
            p->bufLen = sizeof(double);
            if (p->pData) * (double *) p->buffer = a2f(p->pData);
            break;
      }

      rc = SQLBindParameter (
         pSQL->pstmt->hstmt,  // hstmt
         i + 1,               // Parm number
         p->mode,             // fParamType
         fCtype ,             // data type here in C
         p->sqlType == SQL_BOOLEAN ? SQL_CHAR : p->sqlType, // data type in SQL
         p->bufLen,           // precision / length of the C string
         0,
         p->buffer,           // buffer
         p->bufLen + nullterm,// cbValueMax
         &p->inLen            // length or null indicator
      );
   }

   rc = SQLExecute(pSQL->pstmt->hstmt);
   if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
      check_error (pCon, pSQL); // closes pSQL
      jxError = true;
      goto cleanup;
   }

   pResult = nox_NewObject();

   for (i = 0 ; i < numberOfParms ; i ++) {
      p = &procParms[i];
      if (p->mode != SQL_PARAM_OUTPUT && p->mode != SQL_PARAM_INPUT_OUTPUT) continue;

      // json is always in lower ( in this implementation)
      a_str_to_lower (p->name , p->name);

      if (p->inLen == SQL_NULL_DATA ) {
         nox_NodeInsertNew (pResult , NOX_RL_LAST_CHILD, p->name , NULL , NOX_LITERAL);
         continue;
      }

      switch (p->sqlType) {
         case SQL_CHAR:
         case SQL_VARCHAR:
         case SQL_TIMESTAMP:
         case SQL_DATE:
         case SQL_TIME:
         case SQL_DECIMAL:
         case SQL_NUMERIC:
         case SQL_BOOLEAN:
            if (p->inLen >= 0 && p->inLen <= p->bufLen) p->buffer[p->inLen] = '\0';
            p->buffer[p->bufLen] = '\0';
            {  // The CLI pads character output to the buffer size: trim trailing blanks
               PUCHAR end = p->buffer + strlen(p->buffer);
               while (end > p->buffer && *(end-1) == ' ') end--;
               *end = '\0';
            }
            if (p->isBool) { // Pollyfill for BOOLEAN pre 7.5
               nox_SetValueByName(pResult , p->name, (*p->buffer == '1' || *p->buffer == 't') ? "true":"false", NOX_LITERAL);
            } else {
               if (p->sqlType == SQL_TIMESTAMP && isoTimestamp == ON) {
                  ts_ibm2iso8601(p->buffer);
               }
               nox_SetValueByName(pResult , p->name, p->buffer , p->type);
            }
            break;
         case SQL_SMALLINT:
            a_sprintf(temp, "%hd" , * (SHORT *) p->buffer);
            nox_SetValueByName(pResult , p->name, temp , NOX_LITERAL);
            break;
         case SQL_INTEGER:
            a_sprintf(temp, "%ld" , * (LONG *) p->buffer);
            nox_SetValueByName(pResult , p->name, temp , NOX_LITERAL);
            break;
         case SQL_BIGINT:
            a_sprintf(temp, "%lld" , * (INT64*) p->buffer);
            nox_SetValueByName(pResult , p->name, temp , NOX_LITERAL);
            break;
         case SQL_REAL:
         case SQL_DOUBLE:
         default: {
            PUCHAR c;
            double d = p->sqlType == SQL_REAL ? * (float *) p->buffer : * (double *) p->buffer;
            a_sprintf(temp, "%.10f" , d);
            for (c = temp; *c; c++) if (*c == ',') *c = '.'; // locale safety
            nox_SetValueByName(pResult , p->name, temp , NOX_LITERAL);
            break;
         }
      }
   }
   nox_sqlClose (&pSQL);

cleanup:
   for (i = 0 ; i < numberOfParms ; i ++) memFree ((PVOID *) &procParms[i].buffer);
   memFree ((PVOID *) &procParms);
   memFree ((PVOID *) &stmtBuf);
   nox_NodeDelete (pProcMeta);
   return pResult;
}
// RPG: nox_sqlCall (pConnection : procedureName : inputParms)
PNOXNODE nox_sqlCall (PNOX_SQLCONNECT pCon, PLVARCHAR procedureName , PNOXNODE pInParms)
{
   return nox_sqlCallStr (pCon, plvc2str(procedureName) , pInParms);
}
/* ------------------------------------------------------------- */
/* .........
int getColType(SQLHSTMT hstmt , SHORT col )
{
   NOXCOL Col;

   int rc = SQLDescribeCol (
      hstmt,
      col,
      Col.colname,
      sizeof (Col.colname),
      &Col.colnamelen,
      &Col.coltype,
      &Col.collen,
      &Col.scale,
      &Col.nullable
   );

   return (Col.coltype);
}
....... */
/* ------------------------------------------------------------- */
/* does this work ?  */
/* ------------------------------------------------------------- */
static BOOL isIdColumn(SQLHSTMT hstmt , int colno)
{
   int rc;
   SQLINTEGER isTrue;

   // is it an ID column ? get the label, if no label then use the column name
   isTrue = SQL_FALSE;
   rc = SQLColAttribute (hstmt, colno,SQL_DESC_AUTO_INCREMENT, NULL, 0, NULL ,&isTrue);
   // rc = SQLColAttribute (hstmt, colno,SQL_DESC_UPDATABLE, NULL, 0, NULL ,&isTrue);
   return (isTrue == SQL_TRUE);
}
/* ------------------------------------------------------------- */
/* This is required for this wird reason:                        */
/* If you update a row containing a CLOB or BLOB with            */
/* data over 32K it will fail and create a SQL trap error        */
/* if you also are updating another column with a bound          */
/* blank value.                                                  */
/*                                                               */
/* Therfor you will see tha blanks and nulls are updated         */
/* and inserted by SQL constants and not by bound markers        */
/* ------------------------------------------------------------- */
static BOOL  nodeisnull(PNOXNODE pNode)
{
   PUCHAR val;

   if (pNode == NULL) return true;

   // has always a content ...
   if (pNode->type == NOX_ARRAY ||  pNode->type == NOX_OBJECT) {
      // .. so this will fail
      // pNode =  nox_GetNodeChild (pNode);
      // if (pNode != NULL) return false;
      return false;
   }

   val = nox_GetNodeValuePtr (pNode , NULL);
   return (val == null);
}
/* ------------------------------------------------------------- */
/* This is required for this wird reason:                        */
/* If you update a row containing a CLOB or BLOB with            */
/* data over 32K it will fail and create a SQL trap error        */
/* if you also are updating another column with a bound          */
/* blank value.                                                  */
/*                                                               */
/* Therfor you will see tha blanks and nulls are updated         */
/* and inserted by SQL constants and not by bound markers        */
/* ------------------------------------------------------------- */
static BOOL  nodeisblank(PNOXNODE pNode)
{
   PUCHAR val;

   if (pNode == NULL) return true;

   // has always a content ...
   if (pNode->type == NOX_ARRAY ||  pNode->type == NOX_OBJECT) {
      // .. so this will fail
      // pNode =  nox_GetNodeChild (pNode);
      // if (pNode != NULL) return false;
      return false;
   }

   if (pNode->isLiteral) return false;
   val = nox_GetNodeValuePtr (pNode , null);
   if (val == null) return false;
   if (*val == 0) return true;
   return false;
}
/* ------------------------------------------------------------- */
/* Column names for the generated insert / update statements:    */
/* upper case, cut at the longest name Db2 has (a longer name     */
/* fails in SQL anyway). "out" holds COLNAME_BUF bytes            */
/* ------------------------------------------------------------- */
#define COLNAME_MAX 128
#define COLNAME_BUF 256
static void colName (PUCHAR out , PUCHAR name)
{
   UCHAR work [COLNAME_MAX + 1];
   LONG  len = strlen(name);
   if (len > COLNAME_MAX) len = COLNAME_MAX;
   substr (work , name , len);
   a_str2upper (out , work);   // Needed for national charse in columns names i.e.: BELØB
}
/* ------------------------------------------------------------- */
static LONG rowColumns (PNOXNODE pRow)
{
   LONG n = 0;
   PNOXNODE pNode;
   for (pNode = nox_GetNodeChild (pRow); pNode; pNode = nox_GetNodeNext(pNode)) n++;
   return n;
}
/* ------------------------------------------------------------- */
/* Room for an insert / update / meta select of pRow: per column  */
/* a comma, the name and "=default" / ",default"                  */
/* ------------------------------------------------------------- */
static LONG rowStmtSize (PUCHAR table , PNOXNODE pRow, PUCHAR where)
{
   return strlen(table) + (where ? strlen(where) : 0) + 64
        + rowColumns (pRow) * (COLNAME_BUF + 16);
}
/* ------------------------------------------------------------- */
static void buildUpdate (SQLHSTMT hstmt, SQLHSTMT hMetastmt,
   PUCHAR sqlStmt, PUCHAR table, PNOXNODE pSqlParms , PUCHAR where)
{
   PUCHAR  stmt = sqlStmt;
   PUCHAR  comma = "";
   PNOXNODE pNode;
   PUCHAR  name;
   int     colno;
   UCHAR   temp [COLNAME_BUF];

   stmt += strjoin (stmt , "update " , table , " set " );

   pNode    =  nox_GetNodeChild (pSqlParms);
   for ( colno=1; pNode; colno++) {
      if (! isIdColumn(hMetastmt, colno)) {
         name  = nox_GetNodeNamePtr   (pNode);
         colName (temp  , name);
         if  (nodeisnull(pNode)) {
            stmt += strjoin (stmt , comma , temp ,"=NULL");
         } else if  (nodeisblank(pNode)) {
            stmt += strjoin (stmt , comma , temp ,"=default" );    // because timesstamp / date can be set as ''
         } else {
            stmt += strjoin (stmt , comma , temp ,"=?"  );
         }
         comma = ",";
      }
      pNode = nox_GetNodeNext(pNode);
   }

   stmt += strjoin (stmt , " " , where , " ");
}
/* ------------------------------------------------------------- */
static void buildInsert  (SQLHSTMT hstmt, SQLHSTMT hMetaStmt,
   PUCHAR sqlStmt, PUCHAR table, PNOXNODE pSqlParms , PUCHAR where)
{
   PUCHAR  stmt = sqlStmt;
   PUCHAR  comma = "";
   PNOXNODE pNode;
   PUCHAR  name;
   PUCHAR  value;
   int     i,colno;
   PUCHAR  markers = memAlloc (rowColumns (pSqlParms) * 8 + 1);  // ",default" per column at most
   UCHAR   temp [COLNAME_BUF];
   PUCHAR  pMarker = markers;

   *markers = '\0';

   stmt += strjoin  (stmt , "insert into " , table , " (" );

   pNode = nox_GetNodeChild (pSqlParms);
   for ( colno=1; pNode; colno++) {
      if (! isIdColumn(hMetaStmt, colno)) {
         if (!nodeisnull(pNode)) {
            name     = nox_GetNodeNamePtr   (pNode);
            colName (temp  , name);
            stmt    += strjoin (stmt , comma , temp);
            if  (nodeisblank(pNode)) {
               pMarker+= strjoin (pMarker , comma ,"default" );    // because timesstamp / date can be set as ''
            } else {
               pMarker+= strjoin (pMarker , comma , "?" );
            }
            comma = ",";
         }
      }
      pNode = nox_GetNodeNext(pNode);
   }

   stmt += strjoin (stmt , ") values(" ,  markers , ")") ;
   memFree ((PVOID *) &markers);
}
/* ------------------------------------------------------------- */
void createTracetable(PNOX_SQLCONNECT pCon)
{
   PNOX_TRACE pTrc = &pCon->sqlTrace;
   UCHAR  t [512];
   strjoin (t ,
      "CREATE TABLE " , pTrc->lib, ".sqlTrace ("
      "   STSTART TIMESTAMP NOT NULL WITH DEFAULT,        "
      "   STEND TIMESTAMP NOT NULL WITH DEFAULT,          "
      "   STSQLSTATE CHAR(5) NOT NULL WITH DEFAULT,         "
      "   STTEXT VARCHAR ( 256) NOT NULL WITH DEFAULT,      "
      "   STJOB  VARCHAR ( 30) NOT NULL WITH DEFAULT,       "
      "   STTRID BIGINT NOT NULL WITH DEFAULT,              "
      "   STSQLSTMT VARCHAR ( 8192) NOT NULL WITH DEFAULT)  ");


   pTrc->doTrace =  OFF; // So we don't end up in a recusive death spiral
   nox_sqlExec(pCon, t , NULL);
   pTrc->doTrace =  ON;
}
/* ------------------------------------------------------------- */
/* The library this service program is in - wherever it is and   */
/* whatever it is called (renamed copies, library-qualified      */
/* binding, not in the library list). No SQL, no library list.   */
/* Returns the name blank padded (EBCDIC) to 10 and zero         */
/* terminated, as TRACE expects it.                              */
/* ------------------------------------------------------------- */
static void ownLibrary (UCHAR lib[11])
{
   _MATPGMNM_Template_T pgmName;
   memset(&pgmName, 0, sizeof(pgmName));
   pgmName.Template_Size = sizeof(pgmName);
   _MATPGMNM(&pgmName);
   memcpy(lib, pgmName.Format_0.Context.Name, 10);
   lib[10] = '\0';
}
/* ------------------------------------------------------------- */
void nox_traceOpen (PNOX_SQLCONNECT pCon)
{
   PNOX_TRACE pTrc = &pCon->sqlTrace;
   int rc;
   PUCHAR insertStmt = "insert into sqltrace (STSTART,STEND,STSQLSTATE,STTEXT,STJOB,STTRID,STSQLSTMT) "
                  "values (?,?,?,?,?,?,?)";

   ownLibrary (pTrc->lib);
   TRACE ( pTrc->lib , &pTrc->doTrace , pTrc->job);
   if (pTrc->doTrace == OFF) return;
   createTracetable(pCon);
   rc = SQLAllocStmt(pCon->hdbc, &pTrc->handle);
   rc = SQLPrepare(pTrc->handle , insertStmt, SQL_NTS);

   rc = SQLBindParameter(pTrc->handle,1,SQL_PARAM_INPUT,SQL_C_CHAR,SQL_TIMESTAMP,26 ,0,pTrc->tsStart,0,NULL);
   rc = SQLBindParameter(pTrc->handle,2,SQL_PARAM_INPUT,SQL_C_CHAR,SQL_TIMESTAMP,26 ,0,pTrc->tsEnd  ,0,NULL);
   // rc = SQLBindParameter(pTrc->handle,3,SQL_PARAM_INPUT,SQL_C_LONG,SQL_INTEGER  , 9 ,0,pTrc->sqlcode,0,NULL);
   rc = SQLBindParameter(pTrc->handle,4,SQL_PARAM_INPUT,SQL_C_CHAR,SQL_VARCHAR  ,256,0,pTrc->text   ,0,NULL);
   rc = SQLBindParameter(pTrc->handle,5,SQL_PARAM_INPUT,SQL_C_CHAR,SQL_VARCHAR  ,28 ,0,pTrc->job    ,0,NULL);
   rc = SQLBindParameter(pTrc->handle,6,SQL_PARAM_INPUT,SQL_C_BIGINT,SQL_BIGINT ,18 ,0,&pTrc->trid  ,0,NULL);
   // rc = SQLBindParameter(pTrc->handle,7,SQL_PARAM_INPUT,SQL_C_CHAR,SQL_VARCHAR ,8192,0,pTrc->sqlstmt,0,NULL);
}
/* ------------------------------------------------------------- */
void nox_TraceSetId (PNOX_SQLCONNECT pCon, INT64 trid)
{
   PNOX_TRACE pTrc = &pCon->sqlTrace;
   pTrc->trid = trid;
}
/* ------------------------------------------------------------- */
void nox_traceInsert (PNOX_SQL pSQL, PUCHAR stmt , PUCHAR sqlState)
{
   if (pSQL == NULL || pSQL->pCon == NULL ) return;
   PNOX_TRACE pTrc = &pSQL->pCon->sqlTrace; // !!! TODO not from global !!!
   if (pTrc->doTrace == OFF) return;
   int rc;
   rc = SQLBindParameter(pTrc->handle,3,SQL_PARAM_INPUT,SQL_C_CHAR,SQL_CHAR    ,   5,0,sqlState,0,NULL);
   rc = SQLBindParameter(pTrc->handle,7,SQL_PARAM_INPUT,SQL_C_CHAR,SQL_VARCHAR ,8192,0,stmt,0,NULL);

   // insert row
   rc = SQLExecute(pTrc->handle);

}
/* ------------------------------------------------------------- */
SHORT  doInsertOrUpdate(
   PNOX_SQL pSQL,
   PNOX_SQL pSQLmeta,
   PUCHAR sqlTempStmt,
   PUCHAR table ,
   PNOXNODE pRow,
   PUCHAR where ,
   BOOL   update
)
{
   LONG   attrParm;
   LONG   colno;
   LONG   i;
   PUCHAR * valArr;        // JSON text of object / array columns - one per column at most
   LONG   valArrIx= 0;
   SQLINTEGER sql_nts;
   SQLINTEGER bindColNo;

   PNOXNODE pNode;
   PUCHAR comma = "";
   PUCHAR name, value;

   SQLSMALLINT   length;
   SQLRETURN     rc;
   PUCHAR        sqlNullPtr = NULL;

   if (pSQL == NULL || pSQL->pstmt == NULL) return -1;

   a_str2upper(table , table);

   // Now we have the colume definitions - now build the update statement:
   if (update) {
      buildUpdate (pSQL->pstmt->hstmt, pSQLmeta->pstmt->hstmt, sqlTempStmt , table, pRow , where);
   } else {
      buildInsert (pSQL->pstmt->hstmt, pSQLmeta->pstmt->hstmt, sqlTempStmt , table, pRow , where);
   }

   // prepare the statement that will do the update
   rc = SQLPrepare(pSQL->pstmt->hstmt , sqlTempStmt, SQL_NTS);
   if (rc  != SQL_SUCCESS ) {
      if (-109 == getSqlCode(pSQL->pstmt->hstmt)) {
         return rc; // we  have an error - so try with next...
      }
      check_error (pSQL->pCon, pSQL);
      return rc; // we have an error, and die
   }

   // From here on: leave through "cleanup", it frees the JSON text in valArr
   valArr = memAlloc ((rowColumns (pRow) + 1) * sizeof(PUCHAR));

   // Take the description from the "select" and use it on the "update"
   pNode    =  nox_GetNodeChild (pRow);
   bindColNo =0;
   for(colno =1; pNode ; colno ++) {
      int realLength;
      NOXCOL Col;
      BOOL isId = isIdColumn(pSQLmeta->pstmt->hstmt, colno);

      if (!isId && !nodeisnull(pNode) && !nodeisblank(pNode)) {

         bindColNo ++; // Only columns with data ( not null nor blank) need to be bound

         memset (&Col , 0 , sizeof(NOXCOL));
         rc = SQLDescribeCol (
            pSQLmeta->pstmt->hstmt,
            colno,    // The meta "cursor" contaians all columns
            Col.colname,
            sizeof (Col.colname),
            &Col.colnamelen,
            &Col.coltype,
            &Col.collen,
            &Col.scale,
            &Col.nullable
         );

         if (rc != SQL_SUCCESS ) {
            check_error (pSQL->pCon, pSQL);
            goto cleanup; // we have an error
         }


         if (pNode->type == NOX_ARRAY ||  pNode->type == NOX_OBJECT) {
            value = valArr[valArrIx++] = memAlloc(Col.collen + 1);
            realLength = nox_AsJsonTextMem (pNode , value,  Col.collen );
            value [realLength] = '\0';
         } else {
            value = nox_GetNodeValuePtr  (pNode , NULL);
            realLength = strlen(value);
         }

         // Long data > 32K will be chopped into chunks for update.
         if (realLength > 32000) {
            // Set parameters based on total data to send.
            SQLINTEGER lbytes = realLength;
            SQLINTEGER cbTextSize = SQL_DATA_AT_EXEC;

            // Bind the parameter marker.
            rc  = SQLBindParameter (
               pSQL->pstmt->hstmt, // hstmt
               bindColNo,
               SQL_PARAM_INPUT,  // fParamType
               SQL_C_CHAR,       // fCType
               Col.coltype,      // FSqlType
               lbytes,           // cbColDef
               0,                // ibScale
               pNode,            // rgbValue - store the complete node. Here SQL RPC are very flexible - any pointer
               0,                // cbValueMax
               &cbTextSize       // pcbValue
            );
            if ( rc  != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO && rc != SQL_NEED_DATA ) {
               check_error (pSQL->pCon, pSQL);
               goto cleanup; // we have an error
            }

         } else {

            // length  !!! 1234,56 gives 6 digits                                              //GIT
            SQLINTEGER colLen = Col.coltype  == SQL_TIMESTAMP ? Col.collen : realLength + Col.scale;  //GIT
            sql_nts = SQL_NTS;

            rc = SQLBindParameter(
               pSQL->pstmt->hstmt,
               bindColNo,
               SQL_PARAM_INPUT,
               SQL_C_CHAR,
               Col.coltype,
               colLen,       // column len - Take care: timestamp need real length of colum. Numbers need string le//GIT
               Col.scale,    // presition
               value,
               0,
               &sql_nts // NULL terminated string -(pointer to length variable)
            );
         }

         if (rc != SQL_SUCCESS ) {
            check_error (pSQL->pCon, pSQL);
            goto cleanup; // we have an error
         }
      }
      pNode = nox_GetNodeNext(pNode);
   }

   // run  the  statement in "sqlstr"
   rc = SQLExecute( pSQL->pstmt->hstmt);

   if (rc == SQL_NEED_DATA) {
      // Check to see if NEED_DATA; if yes, use SQLPutData.
      rc  = SQLParamData(pSQL->pstmt->hstmt, &pNode);
      while (rc == SQL_NEED_DATA) {
         LONG    cbBatch = 32000; // Dont use real 32K it will be to large a buffer
         PUCHAR  value = nox_GetNodeValuePtr (pNode , NULL);
         LONG    lbytes = strlen(value);

         while (lbytes > cbBatch) {
            rc = SQLPutData(pSQL->pstmt->hstmt, value , cbBatch);
            lbytes -= cbBatch;
            value  += cbBatch;
         }

         // Put final batch.
         rc = SQLPutData(pSQL->pstmt->hstmt, value, lbytes);

         // Setup next column
         rc = SQLParamData(pSQL->pstmt->hstmt, &pNode  );
      }
   }

   if (rc != SQL_SUCCESS && rc != SQL_NO_DATA_FOUND) {
      check_error (pSQL->pCon, pSQL);
   }

cleanup:
   for(i=0;i<valArrIx; i++) {
      memFree((PVOID *) &valArr[i]);
   }
   memFree ((PVOID *) &valArr);
   return rc;

}

/* ------------------------------------------------------------- */
static PNOX_SQL buildMetaStmt (PNOX_SQLCONNECT pCon, PUCHAR table, PNOXNODE pRow)
{
   PUCHAR    sqlTempStmt = memAlloc (rowStmtSize (table , pRow , NULL));
   PUCHAR    stmt = sqlTempStmt;
   PUCHAR    name;
   UCHAR     temp  [COLNAME_BUF];
   PNOXNODE   pNode;
   PUCHAR    comma = "";
   SQLRETURN rc;
   PNOX_SQL    pSQLmeta = nox_sqlNewStatement (pCon, NULL, false, false);

   stmt += cpy (stmt , "select ");

   comma = "";
   pNode    =  nox_GetNodeChild (pRow);
   while (pNode) {
      name  = nox_GetNodeNamePtr   (pNode);
      colName (temp  , name);
      stmt += strjoin (stmt , comma ,temp);
      comma = ",";
      pNode = nox_GetNodeNext(pNode);
   }

   stmt += strjoin  (stmt , " from " , table , " where 1=0 with ur");

   // prepare the statement that provides the columns
   rc = SQLPrepare(pSQLmeta->pstmt->hstmt , sqlTempStmt, SQL_NTS);
   memFree ((PVOID *) &sqlTempStmt);
   if (rc != SQL_SUCCESS ) {
      check_error (pCon, pSQLmeta);
      nox_sqlClose (&pSQLmeta); // Free the data
      return NULL;
   }
   return  pSQLmeta;
}
/* ------------------------------------------------------------- */
LGL nox_sqlUpdateOrInsert (PNOX_SQLCONNECT pCon, BOOL update, PUCHAR table  , PNOXNODE pRowP , PUCHAR whereP, PNOXNODE pSqlParms)
{
   LONG   attrParm;
   LONG   i;
   PUCHAR sqlTempStmt = NULL;
   PUCHAR where = NULL;
   PNOXNODE pNode;
   PUCHAR comma = "";
   PUCHAR name, value;

   SQLSMALLINT   length;
   SQLRETURN     rc;
   PNOX_SQL       pSQL     = nox_sqlNewStatement (pCon, NULL, true, false);
   PNOX_SQL       pSQLmeta;
   NOX_SQLCHUNK      sqlChunk[32];
   SHORT         sqlChunkIx =0;
   PUCHAR        sqlNullPtr = NULL;
   PNOXNODE      pRow = nox_ParseString((PUCHAR) pRowP);
   LGL err = ON; // assume error


   // First get the columen types - by now we use a select to mimic that
   pSQLmeta = buildMetaStmt ( pCon, table, pRow);
   if (pSQLmeta == NULL) {
      goto cleanup;
   }

   where = strFormatAlloc (whereP , pSqlParms , 0);
   sqlTempStmt = memAlloc (rowStmtSize (table , pRow , where));
   rc = doInsertOrUpdate(pSQL, pSQLmeta, sqlTempStmt, table,pRow, where , update);

   // So far we suceeded: But with data ?
   err = (rc == SQL_SUCCESS) ? OFF:ON;

   if (err == OFF) {
      pCon->sqlCode =0;
   } else if ( pSQL && pSQL->pstmt) {
      pCon->sqlCode = getSqlCode (pSQL->pstmt->hstmt);
   }

   // Now we are done with the select statement:
cleanup:
   if (sqlTempStmt) memFree ((PVOID *) &sqlTempStmt);
   if (where)       memFree ((PVOID *) &where);
   if (pRowP != pRow) nox_NodeDelete (pRow);
   nox_sqlClose (&pSQLmeta); // Free the data
   nox_sqlClose (&pSQL);
   return err;
}
/* ------------------------------------------------------------- */
LGL nox_sqlUpdate (PNOX_SQLCONNECT pCon, PUCHAR table  , PNOXNODE pRow , PUCHAR where, PNOXNODE pSqlParms  )
{
   PUCHAR whereStr = NULL;
   LGL    err;
   for(; *where == ' ' ; where++); // skip leading blanks
   if (*where > ' ' && ! a_memiBeginsWith(where, "where")) {
      whereStr = memAlloc (strlen(where) + 8);
      strjoin (whereStr , "where ", where);
      where = whereStr;
   }
   err = nox_sqlUpdateOrInsert  (pCon, true , table  , pRow , where, pSqlParms);
   if (whereStr) memFree ((PVOID *) &whereStr);
   return err;
}
/* ------------------------------------------------------------- */
LGL nox_sqlUpdateVC (PNOX_SQLCONNECT pCon, PLVARCHAR table  , PNOXNODE pRow , PLVARCHAR whereP, PNOXNODE pSqlParmsP  )
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PUCHAR  where     = (pParms->OpDescList->NbrOfParms >= 4) ? plvc2str(whereP) : "";
   PNOXNODE pSqlParms = (pParms->OpDescList->NbrOfParms >= 5) ? pSqlParmsP : NULL;
   return nox_sqlUpdate (pCon, plvc2str (table)   , pRow , where, pSqlParms);
}
/* ------------------------------------------------------------- */
LGL nox_sqlInsert (PNOX_SQLCONNECT pCon, PUCHAR table  , PNOXNODE pRow , PUCHAR where, PNOXNODE pSqlParms  )
{
   return nox_sqlUpdateOrInsert  (pCon, false , table  , pRow , where , pSqlParms);
}
LGL nox_sqlInsertVC (PNOX_SQLCONNECT pCon,PLVARCHAR table  , PNOXNODE pRow , PLVARCHAR whereP, PNOXNODE pSqlParmsP  )
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PUCHAR  where    =  (pParms->OpDescList->NbrOfParms >= 4) ? plvc2str(whereP) : "";
   PNOXNODE pSqlParms = (pParms->OpDescList->NbrOfParms >= 5) ? pSqlParmsP : NULL;
   return nox_sqlUpdateOrInsert  (pCon, false , plvc2str(table)  , pRow , where , pSqlParms);
}
/* ------------------------------------------------------------- */
LGL nox_sqlUpsert (PNOX_SQLCONNECT pCon, PUCHAR table  , PNOXNODE pRow , PUCHAR where, PNOXNODE pSqlParms  )
{
   LGL err;
   // First update - if not found the insert
   err = nox_sqlUpdate  ( pCon, table  , pRow , where, pSqlParms);
   if (err == ON && nox_sqlCode(pCon) == 100) {
      err = nox_sqlInsert (pCon, table  , pRow , where, pSqlParms);
   }
   return err;
}
/* ------------------------------------------------------------- */
LGL nox_sqlUpsertVC (PNOX_SQLCONNECT pCon, PLVARCHAR table  , PNOXNODE pRow , PLVARCHAR whereP, PNOXNODE pSqlParmsP  )
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PUCHAR  where     = (pParms->OpDescList->NbrOfParms >= 4) ? plvc2str(whereP) : "";
   PNOXNODE pSqlParms = (pParms->OpDescList->NbrOfParms >= 5) ? pSqlParmsP : NULL;
   return nox_sqlUpsert (pCon, plvc2str(table)  , pRow , where, pSqlParms);

}
/* -------------------------------------------------------------------
 * Provide options to a pSQL environment - If NULL then use the default
 * ------------------------------------------------------------------- */
LONG nox_sqlGetInsertId (PNOX_SQLCONNECT pCon)
{
   LONG    id;
   PNOXNODE pRow, pChild;
   // PUCHAR  sqlStmt = "values IDENTITY_VAL_LOCAL() into :id";
   // PUCHAR  sqlStmt = "Select IDENTITY_VAL_LOCAL() as id from sysibm.sysdummy1";
   PUCHAR  sqlStmt = "values identity_val_local()";

   // Get that only row
   pRow = nox_sqlResultRow(pCon, sqlStmt, NULL,1,0);
   pChild  = nox_GetNodeChild (pRow);
   id = a2i(nox_GetValuePtr(pChild, NULL , "-1"));
   nox_NodeDelete (pRow);

   return id ;
}
/* -------------------------------------------------------------------
 * Provide options to a pSQL environment - If NULL the use the default
 * ------------------------------------------------------------------- */
void nox_sqlSetOptions (PNOX_SQLCONNECT pCon, PNOXNODE pOptionsP)
{

   PNOX_SQLOPTIONS po = &pCon->options;
   PNOXNODE pNode;

   // Delete previous settings, if we did that parsing
   if (pCon->pOptionsCleanup) {
      nox_NodeDelete (pCon->pOptions);
   }

   // .. and set the new setting
   pCon->pOptionsCleanup = false;
   if (ON == nox_isNode(pOptionsP)) {
      pCon->pOptions = pOptionsP;
   } else if (pOptionsP != NULL) {
      pCon->pOptions = nox_ParseString ((PUCHAR) pOptionsP);
      pCon->pOptionsCleanup = true;
   }

   pNode    =  nox_GetNodeChild (pCon->pOptions);
   while (pNode) {
      int rc = SQL_SUCCESS;
      PUCHAR name, value;
      LONG attrParm;
      name  = nox_GetNodeNamePtr   (pNode);
      value = nox_GetNodeValuePtr  (pNode , NULL);

      // Is header overriden by userprogram ?
      if (a_memiBeginsWith(name , "upperCaseColName")) {
         po->upperCaseColName = *value == 't'? ON:OFF; // for true
      }
      else if (a_memiBeginsWith(name , "autoParseContent")) {
         po->autoParseContent = *value == 't' ? ON:OFF; // for true
      }
      else if (a_memiBeginsWith(name , "decimalPoint")) {
         po->DecimalPoint = *value;
      }
      else if (a_memiBeginsWith(name , "sqlNaming")) {
         po->sqlNaming = *value == 't' ? ON:OFF; // for true
         attrParm = po->sqlNaming == OFF; // sysname is invers of SQL naming :(
         rc = SQLSetConnectAttr     (pCon->hdbc , SQL_ATTR_DBC_SYS_NAMING, &attrParm  , 0);
      }
      // NOTE !! hexSort can only be set at environlevel - befor connect time !!!
      // else if (a_memiBeginsWith(name , "hexSort")) {
      //   po->hexSort = *value == 't' ? ON:OFF; // for true
      //}
      if (rc  != SQL_SUCCESS ) {
         check_error (pCon, NULL);
         return ; // we have an error
      }

      /* more to come....
         po->DateSep;
         po->DateFmt;
         po->TimeSep;
         po->TimeFmt;
         po->DecimalPoint;
      */
      pNode = nox_GetNodeNext(pNode);
   }
}
/* ------------------------------------------------------------- */
/* original
PNOX_SQLCONNECT nox_sqlConnect(PNOXNODE pOptionsP)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PNOXNODE  pOptions = pParms->OpDescList->NbrOfParms >= 1 ? pOptionsP : NULL;
   PNOX_SQLCONNECT pCon;
   LONG          attrParm;
   PUCHAR        server = "*LOCAL";
   int rc;
   PNOX_SQLOPTIONS po;

   pCon = memAllocClear(sizeof(NOX_SQLCONNECT));
   pCon->sqlTrace.handle = -1;
   pCon->iconv = XlateOpen (13488, 0, false);
   po = &pCon->options;
   po->upperCaseColName = OFF;
   po->autoParseContent = ON;
   po->DecimalPoint     = '.';
   po->hexSort          = OFF;
   po->sqlNaming        = OFF;
   po->DateSep          = '-';
   po->DateFmt          = 'y';
   po->TimeSep          = ':';
   po->TimeFmt          = 'H';

   // allocate an environment handle
   rc = SQLAllocEnv (&pCon->henv);
   if (rc != SQL_SUCCESS ) {
      check_error (pCon, NULL);
      nox_sqlDisconnect (&pCon);
      return NULL; // we have an error
   }

   // always use UTF-8 in noxDbUtf8
   attrParm = SQL_TRUE;
   rc = SQLSetEnvAttr  (pCon->henv, SQL_ATTR_UTF8 , &attrParm  , 0);
   if (rc != SQL_SUCCESS ) {
      check_error (pCon, NULL);
      nox_sqlDisconnect (&pCon);
      return NULL; // we have an error
   }

   // Note - this is invers: Default to IBM i naming
   attrParm = pCon->options.sqlNaming == ON ? SQL_FALSE : SQL_TRUE;
   rc = SQLSetEnvAttr  (pCon->henv, SQL_ATTR_SYS_NAMING, &attrParm  , 0);
   / * Dont test since the activations groupe might be reclaimed, and a new "session" is on..
   if (rc != SQL_SUCCESS ) {
      check_error (NULL);
      nox_sqlDisconnect ();
      return NULL; // we have an error
   }
   ... * /

   attrParm = SQL_TRUE;
   rc = SQLSetEnvAttr  (pCon->henv, SQL_ATTR_JOB_SORT_SEQUENCE , &attrParm  , 0);
   if (rc != SQL_SUCCESS ) {
      nox_sqlDisconnect (&pCon);
      return NULL; // we have an error
   }

   rc = SQLAllocConnect (pCon->henv, &pCon->hdbc);  // allocate a connection handle
   if (rc != SQL_SUCCESS ) {
      check_error (pCon, NULL);
      nox_sqlDisconnect (&pCon);
      return NULL; // we have an error
   }

   attrParm = SQL_TXN_NO_COMMIT; // does not work with BLOBS
   // attrParm = SQL_TXN_READ_UNCOMMITTED; // does not work for updates !!! can not bes pr- statement
   rc = SQLSetConnectAttr (pCon->hdbc, SQL_ATTR_COMMIT , &attrParm  , 0);
   if (rc != SQL_SUCCESS ) {
      check_error (pCon, NULL);
      nox_sqlDisconnect (&pCon);
      return NULL; // we have an error
   }

   rc = SQLConnect (pCon->hdbc, server , SQL_NTS, NULL, SQL_NTS, NULL, SQL_NTS);
   if (rc != SQL_SUCCESS ) {
      check_error (pCon, NULL);
      nox_sqlDisconnect (&pCon);
      return NULL; // we have an error
   }

   // If required, open the trace table
   nox_traceOpen (pCon);

   pLastConnnection = pCon;
   return pCon; // we are ok
}*/



PNOX_SQLCONNECT nox_sqlConnect(PNOXNODE pOptionsP)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PNOXNODE  pOptions = pParms->OpDescList->NbrOfParms >= 1 ? pOptionsP : NULL;
   PNOX_SQLCONNECT pCon;
   LONG          attrParm;
   PUCHAR        server = "*LOCAL";
   int rc;
   PNOX_SQLOPTIONS po;

   pCon = memAllocClear(sizeof(NOX_SQLCONNECT));
   pCon->sqlTrace.handle = -1;
   pCon->iconv = XlateOpen (13488, 0, false);
   po = &pCon->options;
   po->upperCaseColName = OFF;
   po->autoParseContent = ON;
   po->DecimalPoint     = '.';
   po->hexSort          = OFF;
   po->sqlNaming        = OFF;
   po->DateSep          = '-';
   po->DateFmt          = 'y';
   po->TimeSep          = ':';
   po->TimeFmt          = 'H';

   // allocate an environment handle
   rc = SQLAllocEnv (&pCon->henv);
   if (rc != SQL_SUCCESS ) {
      check_error (pCon, NULL);
      nox_sqlDisconnect (&pCon);
      return NULL; // we have an error
   }

   // Scope CLI resources to the top program on the stack. This preserves
   // cursors, statements, and other resources when a service program leaves
   // the stack and is re-entered later in the job.
   SQLINTEGER value = 1;
   rc = SQLSetEnvAttr (pCon->henv, SQL_ATTR_INVOKING_PGM,
                       (SQLPOINTER)&value, 0);
   if (rc != SQL_SUCCESS ) {
      check_error (pCon, NULL);
      nox_sqlDisconnect (&pCon);
      return NULL; // we have an error
   }

   // This is OK for now - it will inhirit it from the initial connection
   // and work from out side as well
   // so just dont, test if the call went ok
   attrParm = SQL_TRUE;
   rc = SQLSetEnvAttr  (pCon->henv, SQL_ATTR_JOB_SORT_SEQUENCE , &attrParm  , 0);
   // if (rc != SQL_SUCCESS ) {
   //    nox_sqlDisconnect (&pCon);
   //    return NULL; // we have an error
   // }


   // connection!!
   rc = SQLAllocConnect (pCon->henv, &pCon->hdbc);  // allocate a connection handle
   if (rc != SQL_SUCCESS ) {
      check_error (pCon, NULL);
      nox_sqlDisconnect (&pCon);
      return NULL; // we have an error
   }

   // always use UTF-8 in noxDbUtf8
   attrParm = SQL_TRUE;
   rc = SQLSetConnectAttr  (pCon->hdbc, SQL_ATTR_UTF8 , &attrParm  , 0);
   if (rc != SQL_SUCCESS ) {
      check_error (pCon, NULL);
      nox_sqlDisconnect (&pCon);
      return NULL; // we have an error
   }

   // Note - this is invers: Default to IBM i naming
   attrParm = pCon->options.sqlNaming == ON ? SQL_FALSE : SQL_TRUE;
   rc = SQLSetConnectAttr  (pCon->hdbc, SQL_ATTR_SYS_NAMING, &attrParm  , 0);
   // /* Dont test since the activations groupe might be reclaimed, and a new "session" is on..
   // if (rc != SQL_SUCCESS ) {
   //    check_error (NULL);
   //    nox_sqlDisconnect ();
   //    return NULL; // we have an error
   // }


   attrParm = SQL_TXN_NO_COMMIT; // does not work with BLOBS
   // attrParm = SQL_TXN_READ_UNCOMMITTED; // does not work for updates !!! can not bes pr- statement
   rc = SQLSetConnectAttr (pCon->hdbc, SQL_ATTR_COMMIT , &attrParm  , 0);
   if (rc != SQL_SUCCESS ) {
      check_error (pCon, NULL);
      nox_sqlDisconnect (&pCon);
      return NULL; // we have an error
   }

   rc = SQLConnect (pCon->hdbc, server , SQL_NTS, NULL, SQL_NTS, NULL, SQL_NTS);
   if (rc != SQL_SUCCESS ) {
      check_error (pCon, NULL);
      nox_sqlDisconnect (&pCon);
      return NULL; // we have an error
   }


   // If required, open the trace table
   nox_traceOpen (pCon);

   pLastConnnection = pCon;
   return pCon; // we are ok
}

#pragma convert(0)

