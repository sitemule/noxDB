/* SYSIFCOPT(*IFSIO) TERASPACE(*YES *TSIFC) STGMDL(*SNGLVL) */
/* ------------------------------------------------------------- *
 * Company . . . : System & Method A/S                           *
 * Design  . . . : Niels Liisberg                                *
 * Function  . . : Segments                                      *
 *                                                               *
 *By    Date    Task   Description                           *
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

static PJXSEGMENT pSegment  = NULL;
static JXSEGMENT  Segments[16];


// ---------------------------------------------------------------------------
// Return the data segment pointer
// ---------------------------------------------------------------------------
PJXSEGMENT jx_SegmentSelectNo(SHORT  i)
{
    pSegment = &Segments[i];
    return pSegment;
}
// ---------------------------------------------------------------------------
// Dispose all nodes residing in the datasegment
// ---------------------------------------------------------------------------
VOID jx_SegmentDispose(PJXSEGMENT pSeg)
{
    int i ;
    for (i=0;i<pSeg->nodeCount; i++) {
        PJXNODE pNode = pSeg->nodeArray[i];
        jx_NodeFreeNodeOnly (pNode);
    }
    memFree(&pSeg->nodeArray);
    pSeg->nodeCount =0;
    pSegment = NULL;
}
// ---------------------------------------------------------------------------
// If segments are active, we add the node to the node array in the list
// ---------------------------------------------------------------------------
void SegmentNodeAdd (PJXNODE pNode)
{
   int maxNodes;
   if (pSegment == NULL) return; // Segemnts are not active

   // enshure space in the segment array
   maxNodes = memSize(pSegment->nodeArray) / sizeof(PJXNODE);
   if (pSegment->nodeCount == maxNodes)   {
      int newSize = memSize(pSegment->nodeArray) + 8000  * sizeof(PJXNODE);
      memRealloc(&pSegment->nodeArray ,  newSize );
   }
   pSegment->nodeArray[pSegment->nodeCount++] = pNode;

}
// ---------------------------------------------------------------------------
// Remove the node from the memory segment where it belongs
// ---------------------------------------------------------------------------
void  SegmentNodeDelete(PJXNODE pNode)
{
   int i;

   if  (pSegment == NULL) return; // Segments are not active

   for (i=0;i<pSegment->nodeCount; i++) {
      if (pNode == pSegment->nodeArray[i]) {
         int bytestomove = memSize(pSegment->nodeArray) - ( (i+1) * sizeof(PJXNODE));
         memmove(&pSegment->nodeArray[i] , &pSegment->nodeArray[i+1] , bytestomove);
         pSegment->nodeCount--;
         return;
      }
   }
}


