// CMD:CRTCMOD 
/* ------------------------------------------------------------- */
/* Company . . . : Agent Data ApS                                */
/* Design  . . . : Niels Liisberg                                */
/* Description . : Timestamp wrappers                            */
/*                                                               */
/* By     Date       PTF     Description                         */
/* NL     10.06.2004 0000000 New module                          */
/* ------------------------------------------------------------- */
#include <time.h>
#include <stdio.h>
#include <qp0z1170.h>
#include <mimchint.h>
#include "/qsys.lib/QSYSINC.lib/MIH.file/MATTOD.mbr"
#include "OSTYPES.h"
#include "timestamp.h"
/* ------------------------------------------------------------- */
/* Quick conversion of digits in a buffer to integer             */
/* requires valid digits 0 to 9                                  */
/* ------------------------------------------------------------- */
LONG  buf2int  (PUCHAR buf , USHORT len)
{
   LONG res = 0;
   while(len-->0){
       res = res * 10 + (*(buf++) - '0');
   }
   return res;
}
/* ------------------------------------------------------------- */
PUCHAR  ts_tm2isostr (PUCHAR timeStamp , struct tm *timeinfo, ULONG usec)
{
   sprintf(timeStamp ,  "%4d-%02d-%02d-%02d.%02d.%02d.%06d" ,
       timeinfo->tm_year + 1900,
       timeinfo->tm_mon +1,
       timeinfo->tm_mday,
       timeinfo->tm_hour,
       timeinfo->tm_min,
       timeinfo->tm_sec,
       usec
   );
   return timeStamp;
}
/* -------------------------------------------------------------
   returns the current timestamp
   ------------------------------------------------------------- */
PUCHAR  ts_nowstr (PUCHAR timeStamp)
{
   struct timeval tv;
   struct tm *timeinfo;
   _MI_Time systime;

   mattod( systime  );
   Qp0zCvtToTimeval(&tv, systime , QP0Z_CVTTIME_TO_TIMESTAMP);
   timeinfo =   localtime(&tv.tv_sec);
   ts_tm2isostr (timeStamp , timeinfo, tv.tv_usec);
   return timeStamp;
}
/* -------------------------------------------------------------
   returns the current timestamp
   ------------------------------------------------------------- */
PTS  ts_setnow (PTS pts)
{
   UCHAR temp [32];
   memcpy (pts , ts_nowstr (temp) , sizeof(TS));
   return pts;
}
/* -------------------------------------------------------------
   returns the current timestamp  : this is not reintrant
   ------------------------------------------------------------- */
/* removed and replaced by reintrant macro !!!
PTS now(void)
{
   static TS ts;
   return  ts_setnow(&ts);
}
*/
/* -------------------------------------------------------------
   returns the current timestamp on the stack
   ------------------------------------------------------------- */
TS ts_now(void)
{
   TS ts;
   ts_setnow(&ts);
   return ts;
}
/* -----------------------------------------------------------------
   Time ISO timestamp to unix timestamp
   ----------------------------------------------------------------- */
struct tm * ts_iso2tm (struct tm * timeinfo , PTS pTs)
{
    timeinfo->tm_year = buf2int (pTs->year   ,4) - 1900;
    timeinfo->tm_mon  = buf2int (pTs->month  ,2) - 1;
    timeinfo->tm_mday = buf2int (pTs->day    ,2);
    timeinfo->tm_hour = buf2int (pTs->hour   ,2);
    timeinfo->tm_min  = buf2int (pTs->minute ,2);
    timeinfo->tm_sec  = buf2int (pTs->second ,2);
    return timeinfo;
}
/* -----------------------------------------------------------------
   Time stmp to unix time
   ----------------------------------------------------------------- */
time_t ts_iso2unix (PTS pTs )
{
    struct tm timeinfo;
    ts_iso2tm (&timeinfo, pTs);
    return mktime(&timeinfo);
}
/* ----------------------------------------------------------------- */
PUCHAR ts_unix2isostr (PUCHAR iso ,  time_t unix)
{
    struct  tm * timeinfo = localtime ( &unix );
    ts_tm2isostr (iso  , timeinfo, 0);
    return iso;
}
/* ----------------------------------------------------------------- */
/* testcase:
void main()
{
   UCHAR nowStr [32];
   TS   Now = ts_now();
   TS   xx ;
   LONG unix;
   PTS  p  = now();
   p  = now();
   ts_setnow (&xx);
   ts_nowstr (nowStr);
   unix = ts_iso2unix ((PTS) nowStr);
   unix += 10;  // sec;
   ts_unix2isostr (nowStr, unix);
   if (1==1);;
}
   */
