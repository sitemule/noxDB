/* SYSIFCOPT(*IFSIO) TERASPACE(*YES *TSIFC) STGMDL(*SNGLVL)      */
/* SYSIFCOPT(*IFSIO) TERASPACE(*YES *TSIFC) STGMDL(*SNGLVL)      */
/* COMPILEOPT('OUTPUT(*PRINT) OPTION(*EXPMAC *SHOWINC)')         */
/* Program . . . : JXM002                                        */
/* Design  . . . : Niels Liisberg                                */
/* Function  . . : SQL database I/O                              */
/*                                                               */
/*  SQLCLI documentation:


https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_73/cli/rzadphdapi.htm?lang=da
                                                                */
/* By     Date       PTF     Description                         */
/* NL     21.10.2006         New program                         */
/* NL     16.10.2014         Added to JSONXML library            */
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
#include <regex.h>


#include "ostypes.h"
#include "xlate.h"
#include "varchar.h"
#include "MinMax.h"
#include "parms.h"
#include "utl100.h"
#include "jsonxml.h"
#include "mem001.h"
#include "timestamp.h"

#define NOXDB_UNKNOWN_SQL_DATATYPE -99
#define NOXDB_MAX_PARMS  4096
#define NOXDB_FIRST_ROW -1
#define NOXDB_ALL_ROWS  -1

// Until 7.5
#ifndef SQL_BOOLEAN
#define SQL_BOOLEAN            16
#endif


// Globlas: TODO !!! remove to make code reintrant
extern UCHAR jxMessage[512];
extern BOOL  jxError;
extern UCHAR BraBeg;
extern UCHAR CurBeg;
extern UCHAR Dollar;

extern UCHAR jobSlash       ;
extern UCHAR jobBackSlash   ;
extern UCHAR jobMasterspace ;
extern UCHAR jobBraBeg      ;
extern UCHAR jobBraEnd      ;
extern UCHAR jobCurBeg      ;
extern UCHAR jobCurEnd      ;
extern UCHAR jobDollar      ;


// Unit Globals:
static JXSQLCONNECT connection;
static PJXSQLCONNECT pConnection = NULL;
static BOOL keepConnection = false;
static SQLINTEGER sqlCode = 0;
static SQLCHAR    sqlMessage [SQL_MAX_MESSAGE_LENGTH + 1];
static SQLCHAR    sqlState   [SQL_SQLSTATE_SIZE + 1];
static UCHAR      rootName[32] = "rows";


static enum  {
   UNCONNECTED,
   AUTOCONNECTED,
   HOSTED
} connectionMode;

typedef _Packed struct _SQLCHUNK {
   SQLINTEGER actLen;
   SQLINTEGER chunkLen;
   SQLINTEGER offset;
   PUCHAR value;
} SQLCHUNK, *PSQLCHUNK;

typedef struct {
   SQLINTEGER  inLen ;
   SQLINTEGER  bufLen;
   PUCHAR      buffer   ;
   PUCHAR      name  ;
   SHORT       type  ;
   SQLSMALLINT mode     ;
   SQLSMALLINT sqlType  ;
   PJXNODE     pNode        ;
   PUCHAR      pData       ;
   BOOL        isBool;
} PROCPARM ,* PPROCPARM;

void          jx_sqlDisconnect (void);
PJXSQLCONNECT jx_sqlNewConnection(void);
void jx_traceOpen (PJXSQLCONNECT pCon);
void jx_traceInsert (PJXSQL pSQL, PUCHAR stmt , PUCHAR sqlState);
PJXNODE static sqlErrorObject(PUCHAR sqlstmt);

/* ------------------------------------------------------------- */
void jx_sqlSetRootName (PUCHAR name )
{
   strcpy ( rootName , name);
}

/* ------------------------------------------------------------- */
SQLINTEGER jx_sqlCode(void)
{
  return sqlCode;
}
/* ------------------------------------------------------------- */
static SQLINTEGER getSqlCode(SQLHSTMT hStmt)
{
   SQLSMALLINT    length = 0;

   SQLError(SQL_NULL_HENV, SQL_NULL_HDBC, hStmt,
      sqlState,
      &sqlCode,
      sqlMessage,
      SQL_MAX_MESSAGE_LENGTH + 1,
      &length
   );
   sqlMessage[length] = '\0';
   return sqlCode;
}
/* ------------------------------------------------------------- */
static int check_error (PJXSQL pSQL)
{
   SQLSMALLINT length;
   ULONG l;
   int rc;

   SQLHANDLE     handle;
   SQLSMALLINT   hType = SQL_HANDLE_ENV;
   SQLSMALLINT   msgRecNo = 1;
   SQLHENV       henv  = SQL_NULL_HENV;
   SQLHDBC       hdbc  = SQL_NULL_HDBC;
   SQLHSTMT      hstmt = pSQL && pSQL->pstmt? pSQL->pstmt->hstmt : SQL_NULL_HSTMT;
   LONG          tmpSqlCode;
   UCHAR         tmpSqlState[5];
   UCHAR         tmpSqlMsgDta[SQL_MAX_MESSAGE_LENGTH + 1];
   PLONG         psqlCode   = &tmpSqlCode;
   PUCHAR        psqlState  = tmpSqlState;
   PUCHAR        psqlMsgDta = tmpSqlMsgDta;

   if (pSQL && pSQL->pstmt) {
      hType  =  SQL_HANDLE_STMT;
      handle =  pSQL->pstmt->hstmt;

      /* --------
      // int i;
      // int SQL_DIAG_COLUMN_NAME = 21; is not supported in Db2 for i

      UCHAR text [512];
      SQLSMALLINT textSize = sizeof(text);

      for (i=0;i < 5; i++) {
         SQLGetDiagField(hType, handle , i , SQL_DIAG_COLUMN_NAME,text,sizeof(text), &textSize);
      }
      --------- */

   } else if ( pConnection) {
      if (pConnection->hdbc) {
         hType  =  SQL_HANDLE_DBC;
         handle =  pConnection->hdbc;
      } else {
         hType  =  SQL_HANDLE_ENV;
         handle =  pConnection->henv;
      }
      psqlState  = pConnection->sqlState;
      psqlCode   = &pConnection->sqlCode;
      psqlMsgDta = pConnection->sqlMsgDta;
   }

   length = 0;
   rc = SQLGetDiagRec(hType , handle, msgRecNo, psqlState, psqlCode, psqlMsgDta,  sizeof(tmpSqlMsgDta), &length);
   // No diagnostics - it already was pulled by "getSqlCode"
   if  (rc == 100) {
      sprintf( jxMessage , "%-5.5s %s" , sqlState, sqlMessage);
   } else {
      sprintf( jxMessage , "%-5.5s %-*.*s" , psqlState, length, length, psqlMsgDta);
   }
   jx_sqlClose (&pSQL); // Free the data
   jxError = true;

   return;
}
/* ------------------------------------------------------------- */
static PJXSQLCONNECT jx_sqlNewConnection(void )
{
   // static SQLHSTMT      hstmt = 0 ;
   // SQLINTEGEREGER    len;
   // UCHAR Label [256];
   // LGL  err = ON;
   // LONG rows =0;

   // PJXSQLCONNECT pConnection;  I hate this - but need to go global for now !!
   LONG          attrParm;
   PUCHAR        server = "*LOCAL";
   int rc;
   PSQLOPTIONS po;

   pConnection = &connection;
   memset(pConnection , 0 , sizeof(JXSQLCONNECT));
   pConnection->sqlTrace.handle = -1;
   pConnection->pCd = XlateOpenDescriptor (13488, 0, false);
   po = &pConnection->options;
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
   rc = SQLAllocEnv (&pConnection->henv);
   if (rc != SQL_SUCCESS ) {
     check_error (NULL);
     jx_sqlDisconnect ();
     return NULL; // we have an error
   }

   // Note - this is invers: Default to IBMi naming
   attrParm = pConnection->options.sqlNaming == ON ? SQL_FALSE : SQL_TRUE;
   rc = SQLSetEnvAttr  (pConnection->henv, SQL_ATTR_SYS_NAMING, &attrParm  , 0);
   /* Dont test since the activations groupe might be reclaimed, and a new "session" is on..
   if (rc != SQL_SUCCESS ) {
     check_error (NULL);
     jx_sqlDisconnect ();
     return NULL; // we have an error
   }
   ... */

   /* TODO !!! always use UTF-8
   attrParm = SQL_TRUE;
   rc = SQLSetEnvAttr  (pConnection->henv, SQL_ATTR_UTF8 , &attrParm  , 0);
   if (rc != SQL_SUCCESS ) {
     jx_sqlDisconnect ();
     return NULL; // we have an error
   }
   */

   /* done on each statement */
   /*
   attrParm = SQL_TRUE;
   rc = SQLSetEnvAttr  (pConnection->henv, SQL_ATTR_EXTENDED_COL_INFO , &attrParm  , 0);
   */

   attrParm = SQL_TRUE;
   rc = SQLSetEnvAttr  (pConnection->henv, SQL_ATTR_JOB_SORT_SEQUENCE , &attrParm  , 0);
   if (rc != SQL_SUCCESS ) {
     jx_sqlDisconnect ();
     return NULL; // we have an error
   }

   rc = SQLAllocConnect (pConnection->henv, &pConnection->hdbc);  // allocate a connection handle
   if (rc != SQL_SUCCESS ) {
     check_error (NULL);
     jx_sqlDisconnect ();
     return NULL; // we have an error
   }

   attrParm = SQL_TXN_NO_COMMIT; // does not work with BLOBS
   // attrParm = SQL_TXN_READ_UNCOMMITTED; // does not work for updates !!! can noet bes pr- statemnet
   rc = SQLSetConnectAttr (pConnection->hdbc, SQL_ATTR_COMMIT , &attrParm  , 0);
   if (rc != SQL_SUCCESS ) {
     check_error (NULL);
     jx_sqlDisconnect ();
     return NULL; // we have an error
   }

   rc = SQLConnect (pConnection->hdbc, server , SQL_NTS, NULL, SQL_NTS, NULL, SQL_NTS);
   if (rc != SQL_SUCCESS ) {
     check_error (NULL);
     jx_sqlDisconnect ();
     return NULL; // we have an error
   }

   // If required, open the trace table
   jx_traceOpen (pConnection);

   return pConnection; // we are ok

}
/* ------------------------------------------------------------- */
static PJXSQLCONNECT jx_getCurrentConnection(void)
{

   if (pConnection == NULL) {
      pConnection = jx_sqlNewConnection ();
   }
   return pConnection;
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
static int insertMarkerValue (PUCHAR buf , PUCHAR marker, PJXNODE parms)
{
   int len =0;
   PJXNODE pNode;
   PUCHAR value;

   pNode = jx_GetNode   ( parms , marker);
   if (pNode) {
      value = jx_GetValuePtr  ( pNode , "" , NULL );
      if (pNode->isLiteral) {
         strcpy(buf, value);
         len = strlen(buf);
      } else {
         len = sqlEscape (buf , value);
      }
   }
   return len;
}
/* ------------------------------------------------------------- */
LGL jx_sqlStartTransaction (void)
{
   PJXSQLCONNECT pc;
   int rc;
   LONG   attrParm;


   // build or get the connection
   pc = jx_getCurrentConnection();
   if (pc == NULL) return ON;

   pConnection->transaction = true;

   attrParm = SQL_FALSE;
   rc = SQLSetConnectAttr(pConnection->hdbc, SQL_ATTR_AUTOCOMMIT, &attrParm, 0) ;

   attrParm = SQL_TXN_REPEATABLE_READ;
   // attrParm = SQL_TXN_READ_UNCOMMITTED; // does not work for updates !!! can noet bes pr- statemnet
   rc = SQLSetConnectAttr (pConnection->hdbc, SQL_ATTR_COMMIT , &attrParm  , 0);

   return (rc==0) ? OFF:ON;
}
/* ------------------------------------------------------------- */
static LGL jx_sqlCommitOrRollback(int type)
{

   PJXSQLCONNECT pc;
   int rc1;
   int rc2;
   int rc3;
   LONG   attrParm;

   // build or get the connection
   pc = jx_getCurrentConnection();
   if (pc == NULL) return ON;

   pConnection->transaction = false;

   rc1 = SQLTransact (
      SQL_HANDLE_DBC,
      pConnection->hdbc,
      type
   );

   if (rc1!=0) {
      //check_error (NULL);
   }

   attrParm = SQL_TXN_NO_COMMIT; // does not work with BLOBS
   rc2 = SQLSetConnectAttr (pConnection->hdbc, SQL_ATTR_COMMIT , &attrParm  , 0);

   attrParm = SQL_TRUE;
   rc3 = SQLSetConnectAttr(pConnection->hdbc, SQL_ATTR_AUTOCOMMIT, &attrParm, 0) ;

   return (rc1==0) ? OFF:ON;

   return OFF;
}
/* ------------------------------------------------------------- */
LGL jx_sqlCommit()
{
   return jx_sqlCommitOrRollback(SQL_COMMIT_HOLD);
}
/* ------------------------------------------------------------- */
LGL jx_sqlRollback()
{
   return jx_sqlCommitOrRollback(SQL_ROLLBACK_HOLD);
}
/* ------------------------------------------------------------- */
int jx_sqlExecDirectTrace(PJXSQL pSQL , int hstmt, PUCHAR sqlstmt)
{

   int rc, rc2;
   SQLSMALLINT   length   = 0;
   LONG          lrc;
   PUCHAR        psqlState  = "";
   PJXTRACE      pTrc = &pConnection->sqlTrace;

   sqlCode = 0; // TODO re-entrant !!
   memset ( pConnection->sqlState , ' ' , 5);
   ts_nowstr(pTrc->tsStart); // TODO !!! not form global
   rc = SQLExecDirect( hstmt, sqlstmt, SQL_NTS);
   if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
     rc2= SQLGetDiagRec(SQL_HANDLE_STMT,hstmt,1,pConnection->sqlState,&sqlCode, pTrc->text,sizeof(pTrc->text), &length);
     sprintf( jxMessage , "%-5.5s %0.*s" , pConnection->sqlState , length, pTrc->text);
     jx_sqlClose (&pSQL); // Free the data
   }
   pTrc->text [length] = '\0';
   ts_nowstr(pTrc->tsEnd); // TODO !!! not form global
   jx_traceInsert ( pSQL , sqlstmt , pConnection->sqlState);
   return rc; // we have an error
}
/* ------------------------------------------------------------- */
PUCHAR strFormat (PUCHAR out, PUCHAR in , PJXNODE parms)
{
  PUCHAR p, pMarker, res = out;
  PJXNODE pParms = parms;
  int markerLen ;
  UCHAR marker [64];

  if (parms == NULL) {
     strcpy(out , in);
     return out;
  }

  if (OFF == jx_isNode (parms)) {
    pParms =  jx_ParseString((PUCHAR) parms, NULL);
  }

  while (*in) {
     if (*in == Dollar) {
       pMarker = ++in;
       for (;isalnum(*in) || *in=='.' || *in=='/' || *in=='_' ; in++);
       markerLen = in - pMarker ;
       if (markerLen > 0) {
          substr(marker , pMarker , markerLen );
          out += insertMarkerValue (out , marker, pParms );
       }
     } else {
       *(out++) = *(in++);
     }
  }
  *(out++) =  '\0';

  if (OFF == jx_isNode (parms)) {
      jx_Close (&pParms);
  }

  return res;
}
/* ------------------------------------------------------------- */
static PJXSQL jx_sqlNewStatement(PJXNODE pSqlParms, BOOL exec, BOOL scroll)
{
   PJXSQL pSQL;
   PJXSQLCONNECT pc;
   PJXSQLSTMT pStmt;
   SHORT i;
   int rc;
   LONG   attrParm;

   sqlCode  = 0;
   pSQL = memAlloc(sizeof(JXSQL));
   memset(pSQL , 0 , sizeof(JXSQL));
   pSQL->rowcount = -1;

   // build or get the connection
   pc = jx_getCurrentConnection();
   if (pc == NULL) return NULL;

   pSQL->pstmt        = memAlloc(sizeof(JXSQLSTMT));
   pSQL->pstmt->hstmt = 0;
   pSQL->pstmt->exec  = exec;

   // allocate  and initialize with defaults
   rc = SQLAllocStmt(pConnection->hdbc, &pSQL->pstmt->hstmt);
   if (rc != SQL_SUCCESS ) {
      check_error (pSQL);
      return NULL; // we have an error
   }

   if (exec) {
      // This need to allow update
      attrParm = SQL_INSENSITIVE;
      rc = SQLSetStmtAttr  (pSQL->pstmt->hstmt, SQL_ATTR_CURSOR_SENSITIVITY , &attrParm  , 0);
      if (rc != SQL_SUCCESS ) {
         check_error (pSQL);
         return NULL; // we have an error
      }

   } else {

      if (scroll) {
         attrParm = SQL_TRUE;
         rc = SQLSetStmtAttr  (pSQL->pstmt->hstmt, SQL_ATTR_CURSOR_SCROLLABLE , &attrParm  , 0);
         if (rc != SQL_SUCCESS ) {
            check_error (pSQL);
            return NULL; // we have an error
         }
      }

      attrParm = SQL_TRUE;
      rc = SQLSetStmtAttr  (pSQL->pstmt->hstmt, SQL_ATTR_EXTENDED_COL_INFO , &attrParm  , 0);
      if (rc != SQL_SUCCESS ) {
         check_error (pSQL);
         return NULL; // we have an error
      }

      attrParm = SQL_CONCUR_READ_ONLY;
      rc = SQLSetStmtAttr  (pSQL->pstmt->hstmt, SQL_ATTR_CONCURRENCY , &attrParm  , 0);
      if (rc != SQL_SUCCESS ) {
         check_error (pSQL);
         return NULL; // we have an error
      }

      // TODO !!! SQL_ATTR_MAX_ROWS

   }

   return pSQL;

}
// ------------------------------------------------------------------
// https://www.ibm.com/docs/en/i/7.4?topic=program-null-capable-fields
// ------------------------------------------------------------------
static PUCHAR getSystemColumnName ( PUCHAR sysColumnName, PUCHAR columnText, PUCHAR schema , PUCHAR table , PUCHAR column )
{

   #pragma mapinc("QADBILFI", "QSYS/QADBILFI(*all)" , "both key nullflds", "_P", "RecBuf" , "")
   #include "/QSYS.LIB/QTEMP.LIB/QACYXTRA.FILE/QADBILFI.MBR"
   typedef QDBIFLD_both_t SYSCOLR, * PSYSCOLR;
   typedef QDBIFLD_key_t  SYSCOLK;

   _RIOFB_T * fb;
   SYSCOLR sysColR;
   SYSCOLK sysColK;
   int keylen;
   int i;

   static _RFILE * fSysCol = null;
   if ((fSysCol = _Ropen ("QSYS/QADBILFI" , "rr,nullcap=Y")) == NULL) {
      jx_joblog ( "Not able to open QADBILFI: %s",  strerror(errno)) ;
      return sysColumnName;
   }

   // memset will not work on "volatile" in null maps
   for (i=0; i< fSysCol->null_map_len     ; i ++) { fSysCol->in_null_map[i]= '0';}
   for (i=0; i< fSysCol->null_key_map_len ; i ++) { fSysCol->null_key_map[i]= '0';}

   padncpy  (sysColK.DBILIB , schema , sizeof(sysColK.DBILIB));
   str2vc   (&sysColK.DBILFI , table  );
   keylen = sizeof(sysColK.DBILIB) + sysColK.DBILFI.len;

   // Get format and part info  by table / file name:
   fb = _Rreadk (fSysCol  ,&sysColR , sizeof(SYSCOLR) ,
                 __KEY_EQ | __NULL_KEY_MAP  , &sysColK , keylen);
   if (fb->num_bytes == 0) {
      return NULL;
   }
   // Now have the format and part no
   // now move the format and part into key
   sysColK.DBIFMP = sysColR.DBIFMP;
   memcpy   (sysColK.DBIFMT , sysColR.DBIFMT , sizeof ( sysColK.DBIFMT ));
   str2vc   ((PVAR_CHAR) &sysColK.DBILFL , column );

   // We have the complete key -  get the name for column
   fb = _Rreadk (fSysCol  ,&sysColR , sizeof(SYSCOLR) , __KEY_EQ  , &sysColK , sizeof(SYSCOLK));
   if (fb->num_bytes == 0) {
      return NULL;
   }
   strtrimncpy ( sysColumnName , sysColR.DBIINT , sizeof(sysColR.DBIINT));
   substr ( columnText ,  sysColR.DBITXT.data , sysColR.DBITXT.len);

   return sysColumnName;

}
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

   return  getSystemColumnName ( sysColumnName, columnText, schema , table , column);
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

///* -------------------------------------------------------------
//   Locates the part after CTE last pareparenthesis
//   ------------------------------------------------------------- */
//PUCHAR finalSQLPart (PUCHAR stmt)
//{
//   PUCHAR p   = stmt;
//   PUCHAR ret = stmt;
//   int level =0;
//   for (;*p;p++) {
//      switch (*p) {
//         case '(' :
//            level ++;
//            break;
//         case ')' :
//            level --;
//            if (level == 0) {
//               ret = p +1;
//            }
//            break;
//      }
//   }
//   return ret;
//}
/* ------------------------------------------------------------- */
/* Poyfill for regex                                             */
/* ------------------------------------------------------------- */
BOOL findHasLimit  (PUCHAR sqlStmt)
{
   PUCHAR p = stristr(sqlStmt, "limit ");
   if (p && *(p -1) == ' ') {
      UCHAR temp [10];
      substr ( temp , p+6, 3);
      if ( str2dec ( temp , ',' ) > 0) {
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
   PUCHAR p = stristr(sqlStmt, "offset ");
   if (p && *(p -1) == ' ') {
      UCHAR temp [10];
      substr ( temp , p+6, 3);
      if ( str2dec ( temp , ',' ) > 0) {
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
   PUCHAR p = stristr(sqlStmt, "fetch ");
   if (p && *(p -1) == ' ') {
      PUCHAR p2 = stristr(p , "first ");
      if (p2 && *(p2 -1) == ' ') {
            return true;
      }
   }
   return false;
}

/* ------------------------------------------------------------- */
PJXSQL jx_sqlOpen(PUCHAR sqlstmt , PJXNODE pSqlParmsP, LONG formatP , LONG startP , LONG limitP )
{

   UCHAR sqlTempStmt[32766];
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PJXNODE pSqlParms  =  (pParms->OpDescList->NbrOfParms >= 2 ) ? pSqlParmsP : NULL;
   LONG   format      =  (pParms->OpDescList->NbrOfParms >= 3 ) ? formatP : 0;
   LONG   start       =  (pParms->OpDescList->NbrOfParms >= 4 ) ? startP : NOXDB_FIRST_ROW; // begining
   LONG   limit       =  (pParms->OpDescList->NbrOfParms >= 5 ) ? limitP : NOXDB_ALL_ROWS; // all rows
   LONG   attrParm;
   LONG   i;
   UCHAR  typeName [256];
   LONG   tprc;
   //   PJXSQL pSQL = jx_sqlNewStatement (pParms->OpDescList->NbrOfParms >= 2 ? pSqlParms  :NULL);
   PJXSQL pSQL;
   SQLINTEGER  dummyInt , isTrue,descLen;
   SQLSMALLINT len , dummyShort;
   BOOL scroll = pParms->OpDescList->NbrOfParms <= 2; // Typicall from CALL from RPG

   int rc;

   // quick trim - advance the pointer until data:
   for  (;*sqlstmt > '\0' && *sqlstmt <= ' '; sqlstmt++);

   jxError = false; // Assume OK

   pSQL = jx_sqlNewStatement (NULL, false, scroll);
   if  ( pSQL == NULL) return NULL;

   if ( pConnection->options.hexSort == ON ) {
      LONG attrParm = SQL_FALSE ;
      LONG attr = SQL_ATTR_JOB_SORT_SEQUENCE;
      rc = SQLSetEnvAttr  (pConnection->henv, attr , &attrParm  , 0);
   }

   // build the final sql statement
   strFormat(sqlTempStmt , sqlstmt , pSqlParms);


   //// huxi !! need uncomitted read for blob fields
   // and IBM i does not support statement attribute to set the pr statement. :/
   // so we simply append the "with ur" uncommited read options
   if ((0 != memicmp ( sqlTempStmt , "call", 4))
   &&  (0 != memicmp ( sqlTempStmt , "values", 6))) {
      PUCHAR lookFrom = finalSQLPart (sqlTempStmt);
      static BOOL compilereg = true;
      static regex_t hasLimitReg;
      static regex_t hasOffsetReg;
      static regex_t hasFetchReg;
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
         #pragma convert(1252)
         rc = regcomp(&hasLimitReg , XlateStringQ (buf , "limit[ ]*[0-9]" , 1252, 0)  , options );
         rc = regcomp(&hasOffsetReg, XlateStringQ (buf , "offset[ ]*[0-9]", 1252, 0)   , options );
         rc = regcomp(&hasFetchReg , XlateStringQ (buf , "fetch[ ]*first" , 1252, 0)     , options );
      	#pragma convert(0)
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
         sprintf (sqlTempStmt + strlen(sqlTempStmt)," limit %ld ", limit);
      }
      // Note !! Offset is "Number if rows to skip" therefor the -1 from the "start"
      if (start > 1 && ! hasOffset) {
         sprintf (sqlTempStmt + strlen(sqlTempStmt)," offset %ld ", start - 1);
      }
      if (pConnection->transaction == false ) {
         strcat ( sqlTempStmt , " with ur");
      }
   }
   pSQL->sqlstmt = strdup(sqlTempStmt);


   rc = jx_sqlExecDirectTrace(pSQL , pSQL->pstmt->hstmt, pSQL->sqlstmt);
   if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
     // is checked in abowe    check_error (pSQL);
     return NULL; // we have an error
   }

   // Number of rows? .. No does not work :(
   // DB2_NUMBER_ROWS = 110
   // SQLGetDiagField(SQL_HANDLE_STMT,pSQL->pstmt->hstmt, 0 , 110 ,&pSQL->rowcount,0, NULL);

   // Row count is only affected row in a "delete" or "update" ..TODO find a solution for select
   /*
   rc = SQLRowCount (pSQL->pstmt->hstmt, &pSQL->rowcount);
   if (rc != SQL_SUCCESS ) {
     check_error (pSQL);
     return NULL; // we have an error
   }
   */

   rc = SQLNumResultCols (pSQL->pstmt->hstmt, &pSQL->nresultcols);
   if (rc != SQL_SUCCESS ) {
      check_error (pSQL);
      return NULL; // we have an error
   }
   pSQL->cols = memAlloc (pSQL->nresultcols * sizeof(JXCOL));

   for (i = 0; i < pSQL->nresultcols; i++) {

      int labelRc;
      UCHAR colText  [256];

      PJXCOL pCol = &pSQL->cols[i];

      rc = SQLDescribeCol (
         pSQL->pstmt->hstmt,
         i+1,
         pCol->colname,
         sizeof (pCol->colname),
         &pCol->colnamelen,
         &pCol->coltype,
         (SQLINTEGER *) &pCol->collen,
         &pCol->scale,
         &pCol->nullable
      );

      pCol->colname[pCol->colnamelen] = '\0';
      strcpy (pCol->realname , pCol->colname);

      if (format & (JX_SYSTEM_NAMES | JX_COLUMN_TEXT)) {
         if (NULL == getSysNameForColumn ( pCol->sysname , colText , pSQL->pstmt->hstmt , i+1)) {
            strcpy (pCol->sysname , pCol->colname);
            strcpy (colText       , pCol->colname);
         }
      } else {
         *pCol->sysname = '\0';
      }

      if (format & (JX_COLUMN_TEXT)) {
         strcpy (pCol->text , colText);
      } else {
         *pCol->text = '\0';
      }

      // If all uppsercase ( not given name by .. AS "newName") then lowercase
      if (format & (JX_SYSTEM_NAMES)) {
         if (!(format & (JX_UPPERCASE))) {
            str2lower  (pCol->colname , pCol->sysname);
         }  else {
            strcpy  (pCol->colname , pCol->sysname);
         }
      } else if (format & (JX_CAMEL_CASE)) {
         camelCase(pCol->colname, pCol->colname);
      } else if (format & (JX_UPPERCASE)) {
         // It is upper NOW
         // jx_sqlUpperCaseNames(pSQL);
      } else if (OFF == jx_IsTrue (pConnection->pOptions ,"uppercasecolname")) {
         UCHAR temp [256];
         str2upper  (temp , pCol->colname);
         if (strcmp (temp , pCol->colname) == 0) {
            str2lower  (pCol->colname , pCol->colname);
         }
      }

      // is it an ID column ? get the label, if no label then use the column name
      isTrue = SQL_FALSE;
      rc = SQLColAttribute (pSQL->pstmt->hstmt,i+1,SQL_DESC_AUTO_INCREMENT, NULL, 0, NULL ,&isTrue);
      pCol->isId = isTrue == SQL_TRUE;

      // get the label, if no label then use the column name
      // NOTE in ver 5.4 this only return the 10 first chars ...
      labelRc = SQLColAttribute (pSQL->pstmt->hstmt,i+1,SQL_DESC_LABEL, pCol->header, sizeof(pCol->header),&len,&dummyInt);
      if (labelRc == SQL_SUCCESS) {
         pCol->header[len] =  '\0';
         righttrim(pCol->header);
      } else {
         // No headers, if none provided, default to the column name
         strcpy(pCol->header ,  pCol->colname);
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
            pCol->collen = pCol->displaysize * 2;  // minimum  1MEGABYTES
            // NOTE min and max has odd behaviour !!
            if (pCol->collen  < 1048576L) {
               pCol->collen = 1048576L;
            }
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
   //         pCol->data = (SQLCHAR *) malloc (pCol->collen);
   //         rc = SQLBindCol (pSQL->pstmt->hstmt, i+1, SQL_C_CHAR, pCol->data, pCol->collen, &pCol->outlen);
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
            pCol->nodeType = JX_LITERAL;
            break;
         default:
            pCol->nodeType = JX_VALUE;
      }

   }

   return pSQL;

}
/* ------------------------------------------------------------- */
PJXNODE jx_sqlFormatRow  (PJXSQL pSQL)
{
   int i;
   PJXNODE pRow;
   SQLINTEGER buflen, datatype;
   PUCHAR buf = memAlloc (pSQL->maxColSize);

   if ( pSQL->rc == SQL_SUCCESS
   ||   pSQL->rc == SQL_SUCCESS_WITH_INFO ) {
      jxError = false;

      pRow = jx_NewObject(NULL);

      for (i = 0; i < pSQL->nresultcols; i++) {

         PJXCOL pCol = &pSQL->cols[i];

         // TODO - Work arround !!! first get the length - if null, the dont try the get data
         // If it has a pointer value, the API will fail..
         // For now BLOB and CLOB does not support "not null with default"
         // buflen =0;
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
               // SQLGetCol (pSQL->pstmt->hstmt, i+1, SQL_CHAR, buf , memSize(buf), &buflen);
               SQLGetCol (pSQL->pstmt->hstmt, i+1, SQL_CHAR, buf , LONG_MAX, &buflen);
         }


         // Null data is the same for all types
         if (buflen  ==  SQL_NULL_DATA) {
            jx_NodeAdd (pRow , RL_LAST_CHILD, pCol->colname , NULL,  JX_LITERAL );
         } else {

            memset ( buf + buflen, 0 , 2); // Zero term - also UNICODE

            switch( pCol->coltype) {
               case SQL_BOOLEAN    :
                  jx_NodeAdd (pRow , RL_LAST_CHILD, pCol->colname , (*buf == '1' || *buf == 't') ? "true":"false",  pCol->nodeType );
                  break;
               case SQL_WCHAR:
               case SQL_WVARCHAR:
               case SQL_GRAPHIC:
               case SQL_VARGRAPHIC: {
                  UCHAR temp [32768];
                  PUCHAR pInBuf = buf;
                  size_t OutLen;
                  size_t inbytesleft;

                  // fix  - even bound to a c-buffer, it returns the length
                  if (pCol->coltype ==  SQL_WVARCHAR) {
                    inbytesleft = (* (PSHORT) pInBuf) * 2; // Peak the length, and unicode uses two bytes
                    pInBuf += 2; // skip len
                  } else {
                     for  (inbytesleft = pCol->collen; inbytesleft > 0 ; inbytesleft -= 2) {
                        if ( * (PSHORT) (pInBuf + inbytesleft - 2) > 0x0020) break;
                     }
                  }
                  OutLen = XlateBuffer  (pConnection->pCd, temp , pInBuf, inbytesleft);
                  temp[OutLen] = '\0';

                  jx_NodeAdd (pRow , RL_LAST_CHILD, pCol->colname , temp,  pCol->nodeType );

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

                  len = strTrimLen(p);
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

                  jx_NodeAdd (pRow , RL_LAST_CHILD, pCol->colname , p,  pCol->nodeType );
                  break ;
               }

               default: {
                  PUCHAR p = buf;
                  int len;

                  if (pCol->coltype != SQL_BLOB
                  &&  pCol->coltype != SQL_CLOB) {
                     len = strTrimLen(p);
                     p[len] = '\0';
                  }

                  // trigger new parsing of JSON-objects in columns:
                  // Predicts json data i columns
                  if (pConnection->options.autoParseContent == ON) {
                     if (*p == jobBraBeg || *p == jobCurBeg) {
                        PJXNODE pNode = jx_parseStringCcsid(p, 0);
                        if (pNode) {
                           jx_NodeRename(pNode, pCol->colname);
                           jx_NodeInsertChildTail (pRow, pNode);
                           break;
                        }
                     }
                  }

                  jx_NodeAdd (pRow , RL_LAST_CHILD, pCol->colname , p,  pCol->nodeType );
                  break;
               }
            }
         }
      }
      memFree(&buf);

      return pRow; // Found

   } else {
      sqlCode = getSqlCode(pSQL->pstmt->hstmt);
      if (pSQL->rc != SQL_NO_DATA_FOUND ) {
         check_error (pSQL);
      }
   }

   memFree(&buf);
   return NULL; // not found
}
/* ------------------------------------------------------------- */
PJXNODE jx_sqlFetchRelative (PJXSQL pSQL, LONG fromRow)
{
   int rc;
   if (pSQL == NULL) return (NULL);

   pSQL->rc = SQLFetchScroll (pSQL->pstmt->hstmt, SQL_FETCH_RELATIVE , (fromRow < 1) ? 1: fromRow);
   return jx_sqlFormatRow(pSQL);
}
/* ------------------------------------------------------------- */
PJXNODE jx_sqlFetchNext (PJXSQL pSQL)
{
   int rc;
   if (pSQL == NULL) return (NULL);

   // List next row from the result set
   pSQL->rc = SQLFetch (pSQL->pstmt->hstmt);
   return jx_sqlFormatRow(pSQL);
}
/* ------------------------------------------------------------- */
/****** not used
PJXNODE jx_sqlFetchFirst (PJXSQL pSQL, LONG fromRow)
{
   int rc;
   if (pSQL == NULL) return (NULL);

   if (fromRow > 1) {
      pSQL->rc = SQLFetchScroll (pSQL->pstmt->hstmt, SQL_FETCH_RELATIVE , fromRow);
   } else {
      pSQL->rc = SQLFetch (pSQL->pstmt->hstmt);
   }
   return jx_sqlFormatRow(pSQL);
}
***/
/* ------------------------------------------------------------- */
void jx_sqlClose (PJXSQL * ppSQL)
{
   int i;
   int rc;
   PJXSQL pSQL = * ppSQL;

   if (pConnection->options.hexSort == ON ) {
      LONG attrParm = SQL_TRUE ;
      rc = SQLSetEnvAttr (pConnection->henv, SQL_ATTR_JOB_SORT_SEQUENCE , &attrParm  , 0);
      pConnection->options.hexSort = OFF;
   }

   // Do we have an active statement ...
   if (pSQL) {

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
void jx_sqlKeepConnection (BOOL keep)
{
   keepConnection = keep;
}
/* ------------------------------------------------------------- */
void jx_sqlDisconnect (void)
{

   int rc;

   // if (keepConnection )  return;

   if (pConnection == NULL) return;

   iconv_close (pConnection->pCd) ;

   if (pConnection->sqlTrace.handle != -1) {
      rc = SQLFreeHandle (SQL_HANDLE_STMT, pConnection->sqlTrace.handle);
      pConnection->sqlTrace.handle = -1;
   }

   // disconnect from database
   if (pConnection->hdbc != -1) {
      SQLDisconnect  (pConnection->hdbc);
      SQLFreeConnect (pConnection->hdbc);
      pConnection->hdbc = -1;
   }

   // free environment handle
   if (pConnection->henv != -1) {
      SQLFreeEnv (pConnection->henv);
      pConnection->henv = -1;
   }

   jx_Close(&pConnection->pOptions);
   pConnection = NULL;

}
/* ------------------------------------------------------------- */
PJXNODE jx_buildMetaFields ( PJXSQL pSQL )
{
   int rc;
   LONG    attrParm;
   PJXNODE pFields;
   int i;

   if (pSQL == NULL) return(NULL);

   pFields  = jx_NewArray(NULL);

   /*****  need to be done before the cursor is closed !!

   attrParm = SQL_TRUE;
   rc = SQLSetStmtAttr  (pSQL->pstmt->hstmt, SQL_ATTR_EXTENDED_COL_INFO , &attrParm  , 0);
   if (rc != SQL_SUCCESS ) {
     check_error (pSQL);
     return NULL; // we have an error
   }
   ******/

   for (i = 1; i <= pSQL->nresultcols; i++) {
      PJXNODE pField  = jx_NewObject (NULL);
      PJXCOL  pCol     = &pSQL->cols[i-1];
      PUCHAR  type = "string";
      UCHAR   temp [256];
      SQLINTEGER templen;
      SQLINTEGER descNo;

      // Add name
      jx_NodeAdd (pField  , RL_LAST_CHILD, "name"     , pCol->colname,  VALUE );
      jx_NodeAdd (pField  , RL_LAST_CHILD, "colname"  , pCol->realname, VALUE  );

      if (*pCol->sysname  > ' ') {
         jx_NodeAdd (pField, RL_LAST_CHILD, "sysname", pCol->sysname, VALUE  );
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
         case SQL_BIGINT     : type = "bigint"         ; break;
         case SQL_TINYINT    : type = "tinyint"        ; break;
         case SQL_BOOLEAN    : type = "boolean"        ; break;

         default: {
            if (pCol->coltype >= SQL_NUMERIC && pCol->coltype <= SQL_DOUBLE ) {
               if (pCol->scale > 0) {
                  type = "dec"     ;
               } else {
                  type = "int"     ;
               }
            } else {
               sprintf(temp ,"unknown%d" , pCol->coltype);
               type = temp;
            }
         }
      }
      jx_NodeAdd (pField  , RL_LAST_CHILD, "datatype" , type,  VALUE );

      sprintf(temp , "%d" ,  pCol->coltype);
      jx_NodeAdd (pField  , RL_LAST_CHILD, "sqltype" , temp ,  LITERAL);

      // Add size
      sprintf(temp , "%d" , pCol->displaysize);
      jx_NodeAdd (pField  , RL_LAST_CHILD, "size"     , temp,  LITERAL  );

      // Add decimal precission
      if  (pCol->coltype >= SQL_NUMERIC && pCol->coltype <= SQL_DOUBLE
      &&   pCol->scale > 0) {
         sprintf(temp , "%d" , pCol->scale);
         jx_NodeAdd (pField  , RL_LAST_CHILD, "prec"     , temp,  LITERAL  );
      }

      jx_NodeAdd (pField  , RL_LAST_CHILD, "header" , pCol->header, VALUE  );

      if (*pCol->text > ' ') {
         jx_NodeAdd (pField  , RL_LAST_CHILD, "text"   , pCol->text, VALUE  );
      }

      // Push to array
      jx_ArrayPush (pFields , pField, FALSE);
   }

   // jx_Debug ("Fields:", pFields);
   return  pFields;

}
/* ------------------------------------------------------------- */
static BOOL buildCountStatement (PUCHAR countStmt, PUCHAR sqlStmt)
{

   PUCHAR  pCountStmt = countStmt;
   PUCHAR  end;
   int len;

   // quick trim
   for  (;*sqlStmt <= ' ' && *sqlStmt > '\0'; sqlStmt++);;

   // find the active part of the select statment ( i.e. up until with ur is exists)
   end  =  stristr(sqlStmt  , "with ur");
   len = end == NULL ? strlen (sqlStmt) : end - sqlStmt;

   // CTE - diffrent syntax
   if (BeginsWith(sqlStmt, "with")) {
      PUCHAR w = sqlStmt;
      int para = 0;
      for(;;) {
         switch (*w) {
            case '(':
               para++;
               break;
            case ')':
               para--;
               if (para == 0) {
                  for (w++; *w == ' '; w++);
                  if ( *w != ',') {
                     int firstPartLength = w - sqlStmt;
                     int nextPartLength = len - firstPartLength;
                     substr (pCountStmt, sqlStmt , firstPartLength);
                     pCountStmt += firstPartLength;
                     pCountStmt += sprintf(pCountStmt, "select count(*) counter from (");
                     substr (pCountStmt, w , nextPartLength);
                     pCountStmt += nextPartLength;
                     pCountStmt += sprintf(pCountStmt ,")");
                     return true;
                  }
               }
            break;
         }
         w++;
      }

   } else {
      pCountStmt += sprintf(pCountStmt , "select count(*) counter from (");
      substr (pCountStmt, sqlStmt , len);
      pCountStmt += len;
      pCountStmt += sprintf(pCountStmt , ")");
      return true;
   }
   return false; // Not build
}
/* ------------------------------------------------------------- */
LONG jx_sqlNumberOfRows(PUCHAR sqlStmt)
{

   LONG    rowCount;
   PJXNODE pRow;
   UCHAR   countStmt [32766];

   if (buildCountStatement (countStmt , sqlStmt)) {
      // Get that only row
      pRow = jx_sqlResultRow(countStmt, NULL, 0);
      rowCount = atoi(jx_GetValuePtr(pRow, "counter", "-1"));
      jx_NodeDelete (pRow);
      return rowCount;

   } else {
      return -1; // not able to produce a count statement
   }

}
/* ------------------------------------------------------------- */
/****************  OLD VERSION
LONG jx_sqlNumberOfRows(PUCHAR sqlstmt)
{

   LONG    rowCount, para = 0;
   PJXNODE pRow;
   PUCHAR p, w, lastSelect, orderby, from, withur;
   UCHAR  str2 [32766];

   // replace the coloumn list with a count(*) - TODO !! This will not work on a "with" statment

   // Find the last select ( there can be more when using "with")

   p = sqlstmt;
   w = stristr(p, "with ");
   p = stristr(p , "select ");

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
               lastSelect = stristr(w , "select ");
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
   from    = stristr(lastSelect , " from ");
   if (from == NULL) return 0;

   // remove order by - if any
   orderby = stristr(from  , " order ");
   if (orderby) {
      *orderby = '\0';
   }

   // remove "with ur" - if any
   withur = stristr(from  , " with ur");
   if (withur) {
      *withur = '\0';
   }


   // rebuild the select statement as a "select count(*) from ..."
   substr (str2 , sqlstmt , lastSelect - sqlstmt); // if a "With" exists then grab that
   strcat (str2 ,"select count(*) as counter" );
   strcat (str2 , from );

   // Get that only row
   pRow = jx_sqlResultRow(str2, NULL, 0);

   rowCount = atoi(jx_GetValuePtr(pRow, "counter", NULL));

   jx_NodeDelete (pRow);

   return rowCount;
}
************/
/* ------------------------------------------------------------- */

/***********
LONG jx_sqlNumberOfRowsDiag(PUCHAR sqlstmt)
{

   LONG    rowCount, para = 0;
   PJXNODE pRow;
   PUCHAR p, w, lastSelect, orderby, from, withur;
   UCHAR  str2 [32766];

   strcat (str2 , "GET DIAGNOSTICS :v = DB2_NUMBER_ROWS" );

   // Get that only row
   pRow = jx_sqlResultRow(str2, NULL);

   rowCount = atoi(jx_GetValuePtr(pRow, "counter", NULL));

   jx_NodeDelete (pRow);

   return rowCount;
}
*/
/* dont work - it is works when used in stored procedures  */
/*********
void jx_sqlGetDiagnostics ()
{

   int rc;
   UCHAR messageId [11];
   LONG length;

   PJXSQL pSQL = jx_sqlNewStatement (NULL, true, false);
   rc = SQLPrepare (pSQL->pstmt->hstmt, "get diagnostics condition 1? = DB2_MESSAGE_ID", SQL_NTS);
   rc = SQLBindParameter (
      pSQL->pstmt->hstmt,
      1,
      SQL_PARAM_OUTPUT ,
      SQL_C_DEFAULT,
      SQL_C_CHAR,
      0,
      0,
      messageId ,
      sizeof(messageId),
      &length
   );
   rc = SQLExecute (pSQL->pstmt->hstmt);
   jx_sqlClose (&pSQL);
}
*******/
/* ------------------------------------------------------------- */
/********
void jx_sqlUpperCaseNames(PJXSQL pSQL)
{
   int i;
   for (i = 0; i < pSQL->nresultcols; i++) {
     PJXCOL pCol = &pSQL->cols[i];
     str2upper (pCol->colname , pCol->colname);
   }
}
*****/
/* ------------------------------------------------------------- */
LONG jx_sqlColumns (PJXSQL pSQL)
{
   if (pSQL == NULL) return -1;
   return (pSQL->nresultcols);
}
/* ------------------------------------------------------------- */
LONG jx_sqlRows (PJXSQL pSQL)
{
   if (pSQL == NULL) return -1;
   if (pSQL->rowcount == -1) {
      pSQL->rowcount = jx_sqlNumberOfRows(pSQL->sqlstmt);
   }

   return (pSQL->rowcount);
}
/* ------------------------------------------------------------- *\
   Maybe use this for jx_sqlProcedureMeta :

   SQLRETURN sqlRet = SQLProcedureColumns(
      SQLHSTMT          pSQL->pstmt->hstmt,
      SQLCHAR           NULL, // *CatalogName,
      SQLSMALLINT       0 , // NameLength1,
      SQLCHAR           NULL // *SchemaName,
      SQLSMALLINT       NameLength2,
      SQLCHAR           *ProcName,
      SQLSMALLINT       NameLength3,
      SQLCHAR           *ColumnName,
      SQLSMALLINT       NameLength4
   );

   but for now:
\* ------------------------------------------------------------- */
PJXNODE jx_sqlProcedureMeta (PUCHAR procedureName)
{

   UCHAR sqlStmt [1024];
   UCHAR schema [32];
   UCHAR procedure  [256];
   PUCHAR split;

   split = strchr(procedureName , '.');

   if (split == NULL) return NULL;

   substr (schema    , procedureName , split - procedureName);
   strcpy (procedure , split +1);


   sprintf (sqlStmt ,
      "with cte as ( "
      "select "
         "a.specific_name specific_name,"
         "parameter_mode,"
         "parameter_name,"
         "data_type,"
         "numeric_scale,"
         "numeric_precision,"
         "character_maximum_length,"
         "numeric_precision_radix,"
         "datetime_precision,"
         "is_nullable,"
         "data_type_name,"
         "max(ifnull(numeric_precision , 0) + 2, ifnull(character_maximum_length,0))  buffer_length "
      "from sysprocs a "
      "left join  sysparms b "
      "on a.specific_schema = b.specific_schema and a.specific_name = b.specific_name "
      "where a.routine_schema  = upper('%s') "
      "and   a.routine_name = upper('%s') "
      ") "
      "select (select count(distinct cte.specific_name) from cte) number_of_implementations  , cte.* from cte "
      , schema ,procedure
   );
   return jx_sqlResultSet(sqlStmt, 0 , 99999 , 0 , NULL);
}
/* ------------------------------------------------------------- */
// Get Meta from All types - only works if names are unique accross
// scalar / table / procedures.
// Alternative use The specific version
/* ------------------------------------------------------------- */
PJXNODE jx_sqlRoutineMeta (PUCHAR routineName)
{

   UCHAR sqlStmt [1024];
   UCHAR schema [32];
   UCHAR routine  [256];
   PUCHAR split;

   split = strchr(routineName , '.');

   if (split == NULL) return NULL;

   substr (schema    , routineName , split - routineName);
   strcpy (routine , split +1);


   sprintf (sqlStmt ,
      "with cte as ( "
      "select "
         "case a.function_type when 'S' then 'S' when 'T' then 'T' else 'P' end type ,"
         "a.specific_name specific_name,"
         "a.max_dynamic_result_sets,"
         "parameter_mode,"
         "parameter_name,"
         "data_type,"
         "numeric_scale,"
         "numeric_precision,"
         "character_maximum_length,"
         "numeric_precision_radix,"
         "datetime_precision,"
         "is_nullable,"
         "data_type_name,"
         "max(ifnull(numeric_precision , 0) + 2, ifnull(character_maximum_length,0))  buffer_length "
      "from sysroutines  a "
      "left join  sysparms b "
      "on a.specific_schema = b.specific_schema and a.specific_name = b.specific_name "
      "where a.routine_schema  = upper('%s') "
      "and   a.routine_name = upper('%s') "
      ") "
      "select (select count(distinct cte.specific_name) from cte) number_of_implementations  , cte.* from cte "
      , schema ,routine
   );
   return jx_sqlResultSet(sqlStmt, 0 , 99999 , 0 , NULL);
}
/* ------------------------------------------------------------- */
PJXNODE jx_sqlSpecificRoutineMeta (PUCHAR routineName)
{

   UCHAR sqlStmt [1024];
   UCHAR schema [32];
   UCHAR routine  [256];
   PUCHAR split;

   split = strchr(routineName , '.');

   if (split == NULL) return NULL;

   substr (schema    , routineName , split - routineName);
   strcpy (routine , split +1);


   sprintf (sqlStmt ,
      "with cte as ( "
      "select "
         "case a.function_type when 'S' then 'S' when 'T' then 'T' else 'P' end type ,"
         "a.routine_name routine_name,"
         "a.routine_schema routine_schema,"
         "a.specific_name specific_name,"
         "a.max_dynamic_result_sets,"
         "parameter_mode,"
         "parameter_name,"
         "data_type,"
         "numeric_scale,"
         "numeric_precision,"
         "character_maximum_length,"
         "numeric_precision_radix,"
         "datetime_precision,"
         "is_nullable,"
         "data_type_name,"
         "max(ifnull(numeric_precision , 0) + 2, ifnull(character_maximum_length,0))  buffer_length "
      "from sysroutines  a "
      "left join  sysparms b "
      "on a.specific_schema = b.specific_schema and a.specific_name = b.specific_name "
      "where a.specific_schema = upper('%s') "
      "and   a.specific_name   = upper('%s') "
      ") "
      "select (select count(distinct cte.specific_name) from cte) number_of_implementations  , cte.* from cte "
      , schema ,routine
   );
   return jx_sqlResultSet(sqlStmt, 0 , 99999 , 0 , NULL);
}
/* ------------------------------------------------------------- */
static SQLSMALLINT text2parmtype (PUCHAR mode)  {
   if  (0 == strcmp (mode , "IN"))  return SQL_PARAM_INPUT;
   if  (0 == strcmp (mode , "OUT")) return SQL_PARAM_OUTPUT;
   return SQL_PARAM_INPUT_OUTPUT;
}
/* ------------------------------------------------------------- */
static SQLSMALLINT textType2SQLtype (PUCHAR parmType, PUCHAR parmName)  {

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

   jx_joblog("Unsupported datatype %s for %s" , parmType, parmName);

   return(NOXDB_UNKNOWN_SQL_DATATYPE);

/* TODO  !!  more types
   if  (0 == strcmp (mode , "GRAPHIC VARYING"))                     return();
   if  (0 == strcmp (mode , "BINARY VARYING"))                      return();
   if  (0 == strcmp (mode , "BINARY"))                              return();

   if  (0 == strcmp (mode , "ARRAY"))                               return();
   if  (0 == strcmp (mode , "BINARY LARGE OBJECT"))                 return();
   if  (0 == strcmp (mode , "DOUBLE-BYTE CHARACTER LARGE OBJECT"))  return();
   if  (0 == strcmp (mode , "ROWID"))                               return();
   if  (0 == strcmp (mode , "DISTINCT"))                            return();
   if  (0 == strcmp (mode , "XML"))                                 return();
   if  (0 == strcmp (mode , "CHARACTER LARGE OBJECT"))              return();
   if  (0 == strcmp (parmType , "CHARACTER LARGE OBJECT")) return(SQL_CLOB);
*/
}
/* ------------------------------------------------------------- */
static LONG currentLength (PPROCPARM p, LONG length)
{
   if (p->mode == SQL_PARAM_INPUT
   ||  p->mode == SQL_PARAM_INPUT_OUTPUT) {
      return (p->pData == null) ? SQL_NULL_DATA : length;
   } else {
      return length;
   }
}
/* ------------------------------------------------------------- */
// Note: Only works on qualified procedure calls
/* ------------------------------------------------------------- */
PJXNODE jx_sqlCall ( PUCHAR procedureName , PJXNODE pInParms)
{
   PJXNODE pResult = NULL;
   UCHAR   stmtBuf [32760];
   PUCHAR  stmt =stmtBuf;
   PJXNODE pNode;
   PUCHAR  name;
   UCHAR   temp [256];
   PUCHAR  comma = "";
   PJXSQL  pSQL;
   int     rc;
   int     outCol;
   SQLSMALLINT i;
   LONG    bufLen ;
   int     impl;
   SQLRETURN    sqlRet;
   SQLSMALLINT  fCtype;
   SQLSMALLINT  fSQLtype;

   UCHAR      buffer  [650000];
   PUCHAR     bufferPos = buffer;
   int        numerOfParms = 0;
   PJXNODE    pProcMeta = jx_sqlProcedureMeta (procedureName);
   PROCPARM   procParms   [NOXDB_MAX_PARMS];
   PPROCPARM  p;


   if (pProcMeta == NULL) {
      sprintf( jxMessage , "Procedure %s is not found or not called qualified" , procedureName);
      jxError = true;
      return NULL;
   }
   pNode    =  jx_GetNodeChild (pProcMeta);
   impl = atoi (jx_GetValuePtr (pNode , "number_of_implementations" , "0"));

   if (impl > 1) {
      sprintf( jxMessage , "Procedure %s has %d implementations. Can not decide which to use" , procedureName, impl);
      jxError = true;
      jx_NodeDelete (pProcMeta);
      return NULL;
   }

   stmt += sprintf (stmt , "call %s (" , procedureName );

   pNode    =  jx_GetNodeChild (pProcMeta);
   for (i=0; pNode; i++) {
      p = &procParms[i];
      p->name = jx_GetValuePtr    (pNode , "parameter_name" , "");
      p->mode = text2parmtype (jx_GetValuePtr    (pNode , "parameter_mode" , ""));
      p->sqlType  = textType2SQLtype (jx_GetValuePtr (pNode , "data_type" , ""), p->name);

      if (p->mode == SQL_PARAM_INPUT
      && NULL == jx_GetNode  (pInParms, p->name)) {
         // Omit it from parmist, reuse this slot for next parameter
         i --;
      } else {
         stmt += sprintf (stmt , "%s%s=>?"  , comma , p->name);
         comma = ",";
         numerOfParms = i+1;
         p->pNode = pNode;
         p->pData = jx_GetValuePtr(pInParms , p->name ,null);
      }
      pNode = jx_GetNodeNext(pNode);
   }
   stmt += sprintf (stmt , ")" );

   pSQL = jx_sqlNewStatement (NULL, true, false);
   rc  = SQLPrepare( pSQL->pstmt->hstmt, stmtBuf, SQL_NTS );

   for (i=0; i < numerOfParms ; i++) {
      int nullterm = 0;
      PUCHAR userType = jx_GetValuePtr (p->pNode , "data_type_name" , "");
      p = &procParms[i];

      p->buffer = bufferPos;
      p->type = 0 == atoi (jx_GetValuePtr (p->pNode , "numeric_precision" , "0")) ? VALUE:LITERAL;
      // Pollyfill for BOOLEAN pre 7.5
      p->isBool = BeginsWith (userType , "BOOL");

      switch (p->sqlType ) {
         case SQL_CHAR:
         case SQL_VARCHAR:
         case SQL_TIMESTAMP:
         case SQL_DATE:
         case SQL_TIME:
         case SQL_DECIMAL:
         case SQL_NUMERIC:
         case NOXDB_UNKNOWN_SQL_DATATYPE:
            fCtype = SQL_C_CHAR;
            p->inLen   = currentLength (p, p->pData ? strlen(p->pData):0);
            p->bufLen  = atol (jx_GetValuePtr   (p->pNode , "buffer_length" , "0"));
            if ( p->inLen != SQL_NULL_DATA ) {
               // Pollyfill for BOOLEAN pre 7.5
               if (p->isBool) {
                  p->bufLen = 1;
                  strcpy ( p->buffer , (0==strcmp (p->buffer, "true") ? "1":"0"));
               } else {
                  substr( p->buffer , p->pData , p->inLen);
               }
            }
            *(p->buffer + p->bufLen) = '\0'; // Always keep an final zertermination at the end of buffer
            nullterm = 1 ; // Keep the zerotermination in the buffer;
            break;
         case SQL_SMALLINT:
            fCtype = SQL_C_SHORT;
            p->inLen  = currentLength (p, p->pData ? sizeof(SHORT):0);
            p->bufLen = sizeof(SHORT);
            if (p->pData) * (SHORT *) p->buffer = atoi(p->pData);
            break;
         case SQL_INTEGER:
            fCtype = SQL_C_LONG;
            p->inLen  = currentLength (p, p->pData ? sizeof(LONG):0);
            p->bufLen = sizeof(LONG);
            if (p->pData)  * (LONG *) p->buffer = atol(p->pData);
            break;
         case SQL_BIGINT:
            fCtype = SQL_C_BIGINT;
            p->inLen  = currentLength (p, p->pData ? sizeof(INT64):0);
            p->bufLen = sizeof(INT64);
            if (p->pData)  * (INT64 *) p->buffer = atoll(p->pData);
            break;
         case SQL_REAL:
            fCtype = SQL_C_FLOAT;
            p->inLen  = currentLength (p, p->pData ? sizeof(float):0);
            p->bufLen = sizeof(float);
            if (p->pData)  * (float *) p->buffer = atof(p->pData);
            break;
         case SQL_DOUBLE:
            fCtype = SQL_C_DOUBLE;
            p->inLen  = currentLength (p, p->pData ? sizeof(double):0);
            p->bufLen = sizeof(double);
            if (p->pData)  * (double  *) p->buffer = atof(p->pData);
            break;
      }


      rc  = SQLBindParameter (
         pSQL->pstmt->hstmt,  // hstmt
         i + 1,            // Parm number
         p->mode,          // fParamType
         fCtype ,          // data type here in C
         p->sqlType,       // dtatype in SQL
         p->bufLen,        // precision / Length of the C - string
         0,
         p->buffer,        // buffer ,
         0,                // cbValueMax
         &p->inLen         // Buffer length  or indPtr // was:  &outLen              // pcbValue
      );

      // Setup next;
      bufferPos += p->bufLen + nullterm;
   }

   rc = SQLExecute(pSQL->pstmt->hstmt);
   if (rc != SQL_SUCCESS &&  rc != SQL_SUCCESS_WITH_INFO) {
      check_error (pSQL);
      jxError = true;
      jx_NodeDelete (pProcMeta);
      return NULL;
   }

   pResult = jx_NewObject(NULL);

   for (i = 0 ; i < numerOfParms  ; i ++) {
      p = &procParms[i];

      // json is always in lower ( in this implementation)
      str2lower  (p->name , p->name);

      if (p->mode == SQL_PARAM_OUTPUT
      ||  p->mode == SQL_PARAM_INPUT_OUTPUT) {

         if (p->inLen == SQL_NULL_DATA ) {
            jx_SetNullByName (pResult , p->name);
         } else {

            switch (p->sqlType) {
               case SQL_CHAR:
               case SQL_VARCHAR:
               case SQL_TIMESTAMP:
               case SQL_DATE:
               case SQL_TIME:
               case SQL_DECIMAL:
               case SQL_NUMERIC:
                  *(p->buffer + p->bufLen) = '\0'; // Always keep an final zertermination at the end of buffer
                  // Pollyfill for BOOLEAN pre 7.5
                  if (p->isBool) {
                     jx_SetValueByName(pResult , p->name,  (*p->buffer == '1' || *p->buffer == 't') ? "true":"false", LITERAL);
                  } else {
                     jx_SetValueByName(pResult , p->name,  p->buffer , p->type);
                  }
                  break;
               case SQL_SMALLINT:
                  sprintf(temp, "%hd" , * (SHORT *) p->buffer);
                  jx_SetValueByName(pResult , p->name,  temp , p->type);
                  break;
               case SQL_INTEGER:
                  sprintf(temp, "%ld" , * (LONG *) p->buffer);
                  jx_SetValueByName(pResult , p->name,  temp , p->type);
                  break;
               case SQL_BIGINT:
                  sprintf(temp, "%lld" , * (INT64*) p->buffer);
                  jx_SetValueByName(pResult , p->name,  temp , p->type);
                  break;
               case SQL_REAL:
                  sprintf(temp, "%.5f" , * (float *) p->buffer);
                  strreplacechar(temp ,',', '.'); // locale safty
                  jx_SetValueByName(pResult , p->name,  temp , p->type);
                  break;
               case SQL_DOUBLE:
                  sprintf(temp, "%.10f" , * (double *) p->buffer);
                  strreplacechar(temp ,',', '.'); // locale safty
                  jx_SetValueByName(pResult , p->name,  temp , p->type);
                  break;
            }
         }
      }
   }

   jx_sqlClose (&pSQL);
   jx_NodeDelete (pProcMeta);

   return (pResult);

}

/* ------------------------------------------------------------- */
// Note: This will replace the jx_sqlCall when ready
/* ------------------------------------------------------------- */
PJXNODE jx_sqlExecuteRoutine( PUCHAR routineName , PJXNODE pInParmsP , LONG formatP, LGL specificP)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PJXNODE pInParms = (pParms->OpDescList->NbrOfParms >= 2) ? pInParmsP  : NULL;
   LONG    format  = (pParms->OpDescList->NbrOfParms >= 3) ? formatP  : 0;  // Default: Arrray only
   BOOL    specific = (pParms->OpDescList->NbrOfParms >= 4) ? (specificP == ON)  : FALSE;
   PJXNODE pResult = NULL;
   UCHAR   stmtBuf [32760];
   PUCHAR  stmt =stmtBuf;
   PJXNODE pNode;
   PUCHAR  name;
   UCHAR   temp [256];
   PUCHAR  comma = "";
   PJXSQL  pSQL;
   int     rc;
   int     outCol;
   int     noi;
   SQLSMALLINT i;
   LONG    bufLen ;
   int     impl;
   SQLRETURN    sqlRet;
   SQLSMALLINT  fCtype;
   SQLSMALLINT  fSQLtype;
   UCHAR      buffer  [650000];
   PUCHAR     bufferPos = buffer;
   int        numerOfParms = 0;
   PJXNODE    pRoutineMeta = specific ? jx_sqlSpecificRoutineMeta (routineName) : jx_sqlRoutineMeta (routineName);
   PROCPARM   procParms   [NOXDB_MAX_PARMS];
   PPROCPARM  p;

   JX_ROUTINE_TYPE type ;
   LONG       resultSets;


   pNode    =  jx_GetNodeChild (pRoutineMeta);

   if (pNode == NULL) {
      sprintf( jxMessage , "Routine %s is not found or not called qualified" , routineName);
      jxError = true;
      if (format & JX_GRACEFUL_ERROR) {
         return sqlErrorObject(routineName);
      } else {
         return NULL;
      }
   }

   noi  = atoi (jx_GetValuePtr (pNode , "number_of_implementations" , "0"));
   if (noi > 1 ) {
      sprintf( jxMessage , "Routine %s is polymorphic with %d implementations, can not deside which to use" , routineName, noi);
      jx_NodeDelete ( pRoutineMeta);
      jxError = true;
      if (format & JX_GRACEFUL_ERROR) {
         return sqlErrorObject(routineName);
      } else {
         return NULL;
      }
   }
   type = *jx_GetValuePtr    (pNode , "type" , "");
   resultSets = atoi (jx_GetValuePtr (pNode , "max_dynamic_result_sets" , "0"));

   // Can not call specific names, so we re-map the name :
   if (specific) {
      sprintf ( routineName , "%s.%s" ,
         jx_GetValuePtr (pNode ,  "routine_schema" , ""),
         jx_GetValuePtr (pNode ,  "routine_name"   , "")
      );
   }

   if (type == JX_ROUTINE_PROCEDURE
   &&  0 == resultSets ) {
      stmt += sprintf (stmt , "call %s (" , routineName );
   } else {


      switch (type) {
         case	JX_ROUTINE_PROCEDURE :
            stmt += sprintf (stmt , "call %s (" , routineName );
            break;
         case	JX_ROUTINE_SCALAR    :
            stmt += sprintf (stmt , "values %s (" , routineName );
            break;
         case	JX_ROUTINE_TABLE     :
            stmt += sprintf (stmt , "select * from table ( %s (" , routineName );
            break;
      }

      pNode    =  jx_GetNodeChild (pRoutineMeta);
      for (i=0; pNode; i++) {
         UCHAR tempName [256];
         p = &procParms[i];
         p->name = jx_GetValuePtr    (pNode , "parameter_name" , "");
         if (format & (JX_CAMEL_CASE)) {
            camelCase(tempName , p->name);
         } else {
            strcpy(tempName, p->name);
         }


         p->mode = text2parmtype (jx_GetValuePtr    (pNode , "parameter_mode" , ""));
         p->sqlType  = textType2SQLtype (jx_GetValuePtr (pNode , "data_type" , ""), p->name);

         if ((p->mode == SQL_PARAM_INPUT && NULL == jx_GetNode  (pInParms, tempName))
         ||  (p->mode == SQL_PARAM_OUTPUT)) {
            // Omit it from parmist, reuse this slot for next parameter
            i --;
         } else {
            if (*p->name > ' ') {
               stmt += sprintf (stmt , "%s%s=>"  , comma , p->name);
            }
            //if (ON ==  jx_IsLiteral (pNode ) ) {
            //   stmt += sprintf (stmt , "%s" , jx_GetValuePtr(pInParms , tempName , "0"));
            //} else {
               stmt += sprintf (stmt , "'%s'" , jx_GetValuePtr(pInParms , tempName , ""));
            //}
            comma = ",";
            numerOfParms = i+1;
            p->pNode = pNode;
         }
         pNode = jx_GetNodeNext(pNode);
      }

      switch (type) {
         case	JX_ROUTINE_PROCEDURE :
         case	JX_ROUTINE_SCALAR    :
            stmt += sprintf (stmt , ")" );
            break;
         case	JX_ROUTINE_TABLE     :
            stmt += sprintf (stmt , "))" );
            break;
      }

      if  (type ==  JX_ROUTINE_SCALAR ) {
         PJXNODE pTemp = jx_sqlResultSet(stmtBuf, 0 , -1 , format , NULL);
         PJXNODE pValue = jx_GetNodeChild(jx_GetNodeChild (jx_GetNode  (pTemp, rootName)));
         if  (pValue && jxError == false) {
            pResult = jx_NewObject(NULL);
            jx_NodeMoveInto (pResult , rootName , pValue);
            jx_SetBoolByName(pResult , "success" , ON,OFF);
            jx_NodeDelete (pTemp);
            return pResult;
         } else {
            return pTemp;
         }
      } else {
         return jx_sqlResultSet(stmtBuf, 0 , -1 , format , NULL);
      }

   }

   impl = atoi (jx_GetValuePtr (pNode , "number_of_implementations" , "0"));
   if (impl > 1) {
      sprintf( jxMessage , "Procedure %s has %d implementations. Can not decide which to use" , routineName, impl);
      jxError = true;
      jx_NodeDelete (pRoutineMeta);
      if (format & JX_GRACEFUL_ERROR) {
         return sqlErrorObject(stmtBuf);
      } else {
         return NULL;
      }
   }

   pNode    =  jx_GetNodeChild (pRoutineMeta);
   for (i=0; pNode; i++) {
      p = &procParms[i];
      p->name = jx_GetValuePtr    (pNode , "parameter_name" , "");
      p->mode = text2parmtype (jx_GetValuePtr    (pNode , "parameter_mode" , ""));
      p->sqlType  = textType2SQLtype (jx_GetValuePtr (pNode , "data_type" , ""), p->name);

      if (p->mode == SQL_PARAM_INPUT
      && NULL == jx_GetNode  (pInParms, p->name)) {
         // Omit it from parmist, reuse this slot for next parameter
         i --;
      } else {
         stmt += sprintf (stmt , "%s%s=>?"  , comma , p->name);
         comma = ",";
         numerOfParms = i+1;
         p->pNode = pNode;
         p->pData = jx_GetValuePtr(pInParms , p->name ,null);
      }
      pNode = jx_GetNodeNext(pNode);
   }
   stmt += sprintf (stmt , ")" );

   pSQL = jx_sqlNewStatement (NULL, true, false);
   rc  = SQLPrepare( pSQL->pstmt->hstmt, stmtBuf, SQL_NTS );

   for (i=0; i < numerOfParms ; i++) {
      int nullterm = 0;
      p = &procParms[i];

      p->buffer = bufferPos;
      p->type = 0 == atoi (jx_GetValuePtr (p->pNode , "numeric_precision" , "0")) ? VALUE:LITERAL;

      switch (p->sqlType ) {
         case SQL_CHAR:
         case SQL_VARCHAR:
         case SQL_TIMESTAMP:
         case SQL_DATE:
         case SQL_TIME:
         case SQL_DECIMAL:
         case SQL_NUMERIC:
         case NOXDB_UNKNOWN_SQL_DATATYPE:
            fCtype = SQL_C_CHAR;
            p->inLen   = currentLength (p, p->pData ? strlen(p->pData):0);
            p->bufLen  = atol (jx_GetValuePtr   (p->pNode , "buffer_length" , "0"));
            if ( p->inLen != SQL_NULL_DATA ) {
               if (p->inLen > p->bufLen) p->inLen = p->bufLen;
               substr( p->buffer , p->pData , p->inLen);
            }
            *(p->buffer + p->bufLen) = '\0'; // Always keep an final zertermination at the end of buffer
            nullterm = 1 ; // Keep the zerotermination in the buffer;
            break;
         case SQL_SMALLINT:
            fCtype = SQL_C_SHORT;
            p->inLen  = currentLength (p, p->pData ? sizeof(SHORT):0);
            p->bufLen = sizeof(SHORT);
            if (p->pData) * (SHORT *) p->buffer = atoi(p->pData);
            break;
         case SQL_INTEGER:
            fCtype = SQL_C_LONG;
            p->inLen  = currentLength (p, p->pData ? sizeof(LONG):0);
            p->bufLen = sizeof(LONG);
            if (p->pData)  * (LONG *) p->buffer = atol(p->pData);
            break;
         case SQL_BIGINT:
            fCtype = SQL_C_BIGINT;
            p->inLen  = currentLength (p, p->pData ? sizeof(INT64):0);
            p->bufLen = sizeof(INT64);
            if (p->pData)  * (INT64 *) p->buffer = atoll(p->pData);
            break;
         case SQL_REAL:
            fCtype = SQL_C_FLOAT;
            p->inLen  = currentLength (p, p->pData ? sizeof(float):0);
            p->bufLen = sizeof(float);
            if (p->pData)  * (float *) p->buffer = atof(p->pData);
            break;
         case SQL_DOUBLE:
            fCtype = SQL_C_DOUBLE;
            p->inLen  = currentLength (p, p->pData ? sizeof(double):0);
            p->bufLen = sizeof(double);
            if (p->pData)  * (double  *) p->buffer = atof(p->pData);
            break;
      }


      rc  = SQLBindParameter (
         pSQL->pstmt->hstmt,  // hstmt
         i + 1,            // Parm number
         p->mode,          // fParamType
         fCtype ,          // data type here in C
         p->sqlType,       // dtatype in SQL
         p->bufLen,        // precision / Length of the C - string
         0,
         p->buffer,        // buffer ,
         0,                // cbValueMax
         &p->inLen         // Buffer length  or indPtr // was:  &outLen              // pcbValue
      );

      // Setup next;
      bufferPos += p->bufLen + nullterm;
   }

   rc = SQLExecute(pSQL->pstmt->hstmt);
   if (rc != SQL_SUCCESS &&  rc != SQL_SUCCESS_WITH_INFO) {
      // jx_sqlGetDiagnostics ();
      // getSqlCode(pSQL->pstmt->hstmt);
      check_error (pSQL);
      jxError = true;
      jx_NodeDelete (pRoutineMeta);
      if (format & JX_GRACEFUL_ERROR) {
         return sqlErrorObject(stmtBuf);
      } else {
         return NULL;
      }
   }

   pResult = jx_NewObject(NULL);

   for (i = 0 ; i < numerOfParms  ; i ++) {
      p = &procParms[i];

      // json is always in lower ( in this implementation)
      if (format & (JX_CAMEL_CASE)) {
         camelCase(p->name , p->name);
      } else {
         str2lower (p->name , p->name);
      }

      if (p->mode == SQL_PARAM_OUTPUT
      ||  p->mode == SQL_PARAM_INPUT_OUTPUT) {

         if (p->inLen == SQL_NULL_DATA ) {
            jx_SetNullByName (pResult , p->name);
         } else {

            switch (p->sqlType) {
               case SQL_CHAR:
               case SQL_VARCHAR:
               case SQL_TIMESTAMP:
               case SQL_DATE:
               case SQL_TIME:
               case SQL_DECIMAL:
               case SQL_NUMERIC:
                  *(p->buffer + p->bufLen) = '\0'; // Always keep an final zertermination at the end of buffer
                  jx_SetValueByName(pResult , p->name,  p->buffer , p->type);
                  break;
               case SQL_SMALLINT:
                  sprintf(temp, "%hd" , * (SHORT *) p->buffer);
                  jx_SetValueByName(pResult , p->name,  temp , p->type);
                  break;
               case SQL_INTEGER:
                  sprintf(temp, "%ld" , * (LONG *) p->buffer);
                  jx_SetValueByName(pResult , p->name,  temp , p->type);
                  break;
               case SQL_BIGINT:
                  sprintf(temp, "%lld" , * (INT64*) p->buffer);
                  jx_SetValueByName(pResult , p->name,  temp , p->type);
                  break;
               case SQL_REAL:
                  sprintf(temp, "%.5f" , * (float *) p->buffer);
                  strreplacechar(temp ,',', '.'); // locale safty
                  jx_SetValueByName(pResult , p->name,  temp , p->type);
                  break;
               case SQL_DOUBLE:
                  sprintf(temp, "%.10f" , * (double *) p->buffer);
                  strreplacechar(temp ,',', '.'); // locale safty
                  jx_SetValueByName(pResult , p->name,  temp , p->type);
                  break;
            }
         }
      }
   }

   jx_sqlClose (&pSQL);
   jx_NodeDelete (pRoutineMeta);

   if (format & JX_GRACEFUL_ERROR) {
      PJXNODE  pEnvelope = jx_NewObject (NULL);
      jx_SetBoolByName (pEnvelope , "success" , true , OFF);
      jx_NodeMoveInto(pEnvelope , rootName , pResult);
      return pEnvelope;
   } else {
      return (pResult);
   }

}


//////////////////////


/* ------------------------------------------------------------- */
// Note: Only works on qualified procedure calls
/* ------------------------------------------------------------- */
LGL jx_sqlCallNode ( PUCHAR procedureName , ... )
{
   va_list vl;
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   UCHAR   stmtBuf [32760];
   PUCHAR  stmt =stmtBuf;
   PUCHAR  comma = "";
   PJXSQL  pSQL;
   int     rc;
   int     i, pIx;
   SQLSMALLINT  fCtype;
   SQLSMALLINT  fSQLtype;

   INT64       buffer [10];
   SQLINTEGER  inLen  [10] ;

   stmt += sprintf (stmt , "call %s (" , procedureName );
   for (i=1; i <  pParms->OpDescList->NbrOfParms; i++) {
      stmt += sprintf (stmt , "%s?" , comma);
      comma = ",";
   }
   stmt += sprintf (stmt , ")" );

   pSQL = jx_sqlNewStatement (NULL, true, false);

   rc  = SQLPrepare( pSQL->pstmt->hstmt, stmtBuf, SQL_NTS );

   if (rc != SQL_SUCCESS &&  rc != SQL_SUCCESS_WITH_INFO) {
      check_error (pSQL);
      jxError = true;
      return ON;
   }

   va_start(vl,procedureName);
   for (i=1, pIx=0; i <  pParms->OpDescList->NbrOfParms; i++, pIx++) {

      inLen[pIx]  = sizeof(INT64);
      buffer[pIx] = jx_cvtNodePtr2Offset ( (PJXNODE ) va_arg(vl,PJXNODE) );

      rc  = SQLBindParameter (
         pSQL->pstmt->hstmt,  // hstmt
         i,                   // Parm number
         SQL_PARAM_INPUT,     // fParamType
         SQL_BIGINT,          // data type here in C
         SQL_BIGINT,          // dtatype in SQL
         sizeof(INT64),       // precision / Length of the C - string
         0,
         &buffer[pIx],        // buffer ,
         0,                   // cbValueMax
         &inLen [pIx]         // Buffer length  or indPtr // was:  &outLen              // pcbValue
      );
   }
   va_end(vl);

   rc = SQLExecute(pSQL->pstmt->hstmt);
   if (rc != SQL_SUCCESS &&  rc != SQL_SUCCESS_WITH_INFO) {
      check_error (pSQL);
      jxError = true;
      return ON;
   }

   jx_sqlClose (&pSQL);

   return OFF;

}

/* ------------------------------------------------------------- */
// Note: Only works on qualified procedure calls
/* ------------------------------------------------------------- */
/*
PJXNODE jx_sqlCall ( PUCHAR procedureName , PJXNODE pInParms)
{
   PJXNODE pResult = NULL;
   UCHAR   stmtBuf [32760];
   PUCHAR  stmt =stmtBuf;
   PJXNODE pNode;
   PUCHAR  name;
   UCHAR   temp [256];
   PUCHAR  comma = "";
   PJXSQL  pSQL;
   int     rc;
   int     outCol;
   int     i;
   int     bufLen ;
   int     impl;
   SQLSMALLINT     col;
   SQLSMALLINT   fCType;

   UCHAR      out  [650000];
   PUCHAR     outPos = out;
   SQLINTEGER outParmLen  [4096];
   PUCHAR     outParmBuf  [4096];
   PUCHAR     name [4096];
   SHORT      type [4096];
   int        i =0;

   SQLRETURN sqlRet;
   PUCHAR  mode;
   PUCHAR  parmName;
   PJXNODE pProcMeta = jx_sqlProcedureMeta (procedureName);

   if (pProcMeta == NULL) {
      sprintf( jxMessage , "Procedure %s is not found or not called qualified" , procedureName);
      jxError = true;
      return NULL;
   }
   pNode    =  jx_GetNodeChild (pProcMeta);
   impl = atoi (jx_GetValuePtr (pNode , "number_of_implementations" , "0"));

   if (impl > 1) {
      sprintf( jxMessage , "Procedure %s has %d implementations. Can not decide which to use" , procedureName, impl);
      jxError = true;
      jx_NodeDelete (pProcMeta);
      return NULL;
   }

   stmt += sprintf (stmt , "call %s (" , procedureName );

   pNode    =  jx_GetNodeChild (pInParms);
   while (pNode) {
      PUCHAR val;
      name  = jx_GetNodeNamePtr   (pNode);
      str2upper (temp  , name);   // Needed for national charse in columns names i.e.: BEL�B
      val = jx_GetValuePtr(pNode , "" ,null);
      if (val == null) {
         stmt += sprintf (stmt , "%s%s=>null"  , comma , temp);
      } else {
         stmt += sprintf (stmt , "%s%s=>?"  , comma , temp);
      }
      comma = ",";
      pNode = jx_GetNodeNext(pNode);
   }

   pNode    =  jx_GetNodeChild (pProcMeta);
   while (pNode) {
      mode = jx_GetValuePtr    (pNode , "parameter_mode" , "");
      if (0 == strcmp (mode , "OUT")
      ||  0 == strcmp (mode , "INOUT")) {
         parmName = jx_GetValuePtr    (pNode , "parameter_name" , "");
         stmt += sprintf (stmt , "%s%s=>?"  , comma , parmName);

         // Build output buffer list. Get room for zero termination
         name [outParmsCnt] = parmName;
         outParmBuf  [outParmsCnt] = outPos;
         bufLen = atoi (jx_GetValuePtr   (pNode , "buffer_length" , "0"));
         outParmLen  [outParmsCnt] = bufLen;
         type [outParmsCnt] = 0 == atoi (jx_GetValuePtr (pNode , "numeric_precision" , "0")) ? VALUE:LITERAL;
         outParmsCnt ++;
         *(outPos + bufLen) = '\0';  // Ensure each is zero terminated
         outPos += bufLen + 1;
         comma = ",";
      }
      pNode = jx_GetNodeNext(pNode);
   }
   stmt += sprintf (stmt , ")" );

   pSQL = jx_sqlNewStatement (NULL, true, false);
   rc  = SQLPrepare( pSQL->pstmt->hstmt, stmtBuf, SQL_NTS );


   // bind input parameters:
   pNode    =  jx_GetNodeChild (pInParms);
   col = 1;
   while (pNode) {
      / *
      SQLSMALLINT fCType = SQL_C_CHAR;
      PUCHAR pData = jx_GetValuePtr(pNode , "" ,null);
      SQLINTEGER len;
      SQLINTEGER scale =0;
      SQLINTEGER outLen;

      if (pData == null) {
         pData = "";
         len =  1;
         outLen = SQL_NULL_DATA;
      } else {
         len = strlen(pData);
         outLen = SQL_NTS; // was outLen = len;
      }
      * /
      PUCHAR  val = jx_GetValuePtr(pNode , "" ,null);
      if (val == null) {
      } else {
         SQLSMALLINT fCType = SQL_C_CHAR;
         PUCHAR pData = val;
         SQLINTEGER len = strlen(pData);
         SQLINTEGER scale =0;
         SQLINTEGER outLen = 0;

         rc  = SQLBindParameter (
            pSQL->pstmt->hstmt, // hstmt
            col ++ ,
            SQL_PARAM_INPUT,    // fParamType
            fCType, //  SQL_C_DEFAULT,       // wasfCType ,            // data type here in C
            fCType,             // dtatype in SQL
            len ,               // precision / Length of the C - string
            scale,              // scale  /// 0,                // ibScale
            pData,              // rgbValue - store the complete node. Here SQL RPC are very flexible - any pointer
            0,                  // cbValueMax ( not used)
            &outLen             // pcbValue
         );
      }

      pNode = jx_GetNodeNext(pNode);
   }

   // bind output  parameters:
   for (outCol = 0 ; outCol < outParmsCnt ; outCol ++) {
      SQLINTEGER outLen = 0;

      rc  = SQLBindParameter (
         pSQL->pstmt->hstmt,  // hstmt
         col ++,
         SQL_PARAM_OUTPUT,    // fParamType
         SQL_C_CHAR,          // data type here in C
         SQL_C_CHAR,          // dtatype in SQL
         outParmLen[outCol],  // precision / Length of the C - string
         0,                  //scale,
         outParmBuf[outCol],   // rgbValue - store the complete node. Here SQL RPC are very flexible - any pointer
         0,                   // cbValueMax
         &outParmLen[outCol]  // Strlen or indPtr // was:  &outLen              // pcbValue
      );

   }

   rc = SQLExecute(pSQL->pstmt->hstmt);
   if (rc != SQL_SUCCESS) {
      check_error (pSQL);
      jxError = true;
      jx_NodeDelete (pProcMeta);
      return NULL;
   }

   pResult = jx_NewObject(NULL);

   for (outCol = 0 ; outCol < outParmsCnt ; outCol ++) {
      jx_SetValueByName(pResult , name[outCol],  outParmBuf[outCol] , type[outCol]);
   }

   jx_sqlClose (&pSQL);
   jx_NodeDelete (pProcMeta);

   return (pResult);

}*/

// Additional data descibing the error can optionally
// be set and found in the envvar MESSAGES_LIST
/* ------------------------------------------------------------- */
void static messageList (PJXNODE pError) {
   PUCHAR message;
   message = getenv ("MESSAGES_LIST");
   if (message && *message > ' ') {
      jx_SetEvalByName ( pError , "messages", message);
      putenv("MESSAGES_LIST=");
   }
}
/* ------------------------------------------------------------- */
PJXNODE static sqlErrorObject(PUCHAR sqlstmt)
{
   PJXNODE pError = jx_NewObject(NULL);
   jx_SetBoolByName (pError , "success" ,  OFF, OFF);
   jx_SetStrByName  (pError , "msg"     ,  jxMessage,OFF);
   jx_SetStrByName  (pError , "stmt"    ,  sqlstmt, OFF);
   messageList (pError);

   return pError;
}
/* ------------------------------------------------------------- */
PJXNODE jx_sqlResultSet( PUCHAR sqlstmt, LONG startP, LONG limitP, LONG formatP , PJXNODE pSqlParmsP  )
{

   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   LONG    start     = (pParms->OpDescList->NbrOfParms >= 2) ? startP     : NOXDB_FIRST_ROW; // From first row
   LONG    limit     = (pParms->OpDescList->NbrOfParms >= 3) ? limitP     : NOXDB_ALL_ROWS; // All row
   LONG    format    = (pParms->OpDescList->NbrOfParms >= 4) ? formatP    : 0;  // Arrray only
   PJXNODE pSqlParms = (pParms->OpDescList->NbrOfParms >= 5) ? pSqlParmsP : NULL;
   PJXNODE pRows     ;
   PJXNODE pRow      ;
   PJXNODE pResult;
   PJXSQL  pSQL;
   LONG    i, rc;
   LONG rowCount=0;
   SHORT strLen=0;

   start = start < 1 ? 1 : start;

   pSQL = jx_sqlOpen(sqlstmt , pSqlParms, format , start , limit );
   if ( pSQL == NULL) {
      if (format & JX_GRACEFUL_ERROR) {
         return sqlErrorObject(sqlstmt);
      } else {
        return NULL;
      }
   }

   pRows = jx_NewArray(NULL);
   pRow  = jx_sqlFetchNext (pSQL);
   for (rowCount = 1; pRow && (rowCount <=limit || limit == -1); rowCount ++) {
      jx_ArrayPush (pRows , pRow, FALSE);
      pRow  = jx_sqlFetchNext (pSQL);
   }
   if ( (pSQL->rc != SQL_NO_DATA_FOUND) && (format & JX_GRACEFUL_ERROR) ) {
      jx_NodeDelete (pRows);
      jx_sqlClose (&pSQL);
      return sqlErrorObject(sqlstmt);
   }

   // need a object as return value
   if (format & (JX_META | JX_FIELDS | JX_TOTALROWS | JX_APROXIMATE_TOTALROWS)) {
      PJXNODE pMeta;
      pResult  = jx_NewObject(NULL);
      pMeta    = jx_NewObject(NULL);
      jx_SetValueByName(pResult  , "success" , "true" , LITERAL);
      jx_SetValueByName(pResult , "root"    , rootName , VALUE);
      if (format & JX_FIELDS ) {
         PJXNODE pFields = jx_buildMetaFields (pSQL);
         jx_NodeMoveInto(pMeta , "fields" , pFields);
      }
      if (format & (JX_TOTALROWS | JX_APROXIMATE_TOTALROWS)) {
         jx_SetValueByName(pMeta , "totalProperty"   , "totalRows" , VALUE);

         if (format & JX_APROXIMATE_TOTALROWS ) {
            if (pRow) { // Yet more rows to come
              pSQL->rowcount = start + limit;
            } else {
              pSQL->rowcount = start + rowCount - 2; // "start" and "rowCount" count has both 1 as option base)
            }
         } else {
            pSQL->rowcount = jx_sqlNumberOfRows(sqlstmt);
         }
         jx_SetIntByName(pResult , "totalRows" , pSQL->rowcount , OFF);

         //SQLGetDiagField(SQL_HANDLE_STMT,
         //    pSQL->pstmt->hstmt,0,DB2_NUMBER_ROWS,&rowCount,SQL_INTEGER,&strLen);


         // SQL_INTEGER
         //rc=SQLGetDiagField(SQL_HANDLE_STMT,pSQL->pstmt->hstmt, 0 ,SQL_DIAG_ROW_COUNT,&rowCount,SQL_INTEGER,&strLen);
         // pSQL->rowcount = rowCount;

      }

      jx_NodeMoveInto (pResult , "metaData" , pMeta);
      jx_NodeMoveInto (pResult , rootName    , pRows);

   } else {

      // simply return the array of rows
      pResult = pRows;
   }

   jx_sqlClose (&pSQL);
   return pResult;

}
/* ------------------------------------------------------------- */
PJXNODE jx_sqlResultRowAt ( PUCHAR sqlstmt, LONG startP, PJXNODE pSqlParmsP , LONG formatP)
{

   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   LONG    start     = (pParms->OpDescList->NbrOfParms >= 2) ? startP     : NOXDB_FIRST_ROW;  // From first row
   PJXNODE pSqlParms = (pParms->OpDescList->NbrOfParms >= 3) ? pSqlParmsP : NULL;
   LONG    format    = (pParms->OpDescList->NbrOfParms >= 4) ? formatP    : 0;
   PJXNODE pRow;
   PJXSQL  pSQL;

   pSQL = jx_sqlOpen(sqlstmt , pSqlParms, format , start , 1 );
   if ( pSQL == NULL) {
      if (format & JX_GRACEFUL_ERROR) {
         return sqlErrorObject(sqlstmt);
      } else {
        return NULL;
      }
   }

   pRow  = jx_sqlFetchNext (pSQL);
   jx_sqlClose (&pSQL);
   return pRow;

}
/* ------------------------------------------------------------- */
PJXNODE jx_sqlGetMeta (PUCHAR sqlstmt , LONG formatP)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   LONG    format    = (pParms->OpDescList->NbrOfParms >= 2) ? formatP : 0;
   int i;
   PJXSQL  pSQL  = jx_sqlOpen(sqlstmt , NULL, format, NOXDB_FIRST_ROW, NOXDB_ALL_ROWS );
   PJXNODE pMeta = jx_buildMetaFields ( pSQL );
   jx_sqlClose (&pSQL);
   return pMeta;
}
/* ------------------------------------------------------------- */
PJXNODE jx_sqlResultRow ( PUCHAR sqlstmt, PJXNODE pSqlParmsP , LONG formatP)
{

   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PJXNODE pSqlParms = (pParms->OpDescList->NbrOfParms >= 2) ? pSqlParmsP : NULL;
   LONG    format    = (pParms->OpDescList->NbrOfParms >= 3) ? formatP : 0;
   PJXNODE pRow;
   PJXSQL  pSQL;

   pSQL = jx_sqlOpen(sqlstmt , pSqlParms, format , NOXDB_FIRST_ROW, 1 );
   if ( pSQL == NULL) {
      if (format & JX_GRACEFUL_ERROR) {
         return sqlErrorObject(sqlstmt);
      } else {
        return NULL;
      }
   }

   pRow  = jx_sqlFetchNext (pSQL);
   jx_sqlClose (&pSQL);
   return pRow;

}
/* ------------------------------------------------------------- */
LGL jx_sqlExec(PUCHAR sqlstmt , PJXNODE pSqlParms)
{

   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   LONG   attrParm;
   LONG   i;
   int rc;
   //   PJXSQL pSQL = jx_sqlNewStatement (pParms->OpDescList->NbrOfParms >= 2 ? pSqlParms  :NULL);
   PJXSQL pSQL = jx_sqlNewStatement (NULL, true , false);

   // run  the  statement in "sqlstr"
   if (pParms->OpDescList->NbrOfParms >= 2) {
      UCHAR sqlTempStmt[32766];
      strFormat(sqlTempStmt , sqlstmt , pSqlParms);
      rc = jx_sqlExecDirectTrace(pSQL , pSQL->pstmt->hstmt, sqlTempStmt);
   } else {
      rc = jx_sqlExecDirectTrace(pSQL , pSQL->pstmt->hstmt, sqlstmt);
   }
   jx_sqlClose (&pSQL);
   return (rc == SQL_SUCCESS || rc == SQL_SUCCESS_WITH_INFO) ? OFF: ON;
}
/* ------------------------------------------------------------- */
/* .........
int getColType(SQLHSTMT hstmt , SHORT col )
{
   JXCOL Col;

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
/* does not  work !! */
static BOOL isIdColumn(SQLHSTMT hstmt , int colno)
{
   int rc;
   SQLINTEGER isTrue;

   // is it an ID column ? get the label, if no label then use the column name
   isTrue = SQL_FALSE;
   rc = SQLColAttributes (hstmt, colno,SQL_DESC_AUTO_INCREMENT, NULL, 0, NULL ,&isTrue);
   // rc = SQLColAttributes (hstmt, colno,SQL_DESC_UPDATABLE, NULL, 0, NULL ,&isTrue);
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
static BOOL  nodeisnull(PJXNODE pNode)
{
   PUCHAR val;

   if (pNode == NULL) return true;

   // has always a content ...
   if (pNode->type == ARRAY ||  pNode->type == OBJECT) {
      // .. so this will fail
      // pNode =  jx_GetNodeChild (pNode);
      // if (pNode != NULL) return false;
      return false;
   }

   val = jx_GetNodeValuePtr (pNode , NULL);
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
static BOOL  nodeisblank(PJXNODE pNode)
{
   PUCHAR val;

   if (pNode == NULL) return true;

   // has always a content ...
   if (pNode->type == ARRAY ||  pNode->type == OBJECT) {
      // .. so this will fail
      // pNode =  jx_GetNodeChild (pNode);
      // if (pNode != NULL) return false;
      return false;
   }

   if (pNode->isLiteral) return false;
   val = jx_GetNodeValuePtr (pNode , null);
   if (val == null) return false;
   if (*val == 0) return true;
   return false;
}
/* ------------------------------------------------------------- */
static void buildUpdate (SQLHSTMT hstmt, SQLHSTMT hMetastmt,
   PUCHAR sqlStmt, PUCHAR table, PJXNODE pSqlParms , PUCHAR where)
{
   PUCHAR  stmt = sqlStmt;
   PUCHAR  comma = "";
   PJXNODE pNode;
   PUCHAR  name;
   int     colno;
   UCHAR   temp [128];

   stmt += sprintf (stmt , "update %s set " , table);

   pNode    =  jx_GetNodeChild (pSqlParms);
   for ( colno=1; pNode; colno++) {
      if (! isIdColumn(hMetastmt, colno)) {
         name  = jx_GetNodeNamePtr   (pNode);
         str2upper (temp  , name);   // Needed for national charse in columns names i.e.: BEL�B
         if  (nodeisnull(pNode)) {
            stmt += sprintf (stmt , "%s%s=NULL" , comma , temp);
         } else if  (nodeisblank(pNode)) {
            stmt += sprintf (stmt , "%s%s=default" , comma , temp);    // because timesstamp / date can be set as ''
         } else {
            stmt += sprintf (stmt , "%s%s=?"  , comma , temp);
         }
         comma = ",";
      }
      pNode = jx_GetNodeNext(pNode);
   }

   stmt += sprintf (stmt , " %s " , where);
}
/* ------------------------------------------------------------- */
static void buildInsert  (SQLHSTMT hstmt, SQLHSTMT hMetaStmt,
   PUCHAR sqlStmt, PUCHAR table, PJXNODE pSqlParms , PUCHAR where)
{
   PUCHAR  stmt = sqlStmt;
   PUCHAR  comma = "";
   PJXNODE pNode;
   PUCHAR  name;
   PUCHAR  value;
   int     i,colno;
   UCHAR   markers[4096] ;
   UCHAR   temp [128];
   PUCHAR  pMarker = markers;

   stmt += sprintf (stmt , "insert into  %s (" , table);

   pNode = jx_GetNodeChild (pSqlParms);
   for ( colno=1; pNode; colno++) {
      if (! isIdColumn(hMetaStmt, colno)) {
         if (!nodeisnull(pNode)) {
            name     = jx_GetNodeNamePtr   (pNode);
            str2upper (temp  , name);   // Needed for national charse in columns names i.e.: BEL�B
            stmt    += sprintf (stmt , "%s%s" , comma , temp);
            if  (nodeisblank(pNode)) {
               pMarker+= sprintf (pMarker , "%sdefault" , comma);    // because timesstamp / date can be set as ''
            } else {
               pMarker+= sprintf (pMarker , "%s?" , comma);
            }
            comma = ",";
         }
      }
      pNode = jx_GetNodeNext(pNode);
   }

   stmt += sprintf (stmt , ") values( ");
   stmt += sprintf (stmt , markers);
   stmt += sprintf (stmt , ")") ;
}
/* ------------------------------------------------------------- */
void createTracetable(PJXSQLCONNECT pCon)
{
   PJXTRACE pTrc = &pCon->sqlTrace;
   UCHAR  t [512];
   PUCHAR s = "CREATE            TABLE %s/sqlTrace (       "
       "   STSTART TIMESTAMP NOT NULL WITH DEFAULT,        "
       "   STEND TIMESTAMP NOT NULL WITH DEFAULT,          "
       "   STSQLSTATE CHAR(5) NOT NULL WITH DEFAULT,         "
       "   STTEXT VARCHAR ( 256) NOT NULL WITH DEFAULT,      "
       "   STJOB  VARCHAR ( 30) NOT NULL WITH DEFAULT,       "
       "   STTRID BIGINT NOT NULL WITH DEFAULT,              "
       "   STSQLSTMT VARCHAR ( 8192) NOT NULL WITH DEFAULT)  ";
   sprintf(t , s , pTrc->lib);
   pTrc->doTrace =  OFF; // So we don't end up in a recusive death spiral
   jx_sqlExec(t , NULL);
   pTrc->doTrace =  ON;
}
/* ------------------------------------------------------------- */
void jx_traceOpen (PJXSQLCONNECT pCon)
{
   PJXTRACE pTrc = &pCon->sqlTrace;
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
void jx_traceSetId (INT64 trid)
{
   PJXSQLCONNECT pc = jx_getCurrentConnection();
   PJXTRACE pTrc = &pc->sqlTrace;
   pTrc->trid = trid;
}
/* ------------------------------------------------------------- */
void jx_traceInsert (PJXSQL pSQL, PUCHAR stmt , PUCHAR sqlState)
{
   int rc;
   PJXTRACE pTrc = &pConnection->sqlTrace; // !!! TODO not from global !!!
   if (pTrc->doTrace == OFF) return;
   rc = SQLBindParameter(pTrc->handle,3,SQL_PARAM_INPUT,SQL_C_CHAR,SQL_CHAR    ,   5,0,sqlState,0,NULL);
   rc = SQLBindParameter(pTrc->handle,7,SQL_PARAM_INPUT,SQL_C_CHAR,SQL_VARCHAR ,8192,0,stmt,0,NULL);

   // insert row
   rc = SQLExecute(pTrc->handle);

}
// -------------------------------------------------------------
static BOOL isNumeric (SQLSMALLINT colType)
{
   switch (colType) {
      case SQL_NUMERIC:
      case SQL_DECIMAL:
      case SQL_INTEGER:
      case SQL_SMALLINT:
      case SQL_FLOAT:
      case SQL_REAL:
      case SQL_DOUBLE:
         return true;
   }
   return false;
}
// -------------------------------------------------------------
// Note this is done in ascii
#pragma convert(1252)
PUCHAR convertAndUnescapeUTF8 ( PULONG plbytes , PUCHAR value , PBOOL pfreeme)
{
   PUCHAR pIn , pOut;
   PUCHAR valout;
   ULONG newLen;
   int FromCCSID = 0;
   int ToCCSID = 1208;

   // first convert from job to UTF-8
   valout = memAlloc ( (*plbytes) * 4);
   newLen =  XlateBufferQ(valout, value , *plbytes, FromCCSID, ToCCSID);
   valout[newLen] = '\0'; // Use it as as zero term string later in this logic

   if (*pfreeme) {
      memFree(&value);
   }

   // now replace unicode escapes utf8 values
   // pickup the next four hex chars and convert it
   // Note: we can use the same overlapping buff since we are ahread while we replace
   pIn = pOut = valout;
   while (*pIn) {
      if (*pIn == '\\' && *(pIn+1) == 'u') {
         UCHAR temp [4];
         ULONG skip;
         skip = XlateBufferQ(pOut, asciihex2BinMem (temp , pIn+2 , 2)  , 2 , 1200 , 1208);
         pIn += 6; // skip the \uFFFF sequence
         pOut += skip;
      } else {
         *(pOut++) = *(pIn++);
      }
   }

   *(pOut) = '\0';
   *pfreeme = true;
   *plbytes = pOut - valout;
   return valout;

}
#pragma convert(0)
// -------------------------------------------------------------
// Quick fix - double escape \ for unicode in json  - that is not supported by IBM
PUCHAR  escapeBackSlash ( PULONG plbytes , PUCHAR value , PBOOL pfreeme)
{
   ULONG  cntback = 0;
   PUCHAR p, pIn , pOut;
   PUCHAR valout;

   for (p=value; *p ; p++) {
      if (*p == '\\') cntback ++;
   }
   if ( cntback == 0 ) return value;

   // escape is nessesary
   valout = memAlloc ( (*plbytes) +  cntback);

   pIn= value;
   pOut = valout;
   while (*pIn ) {
      if (*pIn ==  '\\') * (pOut ++) = '\\';
      * (pOut ++)  = * (pIn ++);
   }

   if (*pfreeme) {
      memFree(&value);
   }
   *pfreeme = true;
   return valout;
}

// -------------------------------------------------------------
//  supports this:
//   curl 'http://myibmi:15020/.1/ip2-services/ip2dmdProxy.aspx' -H 'Pragma: no-cache' -H 'Origin: http://localhost:3000' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: da,en-US;q=0.9,en;q=0.8,sv;q=0.7,fr;q=0.6' -H 'x-profile: 2019-04-16-09.57.15.263576/PNO/148/3' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36' -H 'Content-Type: application/json' -H 'Accept: */*' -H 'Cache-Control: no-cache' -H 'X-Requested-With: XMLHttpRequest' -H 'Cookie: sys_sesid="2019-04-16-09.57.15.263576"; ' -H 'Connection: keep-alive' -H 'Referer: http://localhost:3000/' --data-binary '{"batch":[{"type":"upsert","dmd":"dmd/pnoTest.dmd","entity":"PROPTST","transactiontype":"PROPTST","key":{"ID":1},"row":{"ID":1,"PROP":{"field_1":"123t","field_2":"123","field_3":"123","Tester_test":"123"},"PROPS":{"test":"test","tester":"test"}}}]}' --compressed
//
// Unicode escaped chars
//   curl 'http://myibmi:15020/.1/ip2-services/ip2dmdProxy.aspx' -H 'Pragma: no-cache' -H 'Origin: http://localhost:3000' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: da,en-US;q=0.9,en;q=0.8,sv;q=0.7,fr;q=0.6' -H 'x-profile: 2019-04-16-09.57.15.263576/PNO/148/3' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36' -H 'Content-Type: application/json' -H 'Accept: */*' -H 'Cache-Control: no-cache' -H 'X-Requested-With: XMLHttpRequest' -H 'Cookie: sys_sesid="2019-04-16-09.57.15.263576"; ' -H 'Connection: keep-alive' -H 'Referer: http://localhost:3000/' --data-binary '{"batch":[{"type":"upsert","dmd":"dmd/pnoTest.dmd","entity":"PROPTST","transactiontype":"PROPTST","key":{"ID":1},"row":{"ID":1,"PROP":{"field_1":"123t","field_2":"123","field_3":"123","Tester_test":"123"},"PROPS":{"test":"test","tester":"\u00f8"}}}]}' --compressed
// -------------------------------------------------------------
SHORT  doInsertOrUpdate(
   PJXSQL pSQL,
   PJXSQL pSQLmeta,
   PUCHAR sqlTempStmt,
   PUCHAR table ,
   PJXNODE pRow,
   PUCHAR where ,
   BOOL   update
)
{

   typedef struct _COLDATA {
      SQLSMALLINT coltype;
      SQLINTEGER  collen;
      SQLSMALLINT scale;
      SQLSMALLINT nullable;
      PJXNODE     pNode;
      BOOL        isUTF8;
   } COLDATA, *PCOLDATA;

   COLDATA colData[16000];
   PCOLDATA pColData;
   LONG   attrParm;
   LONG   colno;
   LONG   i;
   SQLINTEGER sql_nts;
   SQLINTEGER bindColNo;
   UCHAR dummy[1024];
   SQLPOINTER CharacterAttributePtr = dummy;
   PJXNODE pNode;
   PUCHAR name, value;
   SQLSMALLINT   length;
   SQLRETURN     rc;
   PUCHAR        sqlNullPtr = NULL;
   SQLINTEGER    data_at_exec = SQL_DATA_AT_EXEC;
   SQLSMALLINT   fCType;


   if (pSQL == NULL || pSQL->pstmt == NULL) return -1;


   // Now we have the colume definitions - now build the update statement:
   if (update) {
      buildUpdate (pSQL->pstmt->hstmt, pSQLmeta->pstmt->hstmt, sqlTempStmt , table, pRow , where);
   } else {
      buildInsert (pSQL->pstmt->hstmt, pSQLmeta->pstmt->hstmt, sqlTempStmt , table, pRow , where);
   }

   // prepare the statement that will do the update
   rc = SQLPrepare(pSQL->pstmt->hstmt , sqlTempStmt, SQL_NTS);
   if (rc  != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
      if (-109 == getSqlCode(pSQL->pstmt->hstmt)) {
         return rc; // we  have an error - so try with next...
      }
      check_error (pSQL);
      return rc; // we have an error, and die
   }


   // Take the description from the "select" and use it on the "update"
   pNode    =  jx_GetNodeChild (pRow);
   bindColNo =0;
   for(colno =1; pNode ; colno ++) {
      PCOLDATA pColData = &colData[colno-1];
      BOOL isId = isIdColumn(pSQLmeta->pstmt->hstmt, colno);

      if (!isId && !nodeisnull(pNode) && !nodeisblank(pNode)) {
         UCHAR       colName [256];
         SQLSMALLINT colNameLen;
         ULONG       ccsid;

         bindColNo ++; // Only columns with data ( not null nor blank) need to be bound
         pColData->pNode = pNode;

         rc = SQLDescribeCol (
            pSQLmeta->pstmt->hstmt,
            colno,    // The meta "cursor" contaians all columns
            colName,
            sizeof (colName),
            &colNameLen,
            &pColData->coltype,
            &pColData->collen,
            &pColData->scale,
            &pColData->nullable
         );

         if (rc != SQL_SUCCESS ) {
            check_error (pSQL);
            return rc; // we have an error
         }

         // When the table-data is in UTF-8 we can unescape unicode data and store it as real UTF-8
         rc = SQLColAttribute  (
            pSQLmeta->pstmt->hstmt,
            colno,                  // The meta "cursor" contaians all columns
            SQL_DESC_COLUMN_CCSID,
            CharacterAttributePtr , // SQLPOINTER     CharacterAttributePtr,
            0 ,                     // SQLSMALLINT    BufferLength,
            NULL ,                  // SQLSMALLINT    *StringLengthPtr,
            &ccsid                  //  ullable SQLPOINTER     NumericAttributePtr);
         );

         pColData->isUTF8 = ccsid == 1208;

         // Blob's need binary data - !!TODO check all binary types.
         if (pColData->isUTF8) {
            fCType = SQL_UTF8_CHAR;
         }  else if (pColData->coltype == SQL_BLOB) {
         //|| pColData->coltype == SQL_CLOB ) {
            fCType = SQL_C_BINARY;
         } else {
            fCType = SQL_C_CHAR;
         }

         if (pNode->type == ARRAY ||  pNode->type == OBJECT) {
            // Keep the max len (from the column) for now..
            // Data will be allocated and serilized in "NEED_DATA" section
         } else {
            pColData->collen = strlen (jx_GetNodeValuePtr  (pNode , NULL));
         }

         // Bind the parameter marker.
         rc  = SQLBindParameter (
            pSQL->pstmt->hstmt, // hstmt
            bindColNo,
            SQL_PARAM_INPUT,    // fParamType
            fCType ,            // data type here in C
            pColData->coltype,  // dtatype in SQL
            pColData->collen,   // Length of the C - string
            pColData->scale,    // presition /// 0,                // ibScale
            pColData,           // rgbValue - store the complete node. Here SQL RPC are very flexible - any pointer
            0,                  // cbValueMax
            &data_at_exec       // pcbValue
         );

         if (rc != SQL_SUCCESS ) {
            check_error (pSQL);
            return rc; // we have an error
         }

      }
      pNode = jx_GetNodeNext(pNode);
   }


   // run  the  statement in "sqlstr"
   rc = SQLExecute( pSQL->pstmt->hstmt);

   if (rc == SQL_NEED_DATA) {
      // Check to see if NEED_DATA; if yes, use SQLPutData.
      rc  = SQLParamData(pSQL->pstmt->hstmt, &pColData);
      while (rc == SQL_NEED_DATA) {
         BOOL freeme;
         LONG    cbChunk = 32000; // Dont use real 32K it will be to large a buffer
         PUCHAR  value;
         ULONG   lbytes;
         PJXNODE pNode = pColData->pNode;
         SQLSMALLINT SmallIntVal;
         SQLINTEGER intVal;
         UCHAR buf [256];


         if (pNode->type == ARRAY ||  pNode->type == OBJECT) {
            freeme = true;
            value = memAlloc(pColData->collen);
            lbytes  = jx_AsJsonTextMem (pNode , value ,  pColData->collen );
            value [lbytes] = '\0';
         } else {
            freeme = false;
            value = jx_GetNodeValuePtr  (pNode , NULL);
            lbytes = pColData->collen;
         }

         if (pColData->isUTF8) {
            value = convertAndUnescapeUTF8 (&lbytes , value , &freeme);
         }
         // value = escapeBackSlash (&lbytes , value , &freeme);

         // Put each block in in buffer
         while (lbytes > cbChunk) {
            rc = SQLPutData(pSQL->pstmt->hstmt, value , cbChunk);
            lbytes -= cbChunk;
            value  += cbChunk;
         }

         // Put final batch.
         rc = SQLPutData(pSQL->pstmt->hstmt, value, lbytes);
         if (rc != SQL_SUCCESS) {
            check_error (pSQL);
            return rc; // we have an error
         }

         // Local serialized work string
         if (freeme) {
            memFree(&value);
         }
         // Setup next column
         rc = SQLParamData(pSQL->pstmt->hstmt, &pColData );

      }
   }


   if (rc != SQL_SUCCESS && rc != SQL_NO_DATA_FOUND) {
      check_error (pSQL);
      return rc; // we have an error
   }

   return rc;

}
/* !!!!!!!!!!!!!!!!!!!!! OLD version - fails with BLOB and CLOB over 32K
SHORT  doInsertOrUpdate(
   PJXSQL pSQL,
   PJXSQL pSQLmeta,
   PUCHAR sqlTempStmt,
   PUCHAR table ,
   PJXNODE pRow,
   PUCHAR where ,
   BOOL   update,
   BOOL   override)
{

   LONG   attrParm;
   LONG   i,colno;
   PUCHAR valArr[64];
   SHORT  valArrIx= 0;
   SQLINTEGER sql_nts;

   PJXNODE pNode;
   PUCHAR comma = "";
   PUCHAR name, value;

   SQLSMALLINT   length;
   SQLRETURN     rc;
   PUCHAR        sqlNullPtr = NULL;

   if (pSQL == NULL || pSQL->pstmt == NULL) return -1;


   // Now we have the colume definitions - now build the update statement:
   if (update) {
      buildUpdate (pSQL->pstmt->hstmt, sqlTempStmt , table, pRow , where, override);
   } else {
      buildInsert (pSQL->pstmt->hstmt, sqlTempStmt , table, pRow , where, override);
   }

   // prepare the statement that will do the update
   rc = SQLPrepare(pSQL->pstmt->hstmt , sqlTempStmt, SQL_NTS);
   if (rc  != SQL_SUCCESS ) {
      if (-109 == getSqlCode(pSQL->pstmt->hstmt)) {
         return rc; // we  have an error - so try with next...
      }
      check_error (pSQL);
      return rc; // we have an error, and die
   }


   // Take the description from the "select" and use it on the "update"
   pNode    =  jx_GetNodeChild (pRow);
   colno =1;
   for(i=1; pNode ; i++) {
      int pColData->length;
      JXCOL Col;
      memset (&Col , 0 , sizeof(JXCOL));

      rc = SQLDescribeCol (
         pSQLmeta->pstmt->hstmt,
         i,
         Col.colname,
         sizeof (Col.colname),
         &Col.colnamelen,
         &Col.coltype,
         &Col.collen,
         &Col.scale,
         &Col.nullable
      );

      if (rc != SQL_SUCCESS ) {
         check_error (pSQL);
         return rc; // we have an error
      }

      if (!nodeisnull(pNode)) {

         if (pNode->type == ARRAY ||  pNode->type == OBJECT) {
            value = valArr[valArrIx++] = memAlloc(Col.collen);
            realLength = jx_AsJsonTextMem (pNode , value,  Col.collen );
            value [realLength] = '\0';
         } else {
            value = jx_GetNodeValuePtr  (pNode , NULL);
            realLength = strlen(value);
         }
         sql_nts = SQL_NTS;

         rc = SQLBindParameter(pSQL->pstmt->hstmt,
            colno++,
            SQL_PARAM_INPUT,
            SQL_C_CHAR,
            Col.coltype,
            realLength + Col.scale   , // Col.collen,   // length  !!! 1234,56 gives 6 digits
            Col.scale,    // presition
            value,
            0,
            &sql_nts // NULL -   pointer to length variable
         );
      }

      if (rc != SQL_SUCCESS ) {
         check_error (pSQL);
         return rc; // we have an error
      }

      pNode = jx_GetNodeNext(pNode);
   }


   // run  the  statement in "sqlstr"
   rc = SQLExecute( pSQL->pstmt->hstmt);

   for(i=0;i<valArrIx; i++) {
      memFree(&valArr[i]);
   }


   if (rc != SQL_SUCCESS && rc != SQL_NO_DATA_FOUND) {
      check_error (pSQL);
      return rc; // we have an error
   }

   return rc;

}
*/
/* ------------------------------------------------------------- */
static PJXSQL buildMetaStmt (PUCHAR table, PJXNODE pRow)
{
   UCHAR     sqlTempStmt[32766];
   PUCHAR    stmt = sqlTempStmt;
   PUCHAR    name;
   UCHAR     temp  [256];
   PJXNODE   pNode;
   PUCHAR    comma = "";
   SQLRETURN rc;
   PJXSQL    pSQLmeta = jx_sqlNewStatement (NULL, false , false);

   stmt += sprintf (stmt , "select ");

   comma = "";
   pNode    =  jx_GetNodeChild (pRow);
   while (pNode) {
      name  = jx_GetNodeNamePtr   (pNode);
      str2upper (temp  , name);   // Needed for national charse in columns names i.e.: BEL�B
      stmt += sprintf (stmt , "%s%s" , comma , temp);
      comma = ",";
      pNode = jx_GetNodeNext(pNode);
   }

   stmt += sprintf (stmt , " from %s where 1=0 with ur" , table);

   // prepare the statement that provides the columns
   rc = SQLPrepare(pSQLmeta->pstmt->hstmt , sqlTempStmt, SQL_NTS);
   if (rc != SQL_SUCCESS ) {
      check_error (pSQLmeta);
      jx_sqlClose (&pSQLmeta); // Free the data
      return NULL;
   }
   return  pSQLmeta;
}
/* ------------------------------------------------------------- */
LGL jx_sqlUpdateOrInsert (BOOL update, PUCHAR table  , PJXNODE pRowP , PUCHAR whereP, PJXNODE pSqlParms)
{
   LONG   attrParm;
   LONG   i;
   PUCHAR valArr[64];
   SHORT  valArrIx= 0;

   UCHAR sqlTempStmt[32766];
   UCHAR where [4096];
   UCHAR temp  [256];
   PUCHAR stmt = sqlTempStmt;
   PJXNODE pNode;
   PUCHAR comma = "";
   PUCHAR name, value;

   SQLSMALLINT   length;
   SQLRETURN     rc;
   PJXSQL        pSQL     = jx_sqlNewStatement (NULL, true , false);
   PJXSQL        pSQLmeta;
   SQLCHUNK      sqlChunk[32];
   SHORT         sqlChunkIx =0;
   PUCHAR        sqlNullPtr = NULL;
   PJXNODE       pRow = jx_ParseString((PUCHAR) pRowP, NULL);
   LGL err = ON; // assume error


   // First get the columen types - by now we use a select to mimic that
   pSQLmeta = buildMetaStmt ( table, pRow);
   if (pSQLmeta == NULL) {
      goto cleanup;
   }

   strFormat(where , whereP , pSqlParms);
   rc = doInsertOrUpdate(pSQL, pSQLmeta, sqlTempStmt, table,pRow, where , update);

   // So far we suceeded: But with data ?
   err = (rc == SQL_SUCCESS) ? OFF:ON;

   if (err == OFF) {
      sqlCode =0;
   } else if ( pSQL && pSQL->pstmt) {
      getSqlCode (pSQL->pstmt->hstmt);
   }

   // Now we are done with the select statement:
   cleanup:
   if (pRowP != pRow) jx_NodeDelete (pRow);
   jx_sqlClose (&pSQLmeta); // Free the data
   jx_sqlClose (&pSQL);
   return err;
}
/* ------------------------------------------------------------- */
LGL jx_sqlUpdate (PUCHAR table  , PJXNODE pRow , PUCHAR whereP, PJXNODE pSqlParmsP  )
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PUCHAR  where     = (pParms->OpDescList->NbrOfParms >= 3) ? whereP : "";
   PJXNODE pSqlParms = (pParms->OpDescList->NbrOfParms >= 4) ? pSqlParmsP : NULL;
   UCHAR  whereStr [1024];
   str2upper(table , table);
   for(; *where == ' ' ; where++); // skip leading blanks
   if (*where > ' ' && ! BeginsWith(where, "where")) {
       sprintf (whereStr , "where %s" , where);
       where = whereStr;
   }
   return jx_sqlUpdateOrInsert  (true , table  , pRow , where, pSqlParms);
}
/* ------------------------------------------------------------- */
LGL jx_sqlInsert (PUCHAR table  , PJXNODE pRow , PUCHAR whereP, PJXNODE pSqlParmsP  )
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PUCHAR  where    =  (pParms->OpDescList->NbrOfParms >= 3) ? whereP : "";
   PJXNODE pSqlParms = (pParms->OpDescList->NbrOfParms >= 4) ? pSqlParmsP : NULL;
   str2upper(table , table);
   return jx_sqlUpdateOrInsert  (false , table  , pRow , where , pSqlParms);
}
/* ------------------------------------------------------------- */
LGL jx_sqlUpsert (PUCHAR table  , PJXNODE pRow , PUCHAR whereP, PJXNODE pSqlParmsP  )
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PUCHAR  where     = (pParms->OpDescList->NbrOfParms >= 3) ? whereP : "";
   PJXNODE pSqlParms = (pParms->OpDescList->NbrOfParms >= 4) ? pSqlParmsP : NULL;
   LGL err;
   // First update - if not found the insert
   err = jx_sqlUpdate  ( table  , pRow , where, pSqlParms);
   if (err == ON && jx_sqlCode() == 100) {
        err = jx_sqlInsert (table  , pRow , where, pSqlParms);
   }
   return err;
}
/* -------------------------------------------------------------------
 * Provide options to a pSQL environment - If NULL then use the default
 * ------------------------------------------------------------------- */
INT64 jx_sqlGetInsertId2 (void)
{
   INT64   id;
   PJXNODE pRow;
   // PUCHAR  sqlStmt = "values IDENTITY_VAL_LOCAL() as id ";
   // PUCHAR  sqlStmt = "values IDENTITY_VAL_LOCAL() into :id";
   PUCHAR  sqlStmt = "select IDENTITY_VAL_LOCAL() as id from sysibm.sysdummy1";

   // Get that only row
   pRow = jx_sqlResultRow(sqlStmt, NULL, 0);

   id = atoll(jx_GetValuePtr(pRow, "id", NULL));

   jx_NodeDelete (pRow);

   return id ;
}
/* -------------------------------------------------------------------
 * Back compat old version
 * ------------------------------------------------------------------- */
LONG jx_sqlGetInsertId (void)
{
   return jx_sqlGetInsertId2();
}
/* -------------------------------------------------------------------
 * Provide options to a pSQL environment - If NULL the use the default
 * ------------------------------------------------------------------- */
void jx_sqlSetOptions (PJXNODE pOptionsP)
{

   PJXSQLCONNECT pc = jx_getCurrentConnection();
   PSQLOPTIONS po = &pConnection->options;
   PJXNODE pNode;

   // Delete previous settings, if we did that parsing
   if (pConnection->pOptionsCleanup) {
       jx_Close(&pConnection->pOptions);
   }

   // .. and set the new setting
   pConnection->pOptionsCleanup = false;
   if (ON == jx_isNode(pOptionsP)) {
       pConnection->pOptions = pOptionsP;
   } else if (pOptionsP != NULL) {
       pConnection->pOptions = jx_ParseString ((PUCHAR) pOptionsP , NULL);
       pConnection->pOptionsCleanup = true;
   }

   pNode    =  jx_GetNodeChild (pConnection->pOptions);
   while (pNode) {
      int rc = SQL_SUCCESS;
      PUCHAR name, value;
      LONG attrParm;
      name  = jx_GetNodeNamePtr   (pNode);
      value = jx_GetNodeValuePtr  (pNode , NULL);

      // Is header overriden by userprogram ?
      if (BeginsWith(name , "upperCaseColName")) {
         po->upperCaseColName = *value == 't'? ON:OFF; // for true
      }
      else if (BeginsWith(name , "autoParseContent")) {
         po->autoParseContent = *value == 't' ? ON:OFF; // for true
      }
      else if (BeginsWith(name , "DecimalPoint")) {
         po->DecimalPoint = *value;
      }
      else if (BeginsWith(name , "sqlNaming")) {
         po->sqlNaming = *value == 't' ? ON:OFF; // for true
         attrParm = po->sqlNaming == OFF; // sysname is invers of SQL naming :(
         rc = SQLSetConnectAttr     (pConnection->hdbc , SQL_ATTR_DBC_SYS_NAMING, &attrParm  , 0);
      }
      // NOTE !! hexSort can only be set at environlevel - befor connect time !!!
      // else if (BeginsWith(name , "hexSort")) {
      //   po->hexSort = *value == 't' ? ON:OFF; // for true
      //}
      if (rc  != SQL_SUCCESS ) {
        check_error (NULL);
        return ; // we have an error
      }

      /* more to come....
         po->DateSep;
         po->DateFmt;
         po->TimeSep;
         po->TimeFmt;
         po->DecimalPoint;
      */
      pNode = jx_GetNodeNext(pNode);
   }
}
/* -------------------------------------------------------------------
 * Get the current options from connection as string
 * ------------------------------------------------------------------- */
VARCHAR jx_sqlGetOptions ()
{
   VARCHAR ret;
   PSQLOPTIONS po = &pConnection->options;
   PJXNODE pOptions = jx_NewObject(NULL);


   jx_SetBoolByName (pOptions , "upperCaseColName" , po->upperCaseColName,OFF);
   jx_SetBoolByName (pOptions , "autoParseContent" , po->autoParseContent,OFF);
   jx_SetCharByName (pOptions , "decimalPoint"     , po->DecimalPoint    ,OFF);
   jx_SetBoolByName (pOptions , "hexSort"          , po->hexSort         ,OFF);
   jx_SetBoolByName (pOptions , "sqlNaming"        , po->sqlNaming       ,OFF);
   jx_SetCharByName (pOptions , "dateSep"          , po->DateSep         ,OFF);
   jx_SetCharByName (pOptions , "dateFmt"          , po->DateFmt         ,OFF);
   jx_SetCharByName (pOptions , "timeSep"          , po->TimeSep         ,OFF);
   jx_SetCharByName (pOptions , "timeFmt"          , po->TimeFmt         ,OFF);

   ret = jx_AsJsonText (pOptions);
   jx_NodeDelete (pOptions);
   return ret;

}
/* ------------------------------------------------------------- */
PJXSQLCONNECT jx_sqlConnect(PJXNODE pOptionsP)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PJXNODE  pOptions = pParms->OpDescList->NbrOfParms >= 1 ? pOptionsP : NULL;
   JXSQL tempSQL;
   PJXSQLCONNECT pc;

   connectionMode = HOSTED;
   // memset(&tempSQL , 0 , sizeof(tempSQL));
   // jx_BuildEnv(&tempSQL);
   pc = jx_getCurrentConnection ();

   return pc;
}
