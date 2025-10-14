// CMD:CRTCMOD
/* -------------------------------------------------------------
 * Company . . . : System & Method A/S
 * Design  . . . : Niels Liisberg
 * Function  . . : Assert - internal unit test interface
 *
 * By     Date       Task    Description
 * ------ ---------- ------- -------------------------------------
 * NL     13.10.2026 0000000 New program
 * ------------------------------------------------------------- */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <leod.h>

#include "ostypes.h"
#include "varchar.h"
#include "strUtil.h"
#include "parms.h"
#include "sndpgmmsg.h"


// ---------------------------------------------------------------------------
void nox_Assert (PUCHAR text ,LGL ok)
{
     PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
     ULONG apierr = 0;
     char temp[4096];
     char msgkey [10];
     long stackcount=1;
     int  len;

     // Just "simple" text if no condition
     if (pParms->OpDescList->NbrOfParms == 1) {
          QMHSNDPM (
               "CPF9898",
               QCPFMSG ,
               text ,
               strlen(text) ,
               INFO ,
               "nox_Assert          " ,
               stackcount,
               msgkey ,
               &apierr
          );
     } else if (ok != ON) {

          len = strjoin ( temp, "Assert error: " , text);

          QMHSNDPM (
               "CPF9898",
               QCPFMSG ,
               temp ,
               len ,
               INFO ,
               "nox_Assert          " ,
               stackcount,
               msgkey ,
               &apierr
          );

     }
}
