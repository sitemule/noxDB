/* SYSIFCOPT(*IFSIO) TERASPACE(*YES *TSIFC) STGMDL(*SNGLVL) */
/* --------------------------------------------------------------- *
 * Company . . . : System & Method A/S                             *
 * Design  . . . : Niels Liisberg                                  *
 * Function  . . : NOX - Serializer from RPGLE structures          *
 *                                                                 *
 * By     Date       Task    Description                           *
 * NL     09.03.2021 0000000 New program                           *
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
#include "xlate.h"

#ifdef QOAR_INCLUDE_IFS
#include  <qoar/h/qrntypes>
#include  <qoar/h/qrndtagen>
#else
#include  "/QSYS.LIB/QOAR.LIB/H.FILE/QRNTYPES.MBR"
#include  "/QSYS.LIB/QOAR.LIB/H.FILE/QRNDTAGEN.MBR"
#endif 


static PJXNODE * ppRoot;
static PXLATEDESC pXd = NULL;

typedef void (*JX_DATAGEN)();

/* 	---------------------------------------------------------------------------
    Implement;
    https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/rzasm/roaDataGenExample.htm
    https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_73/rzasm/rzasmpdf.pdf
    --------------------------------------------------------------------------- */
void  jx_dataGenMapper (QrnDgParm_T * pParms)
{
    static PJXNODE pNode;
    static BOOL first;

    switch ( pParms->event) {
        case QrnDgEvent_01_StartMultiple    : {
            break;
        }
        case QrnDgEvent_02_EndMultiple      : {
            break;
        }
        case QrnDgEvent_03_Start            : {

            if (pXd == NULL) {
                pXd = XlateXdOpen (13488 , 0);
            }
            pNode = NULL;
            first = true;
            break;
        }
        case QrnDgEvent_04_End              : {
            break;
        }
        case QrnDgEvent_05_StartStruct      : {
            PJXNODE pObj;
            UCHAR name [256];
            ULONG namelen = XlateXdBuf(pXd, name , (PUCHAR) &pParms->name.name , pParms->name.len * 2);
            name[namelen] = '\0';
            
            pObj  = jx_NewObject(NULL);
            jx_NodeRename(pObj ,  name);
            jx_NodeAddChildTail (pNode , pObj);
            pNode = pObj;
            if (first) {
                first = false;
                *ppRoot = pNode;
            };
            break;
        }
        case QrnDgEvent_06_EndStruct        : {
            pNode = jx_GetNodeParent (pNode);
            break;
        }
        case QrnDgEvent_07_StartScalarArray : {
            PJXNODE pArr;
            UCHAR name [256];
            ULONG namelen = XlateXdBuf(pXd, name , (PUCHAR) &pParms->name.name , pParms->name.len * 2);
            name[namelen] = '\0';

            pArr = jx_NewArray(NULL);
            jx_NodeRename(pArr ,  name);
            jx_NodeAddChildTail (pNode , pArr);  
            pNode = pArr;
            if (first) {
                first = false;
                *ppRoot = pNode;
            };
            break;
        }
        case QrnDgEvent_08_EndScalarArray   : {
            pNode = jx_GetNodeParent (pNode);
            break;
        }
        case QrnDgEvent_09_StartStructArray : {
            PJXNODE pArr;
            UCHAR name [256];
            ULONG namelen = XlateXdBuf(pXd, name , (PUCHAR) &pParms->name.name , pParms->name.len * 2);
            name[namelen] = '\0';

            pArr = jx_NewArray(NULL);
            jx_NodeRename(pArr ,  name);
            jx_NodeAddChildTail (pNode , pArr);
            pNode = pArr; 
            if (first) {
                first = false;
                *ppRoot = pNode;
            };
            break;
        }
        case QrnDgEvent_10_EndStructArray   : {
            pNode = jx_GetNodeParent (pNode);
            break;
        }
        case QrnDgEvent_11_ScalarValue      : {
            PJXNODE pValueNode;
            UCHAR value [32766];
            ULONG valuelen;
            PUCHAR pValue = value;
            UCHAR name [256];
            ULONG namelen;
            NODETYPE  type;
            
            namelen = XlateXdBuf(pXd, name , (PUCHAR) &pParms->name.name , pParms->name.len * 2);
            name[namelen] = '\0';

            valuelen = XlateXdBuf(pXd, value , (PUCHAR) pParms->u.scalar.value  , pParms->u.scalar.valueLenBytes);
            value[valuelen] = '\0';

            switch (pParms->u.scalar.dataType) {
                case QrnDatatype_Indicator :
                    pValue = (*value == '1') ? "true" : "false";
                    type = LITERAL;
                    break;

                // Numeric  
                case QrnDatatype_Decimal  :
                case QrnDatatype_Integer  :
                case QrnDatatype_Unsigned :
                case QrnDatatype_Float    : 
                    if (*pValue  == '+') pValue ++; // Skip the + sign
                    type = LITERAL;
                    break;
                default: 
                    type = VALUE;
                    break;
            }

            pValueNode = jx_NodeAdd (pNode , RL_LAST_CHILD , name , pValue, type);
            if (first) {
                first = false;
                *ppRoot = pValueNode;
            };
            break;
        }
        case QrnDgEvent_12_Terminate        : {
            break;
        }
    }
}

/* 	---------------------------------------------------------------------------
    --------------------------------------------------------------------------- */
JX_DATAGEN jx_dataGen (PJXNODE * ppNode) 
{
    ppRoot = ppNode; // not reentrant 
    return &jx_dataGenMapper;
}
