/* SYSIFCOPT(*IFSIO) TERASPACE(*YES *TSIFC) STGMDL(*SNGLVL)      */
/* COMPILEOPT('OUTPUT(*PRINT) OPTION(*EXPMAC *SHOWINC)')         */
/* Program . . . : JXM002                                        */
/* Design  . . . : Niels Liisberg                                */
/* Function  . . : SQL database I/O                              */
/*                                                               */
/*By    Date      PTF    Description                        */
/* NL     21.10.2006         New program                         */
/* NL     16.10.2014         Added to JSONXML library            */
/* ------------------------------------------------------------- */
#define MAXCOLS 1024

#include <unistd.h>
#include <wchar.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <decimal.h>
#include <stdarg.h>
#include <ctype.h>
#include "ostypes.h"
#include "xlate.h"
#include "varchar.h"
#include "MinMax.h"
#include "parms.h"
#include "utl100.h"
#include "jsonxml.h"
#include "mem001.h"

// Globlas
extern UCHAR jxMessage[512];
extern BOOL  jxError;
extern UCHAR BraBeg;
extern UCHAR CurBeg;

// Unit Globals:
static PJXSQLCONNECT pConnection = NULL;
static BOOL keepConnection = false;

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

void          jx_sqlDisconnect (void);
PJXSQLCONNECT jx_sqlNewConnection(void);

/* ------------------------------------------------------------- */
static int check_error (PJXSQL pSQL)
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
  SQLINTEGER    sqlCode;
  UCHAR         sqlMsgDta[SQL_MAX_MESSAGE_LENGTH + 1];
  PUCHAR        psqlState  = sqlState;
  PLONG         psqlCode   = &sqlCode;
  PUCHAR        psqlMsgDta = sqlMsgDta;

  if (pSQL && pSQL->pstmt) {
     hType  =  SQL_HANDLE_STMT;
     handle =  pSQL->pstmt->hstmt;
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

  rc = SQLGetDiagRec(hType , handle, 1, psqlState, psqlCode, psqlMsgDta,  sizeof(sqlMsgDta), &length);
  sprintf( jxMessage , "%-5.5s %-*.*s" , psqlState, length, length, psqlMsgDta);

  if (pSQL) {
     jx_sqlClose (&pSQL); // Free the data
  }

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

   PJXSQLCONNECT pConnection;
   LONG          attrParm;
   PUCHAR        server = "*LOCAL";
   int rc;
   PSQLOPTIONS po;

   pConnection = memAlloc(sizeof(JXSQLCONNECT));
   memset(pConnection , 0 , sizeof(JXSQLCONNECT));
   pConnection->pCd = XlateXdOpen (13488, 0);
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
   /* Dont test singe the activations groupe might be reclaimed, and a new "session" is on..
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

   rc = SQLAllocConnect (pConnection->henv, &pConnection->hdbc);  // allocate a connection handle
   if (rc != SQL_SUCCESS ) {
     check_error (NULL);
     jx_sqlDisconnect ();
     return NULL; // we have an error
   }

   attrParm = SQL_TXN_NO_COMMIT;
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
PUCHAR strFormat (PUCHAR out, PUCHAR in , PJXNODE parms)
{
  PUCHAR p, pMarker, res = out;
  PJXNODE pParms = parms;
  int markerLen ;
  UCHAR marker [64];

  if (OFF == jx_isNode (parms)) {
    pParms =  jx_ParseString((PUCHAR) parms, NULL);
  }

  while (*in) {
     if (*in == '$') {
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
static PJXSQL jx_sqlNewStatement(PJXNODE pSqlParms, BOOL exec)
{
   PJXSQL pSQL;
   PJXSQLCONNECT pc;
   PJXSQLSTMT pStmt;
   SHORT i;
   int rc;
   LONG   attrParm;

   pSQL = memAlloc(sizeof(JXSQL));
   memset(pSQL , 0 , sizeof(JXSQL));
   pSQL->rowcount = -1;

   // build or get the connection
   pc = jx_getCurrentConnection();
   if (pc == NULL) return NULL;

   // find first idle statement or create new
   for (i=0;i<pc->stmtIx; i++) {
      pStmt = &pc->stmts[i];
      if ( ! pStmt->allocated && pStmt->exec == exec) {
         pStmt->allocated = true;
         pSQL->pstmt = pStmt;
         return pSQL;
      }
   }

   // Take the next
   pStmt = &pc->stmts[pc->stmtIx++];
   pStmt->allocated = true;
   pStmt->exec      = exec;
   pSQL->pstmt      = pStmt;

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
      attrParm = SQL_TRUE;
      rc = SQLSetStmtAttr  (pSQL->pstmt->hstmt, SQL_ATTR_CURSOR_SCROLLABLE , &attrParm  , 0);
      if (rc != SQL_SUCCESS ) {
        check_error (pSQL);
        return NULL; // we have an error
      }

      /*
      attrParm = SQL_TRUE;
      rc = SQLSetStmtAttr  (pSQL->pstmt->hstmt, SQL_ATTR_EXTENDED_COL_INFO , &attrParm  , 0);
      if (rc != SQL_SUCCESS ) {
        check_error (pSQL);
        return NULL; // we have an error
      }
      */

      attrParm = SQL_CONCUR_READ_ONLY;
      rc = SQLSetStmtAttr  (pSQL->pstmt->hstmt, SQL_ATTR_CONCURRENCY , &attrParm  , 0);
      if (rc != SQL_SUCCESS ) {
        check_error (pSQL);
        return NULL; // we have an error
      }
   }

   return pSQL;

}
/* ------------------------------------------------------------- */
/* ------------------------------------------------------------- */
PJXSQL jx_sqlOpen(PUCHAR sqlstmt , PJXNODE pSqlParms)
{

   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   // LONG    format   =  (pParms->OpDescList->NbrOfParms >= 3) ? formatP : 0;  // Status & result object

   LONG   attrParm;
   LONG   i;
//   PJXSQL pSQL = jx_sqlNewStatement (pParms->OpDescList->NbrOfParms >= 2 ? pSqlParms  :NULL);
   PJXSQL pSQL;
   int rc;

   jxError = false; // Assume OK

   pSQL = jx_sqlNewStatement (NULL, false);
   if  ( pSQL == NULL) return NULL;

   // run  the  statement in "sqlstr"
   if (pParms->OpDescList->NbrOfParms >= 2 && pSqlParms ) {
      UCHAR sqlTempStmt[32766];
      strFormat(sqlTempStmt , sqlstmt , pSqlParms);
      pSQL->sqlstmt = strdup(sqlTempStmt);
   } else {
      pSQL->sqlstmt = strdup(sqlstmt);
   }

   rc = SQLExecDirect (pSQL->pstmt->hstmt, pSQL->sqlstmt, SQL_NTS);

   if (rc != SQL_SUCCESS && rc != SQL_NO_DATA_FOUND) {
     check_error (pSQL);
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
     return; // we have an error
   }
   */

   rc = SQLNumResultCols (pSQL->pstmt->hstmt, &pSQL->nresultcols);
   if (rc != SQL_SUCCESS ) {
      check_error (pSQL);
      return NULL; // we have an error
   }

   for (i = 0; i < pSQL->nresultcols; i++) {
      PJXCOL pCol = &pSQL->cols[i];

      SQLDescribeCol (pSQL->pstmt->hstmt, i+1, pCol->colname, sizeof (pCol->colname),
          &pCol->colnamelen, &pCol->coltype, &pCol->collen, &pCol->scale, &pCol->nullable);

      pCol->colname[pCol->colnamelen] = '\0';

      if (OFF == jx_IsTrue (pConnection->pOptions ,"uppercasecolname")) {
         str2lower  (pCol->colname , pCol->colname);
      }

      // get display label  for column
      /****************
      rc = SQLColAttributes (hstmt, i+1, SQL_DESC_LABEL, Label , sizeof(Label)  , &len , NULL);
      if (rc != SQL_SUCCESS ) {
        check_error (pSQL);
        return; // we have an error
      }
      ***********/


      // get display length for column
      SQLColAttributes (pSQL->pstmt->hstmt, i+1, SQL_DESC_PRECISION, NULL, 0,NULL, &pCol->displaysize);

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
         case SQL_BLOB:
         case SQL_CLOB:
 //           pCol->collen = pCol->displaysize * 2;
 //           pCol->data = (SQLCHAR *) malloc (pCol->collen);
            pCol->collen = 1048576;  // 1MEGABYTES
            pCol->data = (SQLCHAR *) malloc (pCol->collen);  // 1MEGABYTES
            rc = SQLBindCol (pSQL->pstmt->hstmt, i+1, SQL_C_BINARY , pCol->data, pCol->collen, &pCol->outlen);
            break;

         case SQL_WCHAR:
         case SQL_WVARCHAR:
         case SQL_GRAPHIC:
         case SQL_VARGRAPHIC:
            pCol->collen = pCol->displaysize * 2;
            pCol->data = (SQLCHAR *) malloc (pCol->collen);
            rc = SQLBindCol (pSQL->pstmt->hstmt, i+1, pCol->coltype, pCol->data, pCol->collen, &pCol->outlen);
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
            pCol->data = (SQLCHAR *) malloc (pCol->collen);
            rc = SQLBindCol (pSQL->pstmt->hstmt, i+1, SQL_C_CHAR, pCol->data, pCol->collen, &pCol->outlen);
            break;
      }
      if (pCol->coltype >= SQL_NUMERIC && pCol->coltype <= SQL_DOUBLE) {
         pCol->nodeType = JX_LITERAL;
      } else {
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

   if ( pSQL->rc == SQL_SUCCESS) {

      pRow = jx_NewObject(NULL);

      for (i = 0; i < pSQL->nresultcols; i++) {

         PJXCOL pCol = &pSQL->cols[i];

         // Null data is the same for all types
         if (pCol->outlen ==  SQL_NULL_DATA) {
            jx_NodeAdd (pRow , RL_LAST_CHILD, pCol->colname , "null",  JX_LITERAL );
         } else {

            switch( pCol->coltype) {
               case SQL_WCHAR:
               case SQL_WVARCHAR:
               case SQL_GRAPHIC:
               case SQL_VARGRAPHIC: {
                  UCHAR temp [32768];
                  PUCHAR pInBuf = pCol->data;
                  size_t OutLen;
                  size_t inbytesleft;

                  for  (inbytesleft = pCol->collen; inbytesleft > 0 ; inbytesleft -= 2) {
                     if ( * (PSHORT) (pInBuf + inbytesleft - 2) > 0x0020) break;
                  }
                  OutLen = XlateXdBuf  (pConnection->pCd, temp , pInBuf, inbytesleft);
                  temp[OutLen] = '\0';

                  jx_NodeAdd (pRow , RL_LAST_CHILD, pCol->colname , temp,  pCol->nodeType );

                  break;
               }

               case SQL_NUMERIC:
               case SQL_DECIMAL:
               case SQL_FLOAT:
               case SQL_REAL:
               case SQL_DOUBLE: {
                  PUCHAR p = pCol->data;
                  int len = strTrimLen(p);
                  p[len] = '\0';

                  // Have to fix .00 numeric as 0.00
                  if (*p == '.') {
                     memmove (p+1 , p, len+1);
                     *p = '0';
                  }

                  jx_NodeAdd (pRow , RL_LAST_CHILD, pCol->colname , p,  pCol->nodeType );

                  break ;
               }

               default: {
                  PUCHAR p = pCol->data;
                  int len;

                  if (pCol->coltype != SQL_BLOB
                  &&  pCol->coltype != SQL_CLOB) {
                     len = strTrimLen(p);
                     p[len] = '\0';
                  }

                  // trigger new parsing of JSON-objects in columns:
                  // Predicts json data i columns
                  if (pConnection->options.autoParseContent == ON) {
                     if (*p == BraBeg || *p == CurBeg) {
                        PJXNODE pNode = jx_ParseString(p, NULL);
                        if (pNode) {
                           jx_NodeRename(pNode, pCol->colname);
                           jx_NodeAddChildTail (pRow, pNode);
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
      return pRow; // Found

   } else {
      if (pSQL->rc != SQL_NO_DATA_FOUND ) {
         check_error (pSQL);
      }
   }

   return NULL; // not found
}
/* ------------------------------------------------------------- */
PJXNODE jx_sqlFetchRelative (PJXSQL pSQL, LONG fromRow)
{
   int rc;
   if (pSQL == NULL) return (NULL);

   pSQL->rc = SQLFetchScroll (pSQL->pstmt->hstmt, SQL_FETCH_RELATIVE , fromRow);
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
void jx_sqlClose (PJXSQL * ppSQL)
{
   int i;
   int rc;
   PJXSQL pSQL = * ppSQL;

   // Do we have an active statement ...
   if (pSQL) {

      // free data buffers
      for (i = 0; i < pSQL->nresultcols; i++) {
         PJXCOL pCol = &pSQL->cols[i];

         // if ( pCol->coltype != SQL_BLOB) {
         if (pCol->data) {
            free (pCol->data);
            pCol->data = null;
         }
         //}
      }
      pSQL->nresultcols = 0; // !! Done

      if (pSQL->pstmt) {
         if (pSQL->pstmt->exec) {

            /*
            if (pSQL->pstmt->hstmt) {
               rc = SQLFreeHandle (SQL_HANDLE_STMT, pSQL->pstmt->hstmt);
            }
            */

         } else {

            // Clean up for read cursor statements:

            /*-------
            if (pSQL->pstmt->hstmt) {
               rc = SQLFreeStmt(pSQL->pstmt->hstmt, SQL_CLOSE);
            }
            ---*/

            /*

            if (pSQL->pstmt->hstmt) {
               rc = SQLFreeHandle (SQL_HANDLE_STMT, pSQL->pstmt->hstmt);
            }
            */

            rc = SQLCloseCursor(pSQL->pstmt->hstmt);
         }
         pSQL->pstmt->allocated = false;
      }


      if (pSQL->sqlstmt) {
         free (pSQL->sqlstmt);
         pSQL->sqlstmt = null;
      }
      memFree(ppSQL);
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

   if (keepConnection )  return;

   if (pConnection == NULL) return;

   XlateXdClose(pConnection->pCd) ;

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
   memFree (&pConnection);

}
/* ------------------------------------------------------------- */
PJXNODE jx_buildMetaFields ( PJXSQL pSQL )
{
   int rc;
   LONG    attrParm;
   PJXNODE pFields  = jx_NewArray(NULL);
   int i;

   attrParm = SQL_TRUE;
   rc = SQLSetStmtAttr  (pSQL->pstmt->hstmt, SQL_ATTR_EXTENDED_COL_INFO , &attrParm  , 0);
   if (rc != SQL_SUCCESS ) {
     check_error (pSQL);
     return NULL; // we have an error
   }

   for (i = 1; i <= pSQL->nresultcols; i++) {
      PJXNODE pField  = jx_NewObject (NULL);
      PJXCOL  pCol     = &pSQL->cols[i-1];
      PUCHAR  type = "string";
      UCHAR   temp [256];

      // Add name
      jx_NodeAdd (pField  , RL_LAST_CHILD, "name" , pCol->colname,  VALUE );

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

      // Add size
      sprintf(temp , "%d" , pCol->displaysize);
      jx_NodeAdd (pField  , RL_LAST_CHILD, "size"     , temp,  LITERAL  );

      // Add decimal precission
      if  (pCol->coltype >= SQL_NUMERIC && pCol->coltype <= SQL_DOUBLE
      &&   pCol->scale > 0) {
         sprintf(temp , "%d" , pCol->scale);
         jx_NodeAdd (pField  , RL_LAST_CHILD, "prec"     , temp,  LITERAL  );
      }

      // Push to array
      jx_ArrayPush (pFields , pField, FALSE);
   }

   // jx_Debug ("Fields:", pFields);
   return  pFields;

}
/* ------------------------------------------------------------- */
LONG jx_sqlNumberOfRows(PUCHAR sqlstmt)
{

   LONG    rowCount;
   PJXNODE pRow;
   PUCHAR p, lastSelect, orderby, from;
   UCHAR  str2 [32766];

   // replace the coloumn list with a count(*) - TODO !! This will not work on a "with" statment

   // Find the last select ( there can be more when using "with")

   p = sqlstmt;
   for(;;) {
      p = stristr(p , "select ");
      if (p == null) break;
      lastSelect = p;
      p++;
   }
   if (lastSelect == NULL) return 0;

   // We need to replace all columns between "select" and  "from"  with the count(*)
   from    = stristr(lastSelect , " from ");
   if (from == NULL) return 0;

   // remove order by - if any
   orderby = stristr(from  , " order ");
   if (orderby) {
      *orderby = '\0';
   }

   // rebuild the select statement as a "select count(*) from ..."
   substr (str2 , sqlstmt , lastSelect - sqlstmt); // if a "With" exists then grab that
   strcat (str2 ,"select count(*) as counter" );
   strcat (str2 , from );

   // Get that only row
   pRow = jx_sqlResultRow(str2, NULL);

   rowCount = atoi(jx_GetValuePtr(pRow, "counter", NULL));

   jx_NodeDelete (pRow);

   return rowCount;
}
/* ------------------------------------------------------------- */
void jx_sqlUpperCaseNames(PJXSQL pSQL)
{
   int i;
   for (i = 0; i < pSQL->nresultcols; i++) {
     PJXCOL pCol = &pSQL->cols[i];
     str2upper (pCol->colname , pCol->colname);
   }
}
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
/* ------------------------------------------------------------- */
PJXNODE jx_sqlResultSet( PUCHAR sqlstmt, LONG startP, LONG limitP, LONG formatP , PJXNODE pSqlParmsP  )
{

   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   LONG    start     = (pParms->OpDescList->NbrOfParms >= 2) ? startP     : 1;  // From first row
   LONG    limit     = (pParms->OpDescList->NbrOfParms >= 3) ? limitP     : -1; // All row
   LONG    format    = (pParms->OpDescList->NbrOfParms >= 4) ? formatP    : 0;  // Arrray only
   PJXNODE pSqlParms = (pParms->OpDescList->NbrOfParms >= 5) ? pSqlParmsP : NULL;
   PJXNODE pRows     = jx_NewArray(NULL);
   PJXNODE pRow      ;
   PJXNODE pResult;
   PJXSQL  pSQL;
   LONG    i;

   pSQL = jx_sqlOpen(sqlstmt , pSqlParms);
   if ( pSQL == NULL) {
        return NULL;
   }

   if (format & (JX_UPPERCASE)) {
        jx_sqlUpperCaseNames(pSQL);
   }

   pRow  = jx_sqlFetchRelative (pSQL, start);
   for (i = 1; pRow && (i <=limit || limit == -1); i++) {
      jx_ArrayPush (pRows , pRow, FALSE);
      pRow  = jx_sqlFetchNext (pSQL);
   }

   // need a object as return value
   if (format & (JX_META | JX_FIELDS | JX_TOTALROWS)) {
      PJXNODE pMeta;
      pResult  = jx_NewObject(NULL);
      pMeta    = jx_NewObject(NULL);
      jx_SetValueByName(pMeta , "success" , "true" , LITERAL);
      jx_SetValueByName(pMeta , "root"    , "rows" , VALUE);
      if (format & JX_FIELDS ) {
         PJXNODE pFields = jx_buildMetaFields (pSQL);
         jx_NodeMoveInto(pMeta , "fields" , pFields);
      }
      if (format & JX_TOTALROWS ) {
         jx_SetValueByName(pMeta , "totalProperty"   , "totalRows" , VALUE);
         pSQL->rowcount = jx_sqlNumberOfRows(sqlstmt);
         jx_SetIntByName(pResult , "totalRows" , pSQL->rowcount );
      }

      jx_NodeMoveInto (pResult , "metaData" , pMeta);
      jx_NodeMoveInto (pResult , "rows"     , pRows);

   } else {

      // simply return the array of rows
      pResult = pRows;
   }

   jx_sqlClose (&pSQL);
   return pResult;

}
/* ------------------------------------------------------------- */
PJXNODE jx_sqlResultRowAt ( PUCHAR sqlstmt, LONG startP, PJXNODE pSqlParmsP )
{

   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   LONG    start     = (pParms->OpDescList->NbrOfParms >= 2) ? startP     : 1;  // From first row
   PJXNODE pSqlParms = (pParms->OpDescList->NbrOfParms >= 3) ? pSqlParmsP : NULL;
   PJXNODE pRow;
   PJXSQL  pSQL;

   pSQL = jx_sqlOpen(sqlstmt , pSqlParms);
   pRow  = jx_sqlFetchRelative (pSQL, start);
   jx_sqlClose (&pSQL);
   return pRow;

}
/* ------------------------------------------------------------- */
PJXNODE jx_sqlGetMeta (PUCHAR sqlstmt)
{
   int i;
   PJXSQL  pSQL  = jx_sqlOpen(sqlstmt , NULL);
   PJXNODE pMeta = jx_buildMetaFields ( pSQL );
   jx_sqlClose (&pSQL);
   return pMeta;
}
/* ------------------------------------------------------------- */
PJXNODE jx_sqlResultRow ( PUCHAR sqlstmt, PJXNODE pSqlParmsP )
{

   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PJXNODE pSqlParms = (pParms->OpDescList->NbrOfParms >= 2) ? pSqlParmsP : NULL;
   PJXNODE pRow;
   PJXSQL  pSQL;

   pSQL = jx_sqlOpen(sqlstmt , pSqlParms);
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
   PJXSQL pSQL = jx_sqlNewStatement (NULL, true);


   // run  the  statement in "sqlstr"
   if (pParms->OpDescList->NbrOfParms >= 2) {
      UCHAR sqlTempStmt[32766];
      strFormat(sqlTempStmt , sqlstmt , pSqlParms);
      rc = SQLExecDirect (pSQL->pstmt->hstmt, sqlTempStmt , SQL_NTS);
   } else {
      rc = SQLExecDirect (pSQL->pstmt->hstmt, sqlstmt, SQL_NTS);
   }

   if (rc != SQL_SUCCESS && rc != SQL_NO_DATA_FOUND) {
      check_error (pSQL);
      return ON; // we have an error
   }


   jx_sqlClose (&pSQL);

   return OFF;

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
static void buildUpdate (SQLHSTMT hstmt, PUCHAR sqlStmt, PUCHAR table, PJXNODE pSqlParms , PUCHAR where)
{
   PUCHAR stmt = sqlStmt;
   PUCHAR comma = "";
   PJXNODE pNode;
   PUCHAR name;
   int     i,columns  = 0;

   stmt += sprintf (stmt , "update %s set " , table);

   pNode    =  jx_GetNode(pSqlParms, "/");
   while (pNode) {
      columns ++;
      name  = jx_GetNodeNamePtr   (pNode);
      stmt += sprintf (stmt , "%s%s=?" , comma , name);
      comma = ",";
      pNode = jx_GetNodeNext(pNode);
   }

   stmt += sprintf (stmt , " %s" , where);
}
/* ------------------------------------------------------------- */
static void buildInsert  (SQLHSTMT hstmt, PUCHAR sqlStmt, PUCHAR table, PJXNODE pSqlParms , PUCHAR where)
{
   PUCHAR  stmt = sqlStmt;
   PUCHAR  comma = "";
   PJXNODE pNode;
   PUCHAR  name;
   int     i,columns  = 0;

   stmt += sprintf (stmt , "insert into  %s (" , table);

   pNode    =  jx_GetNode(pSqlParms, "/");
   while (pNode) {
      columns  ++;
      name  = jx_GetNodeNamePtr   (pNode);
      // value = jx_GetNodeValuePtr  (pNode , NULL);
      stmt += sprintf (stmt , "%s%s" , comma , name);
      comma = ",";
      pNode = jx_GetNodeNext(pNode);
   }

   stmt += sprintf (stmt , ") values( ");
   comma = "";
   for (i=0;i<columns;i++) {
      stmt += sprintf (stmt , "%s?" , comma );
      comma = ",";
   }
   stmt += sprintf (stmt , ")") ;
}
/* ------------------------------------------------------------- */
LGL jx_sqlUpsert (BOOL update, PUCHAR table  , PJXNODE pSqlParms , PUCHAR where)
{

   LONG   attrParm;
   LONG   i;
   UCHAR sqlTempStmt[32766];
   PUCHAR stmt = sqlTempStmt;
   PJXNODE pNode;
   PUCHAR comma = "";
   PUCHAR name, value;

   SQLSMALLINT   length;
   SQLRETURN     rc;
   PJXSQL        pSQL     = jx_sqlNewStatement (NULL, true);
   PJXSQL        pSQLmeta = jx_sqlNewStatement (NULL, false);
   SQLCHUNK      sqlChunk[32];
   SHORT         sqlChunkIx =0;
   PUCHAR        sqlNullPtr = NULL;

   // First get the columen types - by now we use a select to mimic that

   stmt = sqlTempStmt;
   stmt += sprintf (stmt , "select ");

   comma = "";
   pNode    =  jx_GetNode(pSqlParms, "/");
   while (pNode) {
      name  = jx_GetNodeNamePtr   (pNode);
      stmt += sprintf (stmt , "%s%s" , comma , name);
      comma = ",";
      pNode = jx_GetNodeNext(pNode);
   }

   stmt += sprintf (stmt , " from %s where 1=0" , table);


   // prepare the statement that provides the columns
   rc = SQLPrepare(pSQLmeta->pstmt->hstmt , sqlTempStmt, SQL_NTS);
   if (rc != SQL_SUCCESS ) {
     check_error (pSQLmeta);
     return ON; // we have an error
   }

   // Now we have the colume definitions - now build the update statement:

   if (update) {
      buildUpdate (pSQL->pstmt->hstmt, sqlTempStmt , table, pSqlParms , where);
   } else {
      buildInsert (pSQL->pstmt->hstmt, sqlTempStmt , table, pSqlParms , where);
   }

   // prepare the statement that will do the update
   rc = SQLPrepare(pSQL->pstmt->hstmt , sqlTempStmt, SQL_NTS);
   if (rc  != SQL_SUCCESS ) {
     check_error (pSQL);
     return ON; // we have an error
   }


   // Take the description from the "select" and use it on the "update"
   pNode    =  jx_GetNode(pSqlParms, "/");
   for (i=1; pNode; i++) {
      JXCOL Col;
      memset (&Col , 0 , sizeof(JXCOL));

      value = jx_GetNodeValuePtr  (pNode , NULL);

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
         return ON; // we have an error
      }

      // bind parameter to the statement
      if ( Col.coltype == SQL_BLOB
      ||   Col.coltype == SQL_CLOB ) {
         SQLINTEGER dataAtExec = SQL_DATA_AT_EXEC;
         // SQLLEN     dataAtExec = SQL_LEN_DATA_AT_EXEC ( 0 );

         PSQLCHUNK pSqlChunk  = &sqlChunk[sqlChunkIx++];
         pSqlChunk->actLen    = strlen(value);
         pSqlChunk->offset    = 0;
         pSqlChunk->chunkLen  = min(pSqlChunk->actLen,16384);
         pSqlChunk->value     = value;

         if (pSqlChunk->actLen == 0) {
            rc = SQLBindParameter(pSQL->pstmt->hstmt,
               i,
               SQL_PARAM_INPUT,
               SQL_C_BINARY, //SQL_C_CHAR,  // SQL_C_BINARY, ,           // SQL_C_BINARY, //SQL_C_CHAR,
               SQL_LONGVARBINARY,    //  SQL_VARBINARY, //  // SQL_LONGVARCHAR,
               0 , // Col.collen,  // pSqlChunk->actLen, pSqlChunk->chunkLen,  pSqlChunk->chunkLen,//Col.collen,
               0,                    // presition
               value,                // Parm value
               0 ,                   // Buffer len - Not used
               NULL                  // no-chunk just direct access to NULL
            );

         } else {

            rc = SQLBindParameter(pSQL->pstmt->hstmt,
               i,
               SQL_PARAM_INPUT,
               SQL_C_BINARY, //SQL_C_CHAR,  // SQL_C_BINARY, ,           // SQL_C_BINARY, //SQL_C_CHAR,
               SQL_LONGVARBINARY, //  SQL_VARBINARY, //  // SQL_LONGVARCHAR,
               pSqlChunk->actLen,// Col.collen pSqlChunk->chunkLen,  pSqlChunk->chunkLen,//Col.collen,//overall length
               0,                    // presition
               (SQLPOINTER) pSqlChunk,            // Parm value
               0 ,                   // Buffer len - Not used
               &dataAtExec           // chunk size
            );
         }
      } else {
         rc = SQLBindParameter(pSQL->pstmt->hstmt,
            i,
            SQL_PARAM_INPUT,
            SQL_C_CHAR,
            Col.coltype,
            Col.collen,   // length
            Col.scale,    // presition
            value,
            0,
            NULL // pointer to length variable
         );
      }

      if (rc != SQL_SUCCESS ) {
         check_error (pSQL);
         return ON; // we have an error
      }

      pNode = jx_GetNodeNext(pNode);
   }

   // Now we are done with the select statement:
   jx_sqlClose (&pSQLmeta); // Free the data

   // run  the  statement in "sqlstr"
   rc = SQLExecute( pSQL->pstmt->hstmt);

   // Has BLOB's ?
   while  (rc == SQL_NEED_DATA) {
        SQLPOINTER parmNo;
        PSQLCHUNK  pSqlChunk;
        SHORT i;
        SQLINTEGER putLen;
        PUCHAR putBuf;


        rc  = SQLParamData(pSQL->pstmt->hstmt, (SQLPOINTER) &pSqlChunk);

        if (rc == SQL_NEED_DATA) {

           // iterate for each buffer chunk
           while (pSqlChunk->actLen > 0) {
              putLen = min(pSqlChunk->actLen , pSqlChunk->chunkLen);
              putBuf = pSqlChunk->value + pSqlChunk->offset;
              rc = SQLPutData(pSQL->pstmt->hstmt, putBuf , putLen);
              pSqlChunk->offset += putLen;
              pSqlChunk->actLen -= putLen;
           }
        }
   }

   if (rc != SQL_SUCCESS && rc != SQL_NO_DATA_FOUND) {
      check_error (pSQL);
      return ON; // we have an error
   }

   jx_sqlClose (&pSQL);

   return OFF;

}
/* ------------------------------------------------------------- */
LGL jx_sqlUpdate (PUCHAR table  , PJXNODE pSqlParms , PUCHAR whereP)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PUCHAR where =  (pParms->OpDescList->NbrOfParms >= 3) ? whereP : "";
   UCHAR  whereStr [1024];
   for(; *where == ' ' ; where++); // skip leading blanks
   if (*where > ' ' && ! BeginsWith(where, "where")) {
       sprintf (whereStr , "where %s" , where);
       where = whereStr;
   }
   return jx_sqlUpsert  (true , table  , pSqlParms , where);
}
LGL jx_sqlInsert (PUCHAR table  , PJXNODE pSqlParms , PUCHAR whereP)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PUCHAR where =  (pParms->OpDescList->NbrOfParms >= 3) ? whereP : "";
   return jx_sqlUpsert  (false , table  , pSqlParms , where);
}

/* -------------------------------------------------------------------
 * Provide options to a pSQL environment - If NULL the use the default
 * ------------------------------------------------------------------- */
LONG jx_sqlGetInsertId (void)
{
   LONG    id;
   PJXNODE pRow;
   // PUCHAR  sqlStmt = "values IDENTITY_VAL_LOCAL() as id ";
   // PUCHAR  sqlStmt = "values IDENTITY_VAL_LOCAL() into :id";
   PUCHAR  sqlStmt = "Select IDENTITY_VAL_LOCAL() as id from sysibm/sysdummy1";

   // Get that only row
   pRow = jx_sqlResultRow(sqlStmt, NULL);

   id = atoi(jx_GetValuePtr(pRow, "id", NULL));

   jx_NodeDelete (pRow);

   return id ;
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

   pNode    =  jx_GetNode(pConnection->pOptions, "/");
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
      if (rc  != SQL_SUCCESS ) {
        check_error (NULL);
        return ; // we have an error
      }

      /* more to come....
         po->hexSort;
         po->DateSep;
         po->DateFmt;
         po->TimeSep;
         po->TimeFmt;
         po->DecimalPoint;
      */
      pNode = jx_GetNodeNext(pNode);
   }
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

