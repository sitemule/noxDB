/* SYSIFCOPT(*IFSIO) TERASPACE(*YES *NOTSIFC) STGMDL(*SNGLVL)    */
/* ------------------------------------------------------------- */
/* SYSIFCOPT(*IFSIO) OPTION(*EXPMAC *SHOWINC)                    */
/* Program . . . : JXS001                                        */
/* Date  . . . . : 15.02.2016                                    */
/* Design  . . . : Niels Liisberg                                */
/* Function  . . : return one row to CLP command RTXSQLROW       */
/*                                                               */
/*By    Date      PTF    Description                         */
/* NL     15.02.2016         New program                         */
/* ------------------------------------------------------------- */
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <time.h>

#include "ostypes.h"
#include "varchar.h"
#include "utl100.h"
#include "jsonxml.h"

/* ------------------------------------------------------------- */
// manline
/* ------------------------------------------------------------- */
void main (int argc , char * argv[])
{
   PUCHAR   func        = (PUCHAR) argv[1];
   PUCHAR   sqlCmd      = vc2str(  argv[2]);
   PLGL     found       = (PLGL)   argv[3];
   SHORT    colParm     = 4; // The parameter from where the parms begins
   PJXNODE  pRow, pNode;
   PUCHAR   pVal;
   PVARCHAR pCol;


   pRow = jx_sqlResultRow(sqlCmd, NULL);
   if (pRow) { // FOUND
      if (found) *found = ON;
      pNode =  jx_GetNodeChild(pRow);
      while (pNode && colParm < argc ) {
         pVal = jx_GetNodeValuePtr (pNode, NULL);
         pCol = (PVARCHAR) argv[colParm++];
         if (pCol) {
            padncpy(pCol->String , pVal , pCol->Length);
         }
         pNode = jx_GetNodeNext(pNode);
      }
      jx_NodeDelete (pRow);
   } else {
      if (found) *found = OFF;
      while (colParm < argc ) {
         pCol = (PVARCHAR) argv[colParm++];
         if (pCol) {
            memset(pCol->String , ' ' , pCol->Length);
         }
      }
   }
}
