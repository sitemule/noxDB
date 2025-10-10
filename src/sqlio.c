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
#include "noxDbUtf8.h"
#include "memUtil.h"
#include "timestamp.h"
#include "sndpgmmsg.h"

// Until 7.5
#ifndef SQL_BOOLEAN
#define SQL_BOOLEAN            16
#endif

// Globals: TODO !!! remove to make code reintrant
__thread extern UCHAR jxMessage[512];
__thread extern BOOL  jxError;
PNOXSQLCONNECT pLastConnnection = NULL;

extern iconv_t xlate_1200_to_1208;

// !!!!! NOTE every constant in this module is in ASCII
#pragma convert(1252)

/* ------------------------------------------------------------- */
SQLINTEGER nox_sqlCode(PNOXSQLCONNECT pCon)
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
      nox_SetValueByName(pError ,  "messages", message, PARSE_STRING );
      putenv("MESSAGES_LIST=");
   }
}
/* ------------------------------------------------------------- */
PNOXNODE static sqlErrorObject(PUCHAR sqlstmt)
{
   PNOXNODE pError = nox_NewObject();
   nox_SetBoolByName (pError , "success" ,  OFF);
   nox_SetStrByName  (pError , "msg"     ,  jxMessage);
   nox_SetAsciiByName  (pError , "stmt"    ,  sqlstmt);
   messageList (pError);

   return pError;
}
/* ------------------------------------------------------------- */
static int check_error (PNOXSQLCONNECT pCon, PNOXSQL pSQL)
{
   SQLSMALLINT length;
   ULONG l;
   int rc;

   SQLHANDLE     handle;
   SQLSMALLINT   hType = SQL_HANDLE_ENV;

   SQLHENV       henv  = SQL_NULL_HENV;
   SQLHDBC       hdbc  = SQL_NULL_HDBC;
   SQLHSTMT      hstmt = pSQL && pSQL->pstmt? pSQL->pstmt->hstmt : SQL_NULL_HSTMT;
   UCHAR         sqlState[5];
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
   ae_sprintf( jxMessage , "%-5.5s %-*.*s" , psqlState, length, length, psqlMsgDta);
   nox_sqlClose (&pSQL); // Free the data
   jxError = true;

   return;
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
int nox_sqlExecDirectTrace(PNOXSQLCONNECT pCon, PNOXSQL pSQL , int hstmt, PUCHAR sqlstmt)
{

   int rc, rc2;
   BOOL doClose = FALSE;
   SQLSMALLINT   length   = 0;
   LONG          lrc;
   PUCHAR        psqlState  = "";
   PNOXTRACE     pTrc = &pCon->sqlTrace;

   pCon->sqlCode = 0; // TODO re-entrant !!
   memset ( pCon->sqlState , ' ' , 5);
   ts_nowstr(pTrc->tsStart); // TODO !!! not form global
   rc = SQLExecDirect( hstmt, sqlstmt, SQL_NTS);
   if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
      doClose = TRUE;
      jxError = TRUE;
      rc2= SQLGetDiagRec(SQL_HANDLE_STMT,hstmt,1,pCon->sqlState,&pCon->sqlCode, pTrc->text,sizeof(pTrc->text), &length);
      pTrc->text[length] = '\0';
      stra2e (jxMessage  , pTrc->text );
      joblog (jxMessage);
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
static PNOXSQL nox_sqlNewStatement(PNOXSQLCONNECT pCon, PNOXNODE pSqlParms, BOOL exec, BOOL scroll)
{
   PNOXSQL pSQL;
   PNOXSQLSTMT pStmt;
   SHORT i;
   int rc;
   LONG   attrParm;

   if (pCon == NULL) return NULL;
   pCon->sqlCode = 0;

   pSQL = memAllocClear(sizeof(NOXSQL));
   pSQL->pCon = pCon;
   pSQL->rowcount = -1;
   pSQL->pstmt        = memAlloc(sizeof(NOXSQLSTMT));
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

PNOXSQL nox_sqlOpen(PNOXSQLCONNECT pCon, PUCHAR sqlstmt , PNOXNODE pSqlParmsP, LONG formatP , LONG startP , LONG limitP)
{

   UCHAR sqlTempStmt[32766];
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PNOXNODE pSqlParms =  (pParms->OpDescList->NbrOfParms >= 2 ) ? pSqlParmsP : NULL;
   LONG   format      =  (pParms->OpDescList->NbrOfParms >= 3 ) ? formatP : 0;
   LONG   start       =  (pParms->OpDescList->NbrOfParms >= 4 ) ? startP : NOXDB_FIRST_ROW; // begining
   LONG   limit       =  (pParms->OpDescList->NbrOfParms >= 5 ) ? limitP : NOXDB_ALL_ROWS; // all rows
   LONG   attrParm;
   LONG   i;
   UCHAR  typeName [256];
   LONG   tprc;
   PNOXSQL pSQL;
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

   // build the final sql statement
   strFormat(sqlTempStmt , sqlstmt , pSqlParms);

   //// huxi !! need uncomitted read for blob fields
   // and IBM i does not support statement attribute to set the pr statement. :/
   // so we simply append the "with ur" uncommited read options
   if ((0 != memicmp ( sqlTempStmt , "call"  , 4))
   &&  (0 != memicmp ( sqlTempStmt , "values", 6))) {
      PUCHAR lookFrom = finalSQLPart (sqlTempStmt);
      static BOOL compilereg = true;
      //static regex_t hasLimitReg;
      //static regex_t hasOffsetReg;
      //static regex_t hasFetchReg;
      BOOL hasLimit  ;
      BOOL hasOffset ;
      BOOL hasFetch  ;
      PUCHAR end;

      // Before we begin adding to the statement  - ensure is does not end with a ;
      for (end = sqlTempStmt + strlen(sqlTempStmt) -1  ; end > sqlTempStmt; end--) {
         if (*end == ';') *end = ' ';
         if (*end > ' ') break;
      }

      /* regex does not always work when on other CCSID  platforms
      if (compilereg) {
         int rc;
         UCHAR buf [256];
         ULONG options =  REG_NOSUB + REG_EXTENDED + REG_ICASE;
         # pragma convert(1252)
         rc = regcomp(&hasLimitReg , XlateStringQ (buf , "limit[ ]*[0-9]" , 1252, 0)  , options );
         rc = regcomp(&hasOffsetReg, XlateStringQ (buf , "offset[ ]*[0-9]", 1252, 0)   , options );
         rc = regcomp(&hasFetchReg , XlateStringQ (buf , "fetch[ ]*first" , 1252, 0)     , options );
         # pragma convert(0)
         compilereg = false;
      }

      hasLimit  = 0 == (rc= regexec(&hasLimitReg  , lookFrom , 0, NULL, 0));
      hasOffset = 0 == (rc= regexec(&hasOffsetReg , lookFrom , 0, NULL, 0));
      hasFetch  = 0 == (rc= regexec(&hasFetchReg  , lookFrom , 0, NULL, 0));
      */
      hasLimit  = findHasLimit  (lookFrom);
      hasOffset = findHasOffset (lookFrom);
      hasFetch  = findHasFetch  (lookFrom);

      if (limit > 0 && ! hasFetch && ! hasLimit) {
         a_sprintf (sqlTempStmt + strlen(sqlTempStmt)," limit %ld ", limit);
      }
      // Note !! Offset is "Number if rows to skip" therefor the -1 from the "start"
      if (start > 1 && ! hasOffset) {
         a_sprintf (sqlTempStmt + strlen(sqlTempStmt)," offset %ld ", start - 1);
      }
      if (pCon->transaction == false ) {
         strcat ( sqlTempStmt , " with ur");
      }
   }
   pSQL->sqlstmt = strdup(sqlTempStmt);

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
PNOXSQL nox_sqlOpenVC(PNOXSQLCONNECT pCon, PLVARCHAR sqlstmt , PNOXNODE pSqlParmsP, LONG formatP , LONG startP , LONG limitP)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PNOXNODE pSqlParms  =  (pParms->OpDescList->NbrOfParms >= 3 ) ? pSqlParmsP : NULL;
   LONG format =  (pParms->OpDescList->NbrOfParms >= 4 ) ? formatP : 0;
   LONG start  =  (pParms->OpDescList->NbrOfParms >= 5 ) ? startP : 1;
   LONG limit  =  (pParms->OpDescList->NbrOfParms >= 5 ) ? limitP : -1;

   return nox_sqlOpen (pCon, plvc2str(sqlstmt) , pSqlParms, format , start , limit);

}
/* ------------------------------------------------------------- */
PNOXNODE nox_sqlFormatRow  (PNOXSQL pSQL)
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
            nox_NodeInsertNew (pRow , RL_LAST_CHILD, pCol->colname , NULL,  NOX_LITERAL );
         } else {

            memset ( buf + buflen, 0 , 2); // Zero term - also UNICODE

            switch( pCol->coltype) {
               case SQL_BOOLEAN    :
                  nox_NodeInsertNew (
                     pRow ,
                     RL_LAST_CHILD,
                     pCol->colname ,
                     (*buf == '1' || *buf == 't') ? "true":"false",
                     pCol->nodeType
                  );
                  break;

               case SQL_WCHAR:
               case SQL_WVARCHAR:
               case SQL_GRAPHIC:
               case SQL_VARGRAPHIC: {
                  UCHAR temp [32768];
                  PUCHAR pInBuf = buf;
                  size_t OutLen;
                  size_t inbytesleft;

                  if (pCol->coltype ==  SQL_WVARCHAR) {
                  inbytesleft = (* (PSHORT) pInBuf) * 2; // Peak the length, and unicode uses two bytes
                  pInBuf += 2; // skip len
                  } else {
                     for  (inbytesleft = pCol->collen; inbytesleft > 0 ; inbytesleft -= 2) {
                        if ( * (PSHORT) (pInBuf + inbytesleft - 2) > 0x0020) break;
                     }
                  }
                  OutLen = XlateBuffer  (xlate_1200_to_1208, temp , pInBuf, inbytesleft);
                  temp[OutLen] = '\0';

                  nox_NodeInsertNew (pRow , RL_LAST_CHILD, pCol->colname , temp,  pCol->nodeType );

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

                  nox_NodeInsertNew (pRow , RL_LAST_CHILD, pCol->colname , p,  pCol->nodeType );
                  break ;
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

                  nox_NodeInsertNew (pRow , RL_LAST_CHILD, pCol->colname , p,  pCol->nodeType );
                  break;
               }
            }
         }
      }
      memFree(&buf);

      return pRow; // Found

   } else {
      pSQL->pCon->sqlCode = getSqlCode(pSQL->pstmt->hstmt);
      if (pSQL->rc != SQL_NO_DATA_FOUND ) {
         check_error (pSQL->pCon, pSQL);
      }
   }
   memFree(&buf);
   return NULL; // not found
}
/* ------------------------------------------------------------- */
PNOXNODE nox_sqlFetchRelative (PNOXSQL pSQL, LONG fromRow)
{
   int rc;
   if (pSQL == NULL) return (NULL);

   pSQL->rc = SQLFetchScroll (pSQL->pstmt->hstmt, SQL_FETCH_RELATIVE , (fromRow < 1) ? 1: fromRow);
   return nox_sqlFormatRow(pSQL);
}
/* ------------------------------------------------------------- */
PNOXNODE nox_sqlFetchNext (PNOXSQL pSQL)
{
   int rc;
   if (pSQL == NULL) return (NULL);

   // List next row from the result set
   pSQL->rc = SQLFetch (pSQL->pstmt->hstmt);
   return nox_sqlFormatRow(pSQL);
}
/* ------------------------------------------------------------- */
/****** not used

PNOXNODE nox_sqlFetchFirst (PNOXSQL pSQL, LONG fromRow)
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
void nox_sqlClose (PNOXSQL * ppSQL)
{
   int i;
   int rc;
   PNOXSQL pSQL = * ppSQL;


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
void nox_sqlDisconnect (PNOXSQLCONNECT * ppCon)
{

   PNOXSQLCONNECT pCon;
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
   memFree (ppCon);

}
/* ------------------------------------------------------------- */
PNOXNODE nox_buildMetaFields ( PNOXSQL pSQL )
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
      nox_NodeInsertNew (pField  , RL_LAST_CHILD, "name" , pCol->colname,  VALUE );

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

         case SQL_DECIMAL:
         case SQL_INTEGER:
         case SQL_SMALLINT:
         case SQL_FLOAT:
         case SQL_REAL   :
         case SQL_DOUBLE :
         case SQL_BIGINT: {
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
      nox_NodeInsertNew (pField  , RL_LAST_CHILD, "datatype" , type,  VALUE );

      a_sprintf(temp , "%d" ,  pCol->coltype);
      nox_NodeInsertNew (pField  , RL_LAST_CHILD, "sqltype" , temp ,  LITERAL);

      // Add size
      a_sprintf(temp , "%d" , pCol->displaysize);
      nox_NodeInsertNew (pField  , RL_LAST_CHILD, "size"     , temp,  LITERAL  );

      // Add decimal precission
      if  (0==strcmp ( type , "dec" )) {
         a_sprintf(temp , "%d" , pCol->scale);
         nox_NodeInsertNew (pField  , RL_LAST_CHILD, "prec"     , temp,  LITERAL  );
      }

      nox_NodeInsertNew (pField  , RL_LAST_CHILD, "header" , pCol->header, VALUE  );

      // Push to array
      nox_ArrayPush (pFields , pField, FALSE);
   }

   // nox_Debug ("Fields:", pFields);
   return  pFields;

}
/* ------------------------------------------------------------- */
LONG nox_sqlNumberOfRows(PNOXSQLCONNECT pCon ,PUCHAR sqlstmt)
{

   LONG    rowCount, para = 0;
   PNOXNODE pRow;
   PUCHAR p, w, lastSelect, orderby, from, withur;
   UCHAR  str2 [32766];

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

   // remove order by - if any
   orderby = a_stristr(from  , " order ");
   if (orderby) {
      *orderby = '\0';
   }

   // remove "with ur" - if any
   withur = a_stristr(from  , " with ur");
   if (withur) {
      *withur = '\0';
   }

   // rebuild the select statement as a "select count(*) from ..."
   substr (str2 , sqlstmt , lastSelect - sqlstmt); // if a "With" exists then grab that
   strcat (str2 ,"select count(*) as counter" );
   strcat (str2 , from );

   // Get that only row
   pRow = nox_sqlResultRow(pCon, str2, NULL,1,0);

   rowCount = a2i(nox_GetValuePtr(pRow, "counter", NULL));

   nox_NodeDelete (pRow);

   return rowCount;
}
LONG nox_sqlNumberOfRowsVC(PNOXSQLCONNECT pCon ,PLVARCHAR sqlstmt)
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
void nox_sqlUpperCaseNames(PNOXSQL pSQL)
{
   int i;
   for (i = 0; i < pSQL->nresultcols; i++) {
      PNOXCOL pCol = &pSQL->cols[i];
      a_str2upper (pCol->colname , pCol->colname);
   }
}
*/
/* ------------------------------------------------------------- */
LONG nox_sqlColumns (PNOXSQL pSQL)
{
   if (pSQL == NULL) return -1;
   return (pSQL->nresultcols);
}
/* ------------------------------------------------------------- */
LONG nox_sqlRows (PNOXSQL pSQL)
{
   if (pSQL == NULL) return -1;
   if (pSQL->rowcount == -1) {
      pSQL->rowcount = nox_sqlNumberOfRows(pSQL->pCon , pSQL->sqlstmt);
   }

   return (pSQL->rowcount);
}
/* ------------------------------------------------------------- */
PNOXNODE nox_sqlResultSet( PNOXSQLCONNECT pCon ,PUCHAR sqlstmt, PNOXNODE pSqlParms, LONG format, LONG start, LONG limit)
{

   PNOXNODE pRow;
   PNOXNODE pRows;
   PNOXNODE pResult;
   PNOXSQL  pSQL;
   LONG     i, rc;
   LONG     rowCount=0;
   SHORT    strLen=0;

   start = start < 1 ? 1 : start;

   pSQL = nox_sqlOpen(pCon, sqlstmt , pSqlParms, format, start , limit);
   if ( pSQL == NULL) {
      if (format & NOX_GRACEFUL_ERROR) {
         return sqlErrorObject(sqlstmt);
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

   if ( (pSQL->rc != SQL_NO_DATA_FOUND) && (format & NOX_GRACEFUL_ERROR) ) {
      nox_NodeDelete (pRows);
      nox_sqlClose (&pSQL);
      return sqlErrorObject(sqlstmt);
   }


   // need a object as return value
   if (format & (NOX_META | NOX_FIELDS | NOX_TOTALROWS | NOX_APROXIMATE_TOTALROWS)) {
      PNOXNODE pMeta;
      pResult  = nox_NewObject();
      pMeta    = nox_NewObject();
      nox_SetValueByName(pResult  , "success" , "true" , LITERAL);
      nox_SetValueByName(pResult , "root"    , "rows" , VALUE);
      if (format & NOX_FIELDS ) {
         PNOXNODE pFields = nox_buildMetaFields (pSQL);
         nox_NodeMoveInto(pMeta , "fields" , pFields);
      }
      if (format & (NOX_TOTALROWS | NOX_APROXIMATE_TOTALROWS)) {
         nox_SetValueByName(pMeta , "totalProperty"   , "totalRows" , VALUE);

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

         nox_SetIntByName(pResult , "totalRows" , pSQL->rowcount );
      }

      nox_NodeMoveInto (pResult , "metaData" , pMeta);
      nox_NodeMoveInto (pResult , "rows"     , pRows);

   } else {

      // simply return the array of rows
      pResult = pRows;
   }

   nox_sqlClose (&pSQL);
   return pResult;

}
// RPG wrapper:
PNOXNODE nox_sqlResultSetVC( PNOXSQLCONNECT pCon, PLVARCHAR sqlstmt, PNOXNODE pSqlParmsP, LONG formatP, LONG startP, LONG limitP )
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PNOXNODE pSqlParms= (pParms->OpDescList->NbrOfParms >= 3) ? pSqlParmsP : NULL;
   LONG    format    = (pParms->OpDescList->NbrOfParms >= 4) ? formatP    : 0;  // Arrray only
   LONG    start     = (pParms->OpDescList->NbrOfParms >= 5) ? startP     : NOXDB_FIRST_ROW;  // From first row
   LONG    limit     = (pParms->OpDescList->NbrOfParms >= 6) ? limitP     : NOXDB_ALL_ROWS; // All row
   return nox_sqlResultSet( pCon, plvc2str(sqlstmt) , pSqlParms, format , start, limit);
}
/* ------------------------------------------------------------- */
PNOXNODE nox_sqlResultRow ( PNOXSQLCONNECT pCon, PUCHAR sqlstmt, PNOXNODE pSqlParms , LONG format , LONG start )
{
   PNOXNODE pRow;
   PNOXSQL  pSQL;

   pSQL = nox_sqlOpen(pCon , sqlstmt , pSqlParms, format , start , 1 );
   if ( pSQL == NULL) {
       if (format & NOX_GRACEFUL_ERROR) {
           return sqlErrorObject(sqlstmt);
         } else {
           return NULL;
         }
      }

   pRow  = nox_sqlFetchNext (pSQL);
   nox_sqlClose (&pSQL);
   return pRow;

}
// RPG wrapper
PNOXNODE nox_sqlResultRowVC ( PNOXSQLCONNECT pCon, PLVARCHAR sqlstmt, PNOXNODE pSqlParmsP, LONG startP ,  LONG formatP )
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PNOXNODE pSqlParms = (pParms->OpDescList->NbrOfParms >= 3) ? pSqlParmsP : NULL;
   LONG     start     = (pParms->OpDescList->NbrOfParms >= 4) ? startP     : 1;  // From first row
   LONG     format    = (pParms->OpDescList->NbrOfParms >= 5) ? formatP    : 0;  // Arrray only
   return nox_sqlResultRow ( pCon, plvc2str(sqlstmt), pSqlParms, start,format);
}
/* ------------------------------------------------------------- */
PNOXNODE nox_sqlValuesVC ( PNOXSQLCONNECT pCon, PLVARCHAR sqlstmt, PNOXNODE pSqlParmsP , LONG formatP)
{

   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PNOXNODE pSqlParms = (pParms->OpDescList->NbrOfParms >= 3) ? pSqlParmsP : NULL;
   LONG    format     = (pParms->OpDescList->NbrOfParms >= 4) ? formatP    : 0;
   PNOXNODE pResult;
   PNOXNODE pChild ;
   UCHAR   stmtBuf [32760];

   strcpy (stmtBuf , "values (");
   strcat (stmtBuf , plvc2str(sqlstmt));
   strcat (stmtBuf , ")");

   pResult =  nox_sqlResultRow ( pCon , stmtBuf, pSqlParms ,1, format);

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
PNOXNODE nox_sqlGetMeta (PNOXSQLCONNECT pCon, PUCHAR sqlstmt)
{
   int i;
   PNOXSQL  pSQL  = nox_sqlOpen(pCon, sqlstmt , NULL, 0 , 1 , 0);
   PNOXNODE pMeta = nox_buildMetaFields ( pSQL );
   nox_sqlClose (&pSQL);
   return pMeta;
}
PNOXNODE nox_sqlGetMetaVC (PNOXSQLCONNECT pCon, PLVARCHAR sqlstmt)
{
   return nox_sqlGetMeta (pCon, plvc2str(sqlstmt));
}
/* ------------------------------------------------------------- */
LGL nox_sqlExec(PNOXSQLCONNECT pCon,PUCHAR sqlstmt , PNOXNODE pSqlParms)
{

   LONG   attrParm;
   LONG   i;
   int rc;
   //   PNOXSQL pSQL = nox_sqlNewStatement (pParms->OpDescList->NbrOfParms >= 2 ? pSqlParms  :NULL);
   PNOXSQL pSQL = nox_sqlNewStatement (pCon, NULL, true, false);

   // run  the  statement in "sqlstr"
   if (pSqlParms) {
      UCHAR sqlTempStmt[32766];
      strFormat(sqlTempStmt , sqlstmt , pSqlParms);
      rc = nox_sqlExecDirectTrace(pCon, pSQL , pSQL->pstmt->hstmt, sqlTempStmt);
   } else {
      rc = nox_sqlExecDirectTrace(pCon, pSQL , pSQL->pstmt->hstmt, sqlstmt);
   }
   nox_sqlClose (&pSQL);
   return rc == SQL_SUCCESS ? OFF: ON;
}
// RPG wrapper
LGL nox_sqlExecVC(PNOXSQLCONNECT pCon,PLVARCHAR sqlstmt , PNOXNODE pSqlParmsP)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PNOXNODE pSqlParms = (pParms->OpDescList->NbrOfParms >= 3) ? pSqlParmsP : NULL;
   return nox_sqlExec(pCon, plvc2str(sqlstmt) , pSqlParms);
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
   if (pNode->type == ARRAY ||  pNode->type == OBJECT) {
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
   if (pNode->type == ARRAY ||  pNode->type == OBJECT) {
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
static void buildUpdate (SQLHSTMT hstmt, SQLHSTMT hMetastmt,
   PUCHAR sqlStmt, PUCHAR table, PNOXNODE pSqlParms , PUCHAR where)
{
   PUCHAR  stmt = sqlStmt;
   PUCHAR  comma = "";
   PNOXNODE pNode;
   PUCHAR  name;
   int     colno;
   UCHAR   temp [128];

   stmt += strjoin (stmt , "update " , table , " set " );

   pNode    =  nox_GetNodeChild (pSqlParms);
   for ( colno=1; pNode; colno++) {
      if (! isIdColumn(hMetastmt, colno)) {
         name  = nox_GetNodeNamePtr   (pNode);
         a_str2upper (temp  , name);   // Needed for national charse in columns names i.e.: BELØB
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
   UCHAR   markers[4096] ;
   UCHAR   temp [128];
   PUCHAR  pMarker = markers;

   stmt += strjoin  (stmt , "insert into " , table , " (" );

   pNode = nox_GetNodeChild (pSqlParms);
   for ( colno=1; pNode; colno++) {
      if (! isIdColumn(hMetaStmt, colno)) {
         if (!nodeisnull(pNode)) {
            name     = nox_GetNodeNamePtr   (pNode);
            a_str2upper (temp  , name);   // Needed for national charse in columns names i.e.: BELØB
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
}
/* ------------------------------------------------------------- */
void createTracetable(PNOXSQLCONNECT pCon)
{
   PNOXTRACE pTrc = &pCon->sqlTrace;
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
void nox_traceOpen (PNOXSQLCONNECT pCon)
{
   PNOXTRACE pTrc = &pCon->sqlTrace;
   int rc;
   PUCHAR insertStmt = "insert into sqltrace (STSTART,STEND,STSQLSTATE,STTEXT,STJOB,STTRID,STSQLSTMT) "
                  "values (?,?,?,?,?,?,?)";

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
void nox_TraceSetId (PNOXSQLCONNECT pCon, INT64 trid)
{
   PNOXTRACE pTrc = &pCon->sqlTrace;
   pTrc->trid = trid;
}
/* ------------------------------------------------------------- */
void nox_traceInsert (PNOXSQL pSQL, PUCHAR stmt , PUCHAR sqlState)
{
   if (pSQL == NULL || pSQL->pCon == NULL ) return;
   PNOXTRACE pTrc = &pSQL->pCon->sqlTrace; // !!! TODO not from global !!!
   if (pTrc->doTrace == OFF) return;
   int rc;
   rc = SQLBindParameter(pTrc->handle,3,SQL_PARAM_INPUT,SQL_C_CHAR,SQL_CHAR    ,   5,0,sqlState,0,NULL);
   rc = SQLBindParameter(pTrc->handle,7,SQL_PARAM_INPUT,SQL_C_CHAR,SQL_VARCHAR ,8192,0,stmt,0,NULL);

   // insert row
   rc = SQLExecute(pTrc->handle);

}
/* ------------------------------------------------------------- */
SHORT  doInsertOrUpdate(
   PNOXSQL pSQL,
   PNOXSQL pSQLmeta,
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
   PUCHAR valArr[64];
   SHORT  valArrIx= 0;
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
            return rc; // we have an error
         }


         if (pNode->type == ARRAY ||  pNode->type == OBJECT) {
            value = valArr[valArrIx++] = memAlloc(Col.collen);
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
               return rc; // we have an error
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
            return rc; // we have an error
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

   for(i=0;i<valArrIx; i++) {
      memFree(&valArr[i]);
   }

   if (rc != SQL_SUCCESS && rc != SQL_NO_DATA_FOUND) {
      check_error (pSQL->pCon, pSQL);
      return rc; // we have an error
   }

   return rc;

}

/* ------------------------------------------------------------- */
static PNOXSQL buildMetaStmt (PNOXSQLCONNECT pCon, PUCHAR table, PNOXNODE pRow)
{
   UCHAR     sqlTempStmt[32766];
   PUCHAR    stmt = sqlTempStmt;
   PUCHAR    name;
   UCHAR     temp  [256];
   PNOXNODE   pNode;
   PUCHAR    comma = "";
   SQLRETURN rc;
   PNOXSQL    pSQLmeta = nox_sqlNewStatement (pCon, NULL, false, false);

   stmt += cpy (stmt , "select ");

   comma = "";
   pNode    =  nox_GetNodeChild (pRow);
   while (pNode) {
      name  = nox_GetNodeNamePtr   (pNode);
      a_str2upper (temp  , name);   // Needed for national charse in columns names i.e.: BELØB
      stmt += strjoin (stmt , comma ,temp);
      comma = ",";
      pNode = nox_GetNodeNext(pNode);
   }

   stmt += strjoin  (stmt , " from " , table , " where 1=0 with ur");

   // prepare the statement that provides the columns
   rc = SQLPrepare(pSQLmeta->pstmt->hstmt , sqlTempStmt, SQL_NTS);
   if (rc != SQL_SUCCESS ) {
      check_error (pCon, pSQLmeta);
      nox_sqlClose (&pSQLmeta); // Free the data
      return NULL;
   }
   return  pSQLmeta;
}
/* ------------------------------------------------------------- */
LGL nox_sqlUpdateOrInsert (PNOXSQLCONNECT pCon, BOOL update, PUCHAR table  , PNOXNODE pRowP , PUCHAR whereP, PNOXNODE pSqlParms)
{
   LONG   attrParm;
   LONG   i;
   PUCHAR valArr[64];
   SHORT  valArrIx= 0;

   UCHAR sqlTempStmt[32766];
   UCHAR where [4096];
   UCHAR temp  [256];
   PUCHAR stmt = sqlTempStmt;
   PNOXNODE pNode;
   PUCHAR comma = "";
   PUCHAR name, value;

   SQLSMALLINT   length;
   SQLRETURN     rc;
   PNOXSQL       pSQL     = nox_sqlNewStatement (pCon, NULL, true, false);
   PNOXSQL       pSQLmeta;
   SQLCHUNK      sqlChunk[32];
   SHORT         sqlChunkIx =0;
   PUCHAR        sqlNullPtr = NULL;
   PNOXNODE      pRow = nox_ParseString((PUCHAR) pRowP);
   LGL err = ON; // assume error


   // First get the columen types - by now we use a select to mimic that
   pSQLmeta = buildMetaStmt ( pCon, table, pRow);
   if (pSQLmeta == NULL) {
      goto cleanup;
   }

   strFormat(where , whereP , pSqlParms);
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
   if (pRowP != pRow) nox_NodeDelete (pRow);
   nox_sqlClose (&pSQLmeta); // Free the data
   nox_sqlClose (&pSQL);
   return err;
}
/* ------------------------------------------------------------- */
LGL nox_sqlUpdate (PNOXSQLCONNECT pCon, PUCHAR table  , PNOXNODE pRow , PUCHAR where, PNOXNODE pSqlParms  )
{
   UCHAR  whereStr [1024];
   for(; *where == ' ' ; where++); // skip leading blanks
   if (*where > ' ' && ! a_memiBeginsWith(where, "where")) {
      strjoin (whereStr , "where ", where);
      where = whereStr;
   }
   return nox_sqlUpdateOrInsert  (pCon, true , table  , pRow , where, pSqlParms);
}
/* ------------------------------------------------------------- */
LGL nox_sqlUpdateVC (PNOXSQLCONNECT pCon, PLVARCHAR table  , PNOXNODE pRow , PLVARCHAR whereP, PNOXNODE pSqlParmsP  )
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PUCHAR  where     = (pParms->OpDescList->NbrOfParms >= 4) ? plvc2str(whereP) : "";
   PNOXNODE pSqlParms = (pParms->OpDescList->NbrOfParms >= 5) ? pSqlParmsP : NULL;
   return nox_sqlUpdate (pCon, plvc2str (table)   , pRow , where, pSqlParms);
}
/* ------------------------------------------------------------- */
LGL nox_sqlInsert (PNOXSQLCONNECT pCon, PUCHAR table  , PNOXNODE pRow , PUCHAR where, PNOXNODE pSqlParms  )
{
   return nox_sqlUpdateOrInsert  (pCon, false , table  , pRow , where , pSqlParms);
}
LGL nox_sqlInsertVC (PNOXSQLCONNECT pCon,PLVARCHAR table  , PNOXNODE pRow , PLVARCHAR whereP, PNOXNODE pSqlParmsP  )
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PUCHAR  where    =  (pParms->OpDescList->NbrOfParms >= 4) ? plvc2str(whereP) : "";
   PNOXNODE pSqlParms = (pParms->OpDescList->NbrOfParms >= 5) ? pSqlParmsP : NULL;
   return nox_sqlUpdateOrInsert  (pCon, false , plvc2str(table)  , pRow , where , pSqlParms);
}
/* ------------------------------------------------------------- */
LGL nox_sqlUpsert (PNOXSQLCONNECT pCon, PUCHAR table  , PNOXNODE pRow , PUCHAR where, PNOXNODE pSqlParms  )
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
LGL nox_sqlUpsertVC (PNOXSQLCONNECT pCon, PLVARCHAR table  , PNOXNODE pRow , PLVARCHAR whereP, PNOXNODE pSqlParmsP  )
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PUCHAR  where     = (pParms->OpDescList->NbrOfParms >= 4) ? plvc2str(whereP) : "";
   PNOXNODE pSqlParms = (pParms->OpDescList->NbrOfParms >= 5) ? pSqlParmsP : NULL;
   return nox_sqlUpsert (pCon, plvc2str(table)  , pRow , where, pSqlParms);

}
/* -------------------------------------------------------------------
 * Provide options to a pSQL environment - If NULL then use the default
 * ------------------------------------------------------------------- */
LONG nox_sqlGetInsertId (PNOXSQLCONNECT pCon)
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
void nox_sqlSetOptions (PNOXSQLCONNECT pCon, PNOXNODE pOptionsP)
{

   PSQLOPTIONS po = &pCon->options;
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
PNOXSQLCONNECT nox_sqlConnect(PNOXNODE pOptionsP)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PNOXNODE  pOptions = pParms->OpDescList->NbrOfParms >= 1 ? pOptionsP : NULL;
   PNOXSQLCONNECT pCon;
   LONG          attrParm;
   PUCHAR        server = "*LOCAL";
   int rc;
   PSQLOPTIONS po;

   pCon = memAllocClear(sizeof(NOXSQLCONNECT));
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



PNOXSQLCONNECT nox_sqlConnect(PNOXNODE pOptionsP)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PNOXNODE  pOptions = pParms->OpDescList->NbrOfParms >= 1 ? pOptionsP : NULL;
   PNOXSQLCONNECT pCon;
   LONG          attrParm;
   PUCHAR        server = "*LOCAL";
   int rc;
   PSQLOPTIONS po;

   pCon = memAllocClear(sizeof(NOXSQLCONNECT));
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

