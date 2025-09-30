// CMD:CRTCMOD
/* --------------------------------------------------------------- *
 * Company . . . : System & Method A/S                             *
 * Design  . . . : Niels Liisberg                                  *
 * Function  . . : NOX - JSON serializer                           *
 *                                                                 *
 * By     Date       Task    Description                           *
 * NL     02.03.2021 0000000 New program                           *
 * --------------------------------------------------------------- */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h>
#include <iconv.h>


#include <sys/stat.h>
#include "ostypes.h"
#include "sndpgmmsg.h"
#include "trycatch.h"
#include "rtvsysval.h"
#include "parms.h"
#include "utl100.h"
#include "mem001.h"
#include "varchar.h"
#include "noxDbUtf8.h"
#include "qoar/qrndtainto.h"


static PJXNODE pRoot;
static iconv_t iconvCd;
static BOOL first = true;

// TODO !!! ensure UTF-8

// Portotype can not move to generic header since dubble defintion i IBM headers :(
static void  nox_dataIntoMapNode  (PJXNODE pNode, QrnDiParm_T * pParms, SHORT level);

/* --------------------------------------------------------------------------- */
static void  nox_dataIntoMapObject  (PJXNODE pParent, QrnDiParm_T * pParms, SHORT level)
{
    PJXNODE pNode;
    SHORT nextLevel = level +1;

    pParms->env->QrnDiStartStruct (pParms->handle);
    for (pNode = pParent->pNodeChildHead ; pNode ; pNode=pNode->pNodeSiblingNext) {
        if  ( pNode->Name && *pNode->Name > 0) {
            // TODO !! Only report names for nodes  - not null
            // TODO !! Implement real null support when IBM has the API ready
            if (pNode->Value || pNode->type == OBJECT || pNode->type == ARRAY) {
                UCHAR name [256];
                LONG namelen = XlateBuffer (iconvCd, name , pNode->Name , strlen(pNode->Name));
                * ((PUSHORT) (name + namelen)) = 0; // Unicode termination
                pParms->env->QrnDiReportName  (pParms->handle , name , namelen);
            }
        }
        nox_dataIntoMapNode (pNode , pParms, nextLevel);
    }
    pParms->env->QrnDiEndStruct (pParms->handle);
}
/* --------------------------------------------------------------------------- */
static void  nox_dataIntoMapArray (PJXNODE pParent, QrnDiParm_T * pParms, SHORT level)
{
    PJXNODE pNode;
    SHORT nextLevel = level +1;

    pParms->env->QrnDiStartArray  (pParms->handle);
    for (pNode = pParent->pNodeChildHead ; pNode ; pNode=pNode->pNodeSiblingNext) {
        nox_dataIntoMapNode (pNode , pParms, nextLevel);
    }
    pParms->env->QrnDiEndArray  (pParms->handle);
}
/* --------------------------------------------------------------------------- */
static void nox_dataIntoMapValue   (PJXNODE pNode, QrnDiParm_T * pParms )
{
    // Has value?
    if (pNode->Value) {
        UCHAR value [32768];
        LONG valuelen = XlateBuffer (iconvCd, value , pNode->Value , strlen(pNode->Value));
        * ((PUSHORT) (value + valuelen)) = 0; // Unicode termination
        pParms->env->QrnDiReportValue (pParms->handle , value , valuelen);
    // Else it is some kind of null: Strings are "". Literals will return "null"
    } else {
        // Null handeling - for now : TODO !! What about real NULL
        // For now :
        // 1) Since "" is not allowed for numeric / dates
        // 2) and NULL will return "pointer not set"
        // Then it id better to simpy
        // Not do anything an rely of the host structure has initialized fields:

        // pParms->env->QrnDiReportValue (pParms->handle , "" , 0);
    }
}
/* --------------------------------------------------------------------------- */
/* Invalid node types are just jeft out                                          */
/* --------------------------------------------------------------------------- */
static void  nox_dataIntoMapNode  (PJXNODE pNode, QrnDiParm_T * pParms, SHORT level)
{
    if (pNode) {
        switch (pNode->type) {
            case OBJECT:
                nox_dataIntoMapObject  (pNode, pParms, level);
                break;

            case ARRAY:
                nox_dataIntoMapArray   (pNode, pParms, level);
                break;

            case VALUE:
            case POINTER_VALUE:
                nox_dataIntoMapValue   (pNode, pParms);
                break;
        }
    }
}
/*    ---------------------------------------------------------------------------
    --------------------------------------------------------------------------- */
static void   nox_dataIntoMapper (QrnDiParm_T * pParms)
{

    if (first) {
        first = false;
        iconvCd = XlateOpenDescriptor (0, 13488, false);
    }

    pParms->env->QrnDiStart  (pParms->handle);
    nox_dataIntoMapNode (pRoot , pParms , 0 );
    pParms->env->QrnDiFinish (pParms->handle );

}
/*    ---------------------------------------------------------------------------
    --------------------------------------------------------------------------- */
nox_DATAINTO nox_dataInto (PJXNODE pNode)
{
    pRoot = pNode;
    return &nox_dataIntoMapper;
}
