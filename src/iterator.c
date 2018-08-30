/* SYSIFCOPT(*IFSIO) TERASPACE(*YES *TSIFC) STGMDL(*SNGLVL) */
/* ------------------------------------------------------------- *
 * Company . . . : System & Method A/S                           *
 * Design  . . . : Niels Liisberg                                *
 * Function  . . : Iterator                                      *
 *                                                               *
 * By     Date     Task    Description                           *
 * NL     02.06.03 0000000 New program                           *
 * NL     27.02.08 0000510 Allow also no namespace for *:tag     *
 * NL     27.02.08 0000510 jx_NodeCopy                           *
 * NL     13.05.08 0000577 jx_NodeAdd / WriteNote                *
 * NL     13.05.08 0000577 Support for refference location       *
 * ------------------------------------------------------------- */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h>
#include <leod.h>
#include <decimal.h>
#include <wchar.h>
// #include <errno.h>

#include <sys/stat.h>
#include "ostypes.h"
#include "xlate.h"
#include "jsonxml.h"
#include "parms.h"
#include "rtvsysval.h"
#include "utl100.h"
#include "mem001.h"
#include "varchar.h"


/* ---------------------------------------------------------------------------
   --------------------------------------------------------------------------- */
JXITERATOR jx_SetRecursiveIterator (PJXNODE pNode , PUCHAR path)
{
    PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
    JXITERATOR iter;

    if (pParms->OpDescList->NbrOfParms == 2 && path && *path > ' ') {
       pNode = jx_GetNode  (pNode, path );
    }

    memset(&iter , 0 , sizeof(JXITERATOR));
    iter.isFirst = ON;
    iter.isLast  = ON;
    iter.isList  = ON;
    iter.isRecursive = ON;;
    iter.root = pNode;
    iter.size = 0;
    jx_LoadRecursiveList (pNode, &iter, TRUE);
    iter.this = (iter.length > 0) ? iter.list [0] : NULL;
    return iter;
}
/* ---------------------------------------------------------------------------
   --------------------------------------------------------------------------- */
JXITERATOR jx_SetIterator (PJXNODE pNode , PUCHAR path)
{
    PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
    JXITERATOR iter;

    if (pParms->OpDescList->NbrOfParms == 2 && path && *path > ' ') {
       pNode = jx_GetNode  (pNode, path );
    }
    memset(&iter , 0 , sizeof(JXITERATOR));
    iter.isFirst = ON;
    iter.isLast  = ON;
    iter.isList  = OFF;
    iter.isRecursive = OFF;
    iter.root = pNode;
    if (pNode) {
      if (pNode->pNodeChildHead) {
         iter.isList = ON;
         iter.this = pNode->pNodeChildHead;
         iter.next = iter.this->pNodeSibling;
         iter.isLast  = iter.next ? OFF:ON;
         iter.length = pNode->Count;
      } else if (pNode->Value) {
         iter.this = pNode;
      }
    }
    return iter;
}
/* ---------------------------------------------------------------------------
   Return ON for each entry in the list..
   --------------------------------------------------------------------------- */
LGL jx_ForEach (PJXITERATOR pIter)
{
    if (! pIter || ! pIter->this) return OFF;

    // Break by user? Cleanup and break
    if (pIter->doBreak == ON) {
       memFree(&pIter->list);
       return OFF;
    }

    // The first Nodeent is already set up in the initializer of the iterator
    if (pIter->count == 0) { // Note the "isFirst" flag is for our client - not for this logic
      pIter->count = 1;
      return ON;
    }

    if (pIter->isFirst == ON) {
       pIter->isFirst = OFF;
      *pIter->comma.String = ',';
       pIter->comma.Length = 1;
    }

    if (pIter->isRecursive == ON) {
      if (pIter->count == pIter->length) {
         free (pIter->list);
         return OFF;
      }
      pIter->this = pIter->list[pIter->count];
      if (pIter->count == pIter->length-1)  {
         pIter->isLast = ON;
      }
    } else {
      if (! pIter->next) return OFF;
      pIter->this = pIter->next;
      pIter->next = pIter->next->pNodeSibling;
      pIter->isLast  = pIter->next ? OFF:ON;
    }
    pIter->count ++;
    return ON;
}


