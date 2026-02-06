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

#include "qoar/h/qrndtainto"

#include "ostypes.h"
#include "sndpgmmsg.h"
#include "trycatch.h"
#include "parms.h"
#include "strUtil.h"
#include "memUtil.h"
#include "varchar.h"
#define NOX_BUILD
#include "noxDbUtf8.h"


static PNOXNODE pRoot;
extern iconv_t xlate_1208_to_1200;
static BOOL first = true;

// TODO !!! ensure UTF-8

// Prototype can not move to generic header since dubble defintion i IBM headers :(
static void  nox_DataIntoMapNode  (PNOXNODE pNode, QrnDiParm_T * pParms, SHORT level);

/* --------------------------------------------------------------------------- */
static void  nox_DataIntoMapObject  (PNOXNODE pParent, QrnDiParm_T * pParms, SHORT level)
{
    PNOXNODE pNode;
    SHORT nextLevel = level +1;

    pParms->env->QrnDiStartStruct (pParms->handle);
    for (pNode = pParent->pNodeChildHead ; pNode ; pNode=pNode->pNodeSiblingNext) {
        if  ( pNode->Name && *pNode->Name > 0) {
            // TODO !! Only report names for nodes  - not null
            // TODO !! Implement real null support when IBM has the API ready
            if (pNode->Value || pNode->type == NOX_OBJECT || pNode->type == NOX_ARRAY) {
                UCHAR name [256];
                LONG namelen = XlateBuffer (xlate_1208_to_1200, name , pNode->Name , strlen(pNode->Name));
                * ((PUSHORT) (name + namelen)) = 0; // Unicode termination
                pParms->env->QrnDiReportName  (pParms->handle , name , namelen);
            }
        }
        nox_DataIntoMapNode (pNode , pParms, nextLevel);
    }
    pParms->env->QrnDiEndStruct (pParms->handle);
}
/* --------------------------------------------------------------------------- */
static void  nox_DataIntoMapArray (PNOXNODE pParent, QrnDiParm_T * pParms, SHORT level)
{
    PNOXNODE pNode;
    SHORT nextLevel = level +1;

    pParms->env->QrnDiStartArray  (pParms->handle);
    for (pNode = pParent->pNodeChildHead ; pNode ; pNode=pNode->pNodeSiblingNext) {
        nox_DataIntoMapNode (pNode , pParms, nextLevel);
    }
    pParms->env->QrnDiEndArray  (pParms->handle);
}
/* --------------------------------------------------------------------------- */
static void nox_DataIntoMapValue   (PNOXNODE pNode, QrnDiParm_T * pParms )
{
    // Has value?
    if (pNode->Value) {
        UCHAR value [32768];
        LONG valuelen = XlateBuffer (xlate_1208_to_1200, value , pNode->Value , strlen(pNode->Value));
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
/* Invalid node types are just jeft out                                        */
/* --------------------------------------------------------------------------- */
static void  nox_DataIntoMapNode  (PNOXNODE pNode, QrnDiParm_T * pParms, SHORT level)
{
    if (pNode) {
        switch (pNode->type) {
            case NOX_OBJECT:
                nox_DataIntoMapObject  (pNode, pParms, level);
                break;

            case NOX_ARRAY:
                nox_DataIntoMapArray   (pNode, pParms, level);
                break;

            case NOX_VALUE:
            case NOX_POINTER:
                nox_DataIntoMapValue   (pNode, pParms);
                break;
        }
    }
}
/*    ---------------------------------------------------------------------------
    --------------------------------------------------------------------------- */
static void   nox_DataIntoMapper (QrnDiParm_T * pParms)
{

    // if (first) {
    //     first = false;
    //     xlate_1208_to_1200 = XlateOpenDescriptor (0, 13488, false);
    // }

    pParms->env->QrnDiStart  (pParms->handle);
    nox_DataIntoMapNode (pRoot , pParms , 0 );
    pParms->env->QrnDiFinish (pParms->handle );

}
/*    ---------------------------------------------------------------------------
    --------------------------------------------------------------------------- */
NOX_DATAINTO nox_DataInto (PNOXNODE pNode)
{
    pRoot = pNode;
    return &nox_DataIntoMapper;
}
