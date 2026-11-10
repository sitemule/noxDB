// CMD:CRTCMOD
/* ------------------------------------------------------------- */
/* Program . . . : sqldiag                                       */
/* Design  . . . : Niels Liisberg                                */
/* Function  . . : The job log messages behind an SQL error      */
/*                                                               */
/*  The CLI diagnostic record only holds the SQL message, e.g.   */
/*  SQL0913 "MYTABLE in MYLIB type *FILE in use". The job that   */
/*  holds the lock is in the *DIAG message sent just before it   */
/*  (CPF5027 / CPF5032 / CPF3202). On an error we read the job   */
/*  log messages sent since the statement started.               */
/*                                                               */
/*  No SQL here on purpose: after an SQL error such as -901 a    */
/*  query like qsys2.joblog_info would fail as well. The job log */
/*  is read with the List Job Log Messages API (QGYOLJBL), and   */
/*  API errors come back in the error code - never as exceptions.*/
/*  Nothing runs on the good path except the MATTOD at the start */
/*  of each statement (nox_sqlDiagStart).                        */
/*                                                               */
/* By     Date       PTF     Description                         */
/* NL     10.11.2026         New module                          */
/* ------------------------------------------------------------- */
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <time.h>
#include <qp0z1170.h>
#include <mimchint.h>
#include "/qsys.lib/QSYSINC.lib/MIH.file/MATTOD.mbr"
#include <qgyoljbl.h>
#include <qgyclst.h>
#include <qusec.h>

#include <QTQICONV.h>
#include "ostypes.h"
#include "varchar.h"
#include "xlate.h"
#include "strutil.h"
#include "parms.h"
#define NOX_BUILD
#include "noxDbUtf8.h"

__thread extern UCHAR jxMessage[512];

#define DIAG_MAX_MSGS  20    // newest job log messages looked at
#define DIAG_MSG_LEN   512   // first level text, with replacement data

typedef _Packed struct {
   Qgy_Oljbl_MsgSelInfo_t sel;
   int   fieldId;
   char  callMsgQ[1];
} DIAG_SELECT;

typedef _Packed struct {
   Qus_EC_t ec;
   char     exceptionData[64];
} DIAG_APIERR;

static __thread iconv_t jobToUtf8;
static __thread BOOL    jobToUtf8Open = false;

/* ------------------------------------------------------------- */
/* Remember when the statement started (a single MI instruction) */
/* and drop the messages from the previous error                 */
/* ------------------------------------------------------------- */
void nox_sqlDiagStart (PNOX_SQLCONNECT pCon)
{
   if (pCon == NULL) return;
   mattod ((char *) pCon->diagFrom);
   if (pCon->pDiag) {
      nox_NodeDelete (pCon->pDiag);
      pCon->pDiag = NULL;
   }
   pCon->hasError  = OFF;
   pCon->errMsg[0] = '\0';
   if (pCon->errStmt) {
      free (pCon->errStmt);
      pCon->errStmt = NULL;
   }
}
/* ------------------------------------------------------------- */
/* Statement start as the job log sort key CYYMMDDHHMMSSuuuuuu   */
/* (local time, the way the job log has it); "" when not known   */
/* ------------------------------------------------------------- */
static void diagFromKey (PNOX_SQLCONNECT pCon, char * key)
{
   static const char zero[8] = {0};
   struct timeval tv;
   struct tm tmLocal;

   *key = '\0';
   if (memcmp (pCon->diagFrom, zero, sizeof(zero)) == 0) return;
   Qp0zCvtToTimeval (&tv, (char *) pCon->diagFrom, QP0Z_CVTTIME_TO_TIMESTAMP);
   localtime_r (&tv.tv_sec, &tmLocal);
   sprintf (key, "%1d%02d%02d%02d%02d%02d%02d%06d",
      tmLocal.tm_year >= 100 ? 1 : 0, tmLocal.tm_year % 100, tmLocal.tm_mon + 1, tmLocal.tm_mday,
      tmLocal.tm_hour, tmLocal.tm_min, tmLocal.tm_sec, (int) tv.tv_usec);
}
/* ------------------------------------------------------------- */
/* Job CCSID text (fixed length or zero terminated) to UTF-8     */
/* ------------------------------------------------------------- */
static PUCHAR toUtf8 (PUCHAR out, PUCHAR in, LONG len)
{
   LONG outLen;
   if (! jobToUtf8Open) {
      jobToUtf8 = XlateOpen (0, 1208, false);
      jobToUtf8Open = true;
   }
   while (len > 0 && (in[len-1] == ' ' || in[len-1] == '\0')) len--;
   outLen = XlateBuffer (jobToUtf8, out, in, len);
   out[outLen < 0 ? 0 : outLen] = '\0';
   return out;
}
/* ------------------------------------------------------------- */
#pragma convert(1252)
static PNOXNODE diagMessage (Qgy_Oljbl_RecVar_t * pRec, PUCHAR pText, LONG textLen)
{
   PNOXNODE pMsg = nox_NewObject();
   UCHAR    temp [DIAG_MSG_LEN * 4 + 1];
   PUCHAR   type;

   switch ((pRec->Msg_Type[0] - 0xF0) * 10 + (pRec->Msg_Type[1] - 0xF0)) {
      case  2: type = "diagnostic"; break;
      case 14:
      case 16: type = "notify";     break;
      default: type = "escape";     break;
   }
   nox_SetAsciiByName (pMsg, "msgId",    toUtf8 (temp, pRec->Msg_ID, sizeof(pRec->Msg_ID)));
   nox_SetAsciiByName (pMsg, "type",     type);
   nox_SetIntByName   (pMsg, "severity", pRec->Msg_Severity);
   nox_SetAsciiByName (pMsg, "text",     toUtf8 (temp, pText, textLen));
   return pMsg;
}
#pragma convert(0)
/* ------------------------------------------------------------- */
/* After an SQL error: remember the message (jxMessage, job CCSID)*/
/* and the statement for nox_sqlErrorObject, and the diagnostic,  */
/* escape and notify messages the job log got since the statement */
/* started, oldest first - in pCon->pDiag (NULL when none) until  */
/* the next statement                                             */
/* ------------------------------------------------------------- */
void nox_sqlDiagCollect (PNOX_SQLCONNECT pCon, PUCHAR sqlstmt)
{
   static const char lastKey[4] = {0xFF, 0xFF, 0xFF, 0xFF};
   DIAG_SELECT     select;
   DIAG_APIERR     apiErr;
   DIAG_APIERR     closeErr;
   Qgy_Oljbl_ListInfo_t listInfo;
   char            receiver [DIAG_MAX_MSGS * (sizeof(Qgy_Oljbl_RecVar_t) + sizeof(Qgy_Oljbl_IDFieldInfo_t) + DIAG_MSG_LEN + 64)];
   Qgy_Oljbl_RecVar_t * found [DIAG_MAX_MSGS];
   PUCHAR          foundText [DIAG_MAX_MSGS];
   LONG            foundLen  [DIAG_MAX_MSGS];
   int             nFound = 0;
   char            fromKey [20];
   char            msgKey  [20];
   int             i;
   Qgy_Oljbl_RecVar_t * pRec;

   if (pCon == NULL) return;
   if (pCon->pDiag) {
      nox_NodeDelete (pCon->pDiag);
      pCon->pDiag = NULL;
   }
   pCon->hasError = ON;
   strncpy (pCon->errMsg , jxMessage , sizeof(pCon->errMsg) - 1);
   pCon->errMsg[sizeof(pCon->errMsg) - 1] = '\0';
   if (sqlstmt && pCon->errStmt == NULL) {
      pCon->errStmt = strdup (sqlstmt);
   }
   diagFromKey (pCon, fromKey);

   memset (&select, ' ', sizeof(select));
   memcpy (select.sel.List_Direction, "*PRV", 4);
   select.sel.Job_Name[0] = '*';
   memcpy (select.sel.Starting_Msg_Key, lastKey, 4);
   select.sel.Max_Msg_Length  = DIAG_MSG_LEN;
   select.sel.Max_Help_Length = 0;
   select.sel.ID_Offset       = offsetof(DIAG_SELECT, fieldId);
   select.sel.Num_Fields      = 1;
   select.sel.Q_Offset        = offsetof(DIAG_SELECT, callMsgQ);
   select.sel.Msg_Q_Name_Size = 1;
   select.fieldId             = 302;   // message with replacement data
   select.callMsgQ[0]         = '*';

   memset (&apiErr, 0, sizeof(apiErr));
   apiErr.ec.Bytes_Provided = sizeof(apiErr);
   memset (&listInfo, 0, sizeof(listInfo));

   QGYOLJBL (receiver, sizeof(receiver), &listInfo, DIAG_MAX_MSGS,
             &select, sizeof(select), &apiErr);
   if (apiErr.ec.Bytes_Available > 0) return;

   // newest first: stop at the first message older than the statement
   pRec = (Qgy_Oljbl_RecVar_t *) receiver;
   for (i = 0; i < listInfo.Records_Retd; i++) {
      memcpy (msgKey     , pRec->Date_Sent , 7);
      memcpy (msgKey + 7 , pRec->Time_Sent , 6);
      memcpy (msgKey + 13, pRec->Time_Sent_Microseconds, 6);
      msgKey[19] = '\0';
      if (*fromKey && memcmp (msgKey, fromKey, 19) < 0) break;

      if (memcmp (pRec->Msg_Type, "02", 2) == 0     // diagnostic
      ||  memcmp (pRec->Msg_Type, "14", 2) == 0     // notify
      ||  memcmp (pRec->Msg_Type, "15", 2) == 0     // escape
      ||  memcmp (pRec->Msg_Type, "16", 2) == 0     // notify, not handled
      ||  memcmp (pRec->Msg_Type, "17", 2) == 0) {  // escape, not handled
         Qgy_Oljbl_IDFieldInfo_t * pField = NULL;
         if (pRec->Num_Fields_Retd > 0) {
            pField = (Qgy_Oljbl_IDFieldInfo_t *) (receiver + pRec->Offset_to_Fields_Retd);
         }
         found     [nFound] = pRec;
         foundText [nFound] = pField ? (PUCHAR) (pField + 1) : (PUCHAR) "";
         foundLen  [nFound] = pField ? pField->Data_Length : 0;
         nFound++;
      }
      if (pRec->Offset_to_Next <= 0) break;
      pRec = (Qgy_Oljbl_RecVar_t *) (receiver + pRec->Offset_to_Next);
   }

   memset (&closeErr, 0, sizeof(closeErr));
   closeErr.ec.Bytes_Provided = sizeof(closeErr);
   QGYCLST (listInfo.Request_Handle, &closeErr);

   if (nFound == 0) return;
   pCon->pDiag = nox_NewArray();
   for (i = nFound - 1; i >= 0; i--) {   // oldest first
      nox_ArrayPush (pCon->pDiag, diagMessage (found[i], foundText[i], foundLen[i]), FALSE);
   }
}
