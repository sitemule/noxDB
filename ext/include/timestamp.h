#ifndef TIMESTAMP_H
#define TIMESTAMP_H
#include <decimal.h>
#include "ostypes.h"

typedef _Packed struct {
    UCHAR year   [4];
    UCHAR dash1   ;
    UCHAR month  [2];
    UCHAR dash2   ;
    UCHAR day    [2];
    UCHAR dash3   ;
    UCHAR hour   [2];
    UCHAR dot1    ;
    UCHAR minute [2];
    UCHAR dot2    ;
    UCHAR second [2];
    UCHAR dot3    ;
    UCHAR usec   [6];
} TS , *PTS;

#define TIMESTAMP_LOW_VALUE ("0001-01-01-00.00.00.000000")
#define TIMESTAMP_HIGH_VALUE ("9999-12-31-23.59.59.999999")

/*
#pragma map (CurrentTimeStamp , "CURTS")
#pragma linkage (CurrentTimeStamp , OS)
void CurrentTimeStamp  (PTS timestamp);
*/

/* C-Prototypes */
PUCHAR  ts_nowstr (PUCHAR timeStamp);
TS      ts_now(void);
PTS     ts_setnow (PTS pts);
#define  now()  ts_nowstr(TIMESTAMP_LOW_VALUE)
#define  CurrentTimeStamp(a) ts_setnow((PTS) a)
decimal (15) ts2sec (PTS pTs);
PUCHAR  ts_tm2isostr (PUCHAR iso  , struct tm *timeinfo, ULONG usec) ;
struct tm * ts_iso2tm (struct tm * timeinfo , PTS pTs);
time_t ts_iso2unix (PTS pTs ) ;
PUCHAR ts_unix2isostr (PUCHAR iso ,  time_t unix);
#endif