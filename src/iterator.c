// CMD:CRTCMOD
/* ------------------------------------------------------------- *
 * Company . . . : System & Method A/S                           *
 * Design  . . . : Niels Liisberg                                *
 * Function  . . : Iterator                                      *
 *                                                               *
 * By     Date     Task    Description                           *
 * NL     02.06.03 0000000 New program                           *
 * NL     27.02.08 0000510 Allow also no namespace for *:tag     *
 * NL     27.02.08 0000510 nox_NodeCopy                           *
 * NL     13.05.08 0000577 nox_NodeInsert / WriteNote                *
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
#include "varchar.h"
#include "xlate.h"
#include "parms.h"
#include "memUtil.h"
#include "noxDbUtf8.h"


// ---------------------------------------------------------------------------
void  nox_LoadRecursiveList (PNOXNODE pNode, PNOXITERATOR pIter, BOOL first)
{
   while (pNode) {
      if (pIter->length >= pIter->size) {
         pIter->size += 256;
         pIter->list = realloc (pIter->list , sizeof(PNOXNODE) * pIter->size);
      }
      pIter->list [pIter->length] = pNode;
      pIter->length++;
      nox_LoadRecursiveList (pNode->pNodeChildHead , pIter, FALSE);
      pNode = first ? NULL : pNode->pNodeSiblingNext;
   }
}
// ---------------------------------------------------------------------------
NOXITERATOR nox_SetRecursiveIterator (PNOXNODE pNode , PUCHAR path)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   NOXITERATOR iter;

   if (path && *path > BLANK) {
      pNode = nox_GetNode  (pNode, path );
   }

   memset(&iter , 0 , sizeof(NOXITERATOR));
   iter.isFirst = ON;
   iter.isLast  = ON;
   iter.isList  = ON;
   iter.isRecursive = ON;;
   iter.root = pNode;
   iter.size = 0;
   nox_LoadRecursiveList (pNode, &iter, TRUE);
   iter.this = (iter.length > 0) ? iter.list [0] : NULL;
   return iter;
}
// ---------------------------------------------------------------------------
NOXITERATOR nox_SetRecursiveIteratorVC (PNOXNODE pNode , PLVARCHAR pathP)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PUCHAR path = (pParms->OpDescList->NbrOfParms == 2 && pathP) ? plvc2str(pathP) : NULL;

   return nox_SetRecursiveIterator (pNode , path);
}
// ---------------------------------------------------------------------------
NOXITERATOR nox_SetIterator (PNOXNODE pNode , PUCHAR path)
{
   NOXITERATOR iter;

   if (path && *path > BLANK) {
      pNode = nox_GetNode  (pNode, path );
   }
   memset(&iter , 0 , sizeof(NOXITERATOR));
   iter.isFirst = ON;
   iter.isLast  = ON;
   iter.isList  = OFF;
   iter.isRecursive = OFF;
   iter.root = pNode;
   if (pNode) {
      if (pNode->pNodeChildHead) {
         iter.isList = ON;
         iter.this = pNode->pNodeChildHead;
         iter.next = iter.this->pNodeSiblingNext;
         iter.isLast  = iter.next ? OFF:ON;
         iter.length = pNode->Count;
      } else if (pNode->Value) {
         iter.this = pNode;
      }
   }
   return iter;
}
// ---------------------------------------------------------------------------
NOXITERATOR nox_SetIteratorVC (PNOXNODE pNode , PLVARCHAR pathP)
{
   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PUCHAR path = (pParms->OpDescList->NbrOfParms == 2 && pathP ) ? plvc2str(pathP) : NULL;
   return nox_SetIterator (pNode , path);
}
/* ---------------------------------------------------------------------------
   Return ON for each entry in the list..
   --------------------------------------------------------------------------- */
LGL nox_ForEach (PNOXITERATOR pIter , PLVARCHAR filterP)
{

   PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
   PUCHAR filter = (pParms->OpDescList->NbrOfParms >= 2 && pathP ) ? plvc2str(filterP) : NULL;

   if (! pIter || ! pIter->this) return OFF;

   // Break by user? Cleanup and break
   if (pIter->doBreak == ON) {
      memFree(&pIter->list);
      return OFF;
   }

   // Filter  - used by XML , that can have mixed elements at same level
   // TODO test this !!
   if (filter) {
      PNOXNODE pTemp = pIter->this;
      while (pTemp && 0 != astricmp (pTemp->Name ,filter )) {
         pTemp = pTemp->pNodeSiblingNext;
      }
      if (pTemp == NULL) {
         return OFF;
      }
      pIter->this = pIter->next;
      pIter->next = pIter->next->pNodeSiblingNext;
      pIter->isLast  = pIter->next ? OFF:ON;
      return ON;
   }

   // The first Node is already set up in the initializer of the iterator
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
      pIter->next = pIter->next->pNodeSiblingNext;
      pIter->isLast  = pIter->next ? OFF:ON;
   }
   pIter->count ++;
   return ON;
}


