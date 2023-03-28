/* SYSIFCOPT(*IFSIO) TERASPACE(*YES *TSIFC) STGMDL(*SNGLVL) */
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
#include "jsonxml.h"


#ifdef QOAR_INCLUDE_IFS
#include  <qoar/h/qrndtainto>
#else
#include  "/QSYS.LIB/QOAR.LIB/H.FILE/QRNDTAINTO.MBR"
#endif


static PJXNODE pRoot;
static iconv_t iconvCd;
static BOOL first = true;


// Portotype can not move to generic header since dubble defintion i IBM headers :(
static void  jx_dataIntoMapNode  (PJXNODE pNode, QrnDiParm_T * pParms, SHORT level);

/* --------------------------------------------------------------------------- */
static void  jx_dataIntoMapObject  (PJXNODE pParent, QrnDiParm_T * pParms, SHORT level)
{
    PJXNODE pNode;
    SHORT nextLevel = level +1;

    pParms->env->QrnDiStartStruct (pParms->handle);
    for (pNode = pParent->pNodeChildHead ; pNode ; pNode=pNode->pNodeSibling) {
        if  ( pNode->Name && *pNode->Name > 0) {
            UCHAR name [256];
            LONG namelen = XlateBuffer (iconvCd, name , pNode->Name , strlen(pNode->Name));
            * ((PUSHORT) (name + namelen)) = 0; // Unicode termination
            pParms->env->QrnDiReportName  (pParms->handle , name , namelen);
        }
        jx_dataIntoMapNode (pNode , pParms, nextLevel);
    }
    pParms->env->QrnDiEndStruct (pParms->handle);
}
/* --------------------------------------------------------------------------- */
static void  jx_dataIntoMapArray (PJXNODE pParent, QrnDiParm_T * pParms, SHORT level)
{
    PJXNODE pNode;
    SHORT nextLevel = level +1;

    pParms->env->QrnDiStartArray  (pParms->handle);
    for (pNode = pParent->pNodeChildHead ; pNode ; pNode=pNode->pNodeSibling) {
        jx_dataIntoMapNode (pNode , pParms, nextLevel);
    }
    pParms->env->QrnDiEndArray  (pParms->handle);
}
/* --------------------------------------------------------------------------- */
static void jx_dataIntoMapValue   (PJXNODE pNode, QrnDiParm_T * pParms )
{
    // Has value?
    if (pNode->Value && pNode->Value[0] > '\0') {
        UCHAR value [32768];
        LONG valuelen = XlateBuffer (iconvCd, value , pNode->Value , strlen(pNode->Value));
        * ((PUSHORT) (value + valuelen)) = 0; // Unicode termination
        pParms->env->QrnDiReportValue (pParms->handle , value , valuelen);
    // Else it is some kind of null: Strings are "". Literals will return "null"
    } else {
        // Null handeling - for now : TODO !! What about real NULL
        pParms->env->QrnDiReportValue (pParms->handle , "" , 0);
        /*
        if (pNode->isLiteral) {

        //	pParms->env->QrnDiReportName  (pParms->handle , pNode->Name , strlen(pNode->Name));
        //	pParms->env->QrnDiReportValue (pParms->handle , pNode->Value, strlen(pNode->Value));
        }


        */
    }
}
/* --------------------------------------------------------------------------- */
/* Invalid node types are just jeft out                                          */
/* --------------------------------------------------------------------------- */
static void  jx_dataIntoMapNode  (PJXNODE pNode, QrnDiParm_T * pParms, SHORT level)
{
    if (pNode) {
        switch (pNode->type) {
            case OBJECT:
                jx_dataIntoMapObject  (pNode, pParms, level);
                break;

            case ARRAY:
                jx_dataIntoMapArray   (pNode, pParms, level);
                break;

            case VALUE:
            case POINTER_VALUE:
                jx_dataIntoMapValue   (pNode, pParms);
                break;
        }
    }
}
/* 	---------------------------------------------------------------------------
    --------------------------------------------------------------------------- */
static void   jx_dataIntoMapper (QrnDiParm_T * pParms)
{

    if (first) {
        first = false;
        iconvCd = XlateOpenDescriptor (0, 13488, false);
    }

    pParms->env->QrnDiStart  (pParms->handle);
    jx_dataIntoMapNode (pRoot , pParms , 0 );
    pParms->env->QrnDiFinish (pParms->handle );

}
/* 	---------------------------------------------------------------------------
    --------------------------------------------------------------------------- */
JX_DATAINTO jx_dataInto (PJXNODE pNode)
{
    pRoot = pNode;
    return &jx_dataIntoMapper;
}
