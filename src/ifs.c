// CMD:CRTCMOD
/* -------------------------------------------------------------
 * Company . . . : System & Method A/S
 * Design  . . . : Niels Liisberg
 * Function  . . : NOX - main service program API exports
 *
 * By     Date     Task    Description
 * ------ -------- ------- -------------------------------------
 * NL     02.06.03 0000000 New program
 * NL     27.02.08 0000510 Allow also no namespace for *:tag
 * NL     27.02.08 0000510 nox_NodeCopy
 * NL     13.05.08 0000577 nox_NodeInsert / WriteNote
 * NL     13.05.08 0000577 Support for refference location
 * NL     01.06.18 0001000 noxdb2 version 2 implementation
 *
 *
 * ------------------------------------------------------------- */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <leod.h>

#include "ostypes.h"
#include "varchar.h"
#include "parms.h"

// ---------------------------------------------------------------------------
void nox_WriteStrStmf  (PLVARCHAR data,PUCHAR file , LGL appendP)
{
     PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
     BOOL append = (pParms->OpDescList->NbrOfParms >= 3 && appendP == ON);

     FILE * f;
     int l;
     f = fopen(file , append ? "ab,o_ccsid=1208" : "wb,o_ccsid=1208");
     l = fwrite (data->String, 1 , data->Length , f);
     fclose(f);
}
