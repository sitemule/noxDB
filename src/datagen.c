// CMD:CRTCMOD
/* ---------------------------------------------------------------
 * Company . . . : System & Method A/S
 * Design  . . . : Niels Liisberg
 * Function  . . : NOX - Serializer from RPGLE structures
 *
 * By     Date       Task    Description
 * NL     09.03.2021 0000000 New program
 * trace:
 * ADDENVVAR QIBM_RPG_DATA_GEN_TRACE VALUE('*STDOUT')
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
#include "parms.h"
#include "strUtil.h"
#include "memUtil.h"
#include "varchar.h"
#include "noxDbUtf8.h"
#include "xlate.h"

#include  "qoar/h/qrntypes"
#include  "qoar/h/qrndtagen"

// NOTE !!! ALL constants are UTF-8
#pragma convert(1252)

// TODO !!! - Check reintrant

static BOOL upperCaseNames = false;
static PNOXNODE * ppRoot;
extern iconv_t xlate_1200_to_1208;

typedef void (*NOX_DATAGEN)();

/*    ---------------------------------------------------------------------------
    Implement;
    https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/rzasm/roaDataGenExample.htm
    https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_73/rzasm/rzasmpdf.pdf
    --------------------------------------------------------------------------- */
void  nox_dataGenMapper (QrnDgParm_T * pParms)
{
    static PNOXNODE pNode;
    static BOOL first = false;


    switch ( pParms->event) {
        case QrnDgEvent_01_StartMultiple    : {
            break;
        }
        case QrnDgEvent_02_EndMultiple      : {
            break;
        }
        case QrnDgEvent_03_Start            : {
            pNode = NULL;
            first = true;
            break;
        }
        case QrnDgEvent_04_End              : {
            break;
        }
        case QrnDgEvent_05_StartStruct      : {
            PNOXNODE pObj;
            UCHAR name [256];
            LONG namelen = XlateBuffer (xlate_1200_to_1208, name , (PUCHAR) &pParms->name.name , pParms->name.len * 2);
            name[namelen] = '\0';

            if (! upperCaseNames) {
                aCamelCase (name, name);
            }

            pObj  = nox_NewObject();
            nox_NodeRename(pObj ,  name);
            nox_NodeInsertChildTail (pNode , pObj);
            pNode = pObj;
            if (first) {
                first = false;
                *ppRoot = pNode;
            };
            break;
        }
        case QrnDgEvent_06_EndStruct        : {
            pNode = nox_GetNodeParent (pNode);
            break;
        }
        case QrnDgEvent_07_StartScalarArray : {
            PNOXNODE pArr;
            UCHAR name [256];
            ULONG namelen = XlateBuffer (xlate_1200_to_1208, name , (PUCHAR) &pParms->name.name , pParms->name.len * 2);
            name[namelen] = '\0';

            if (! upperCaseNames) {
                aCamelCase (name, name);
            }

            pArr = nox_NewArray();
            nox_NodeRename(pArr ,  name);
            nox_NodeInsertChildTail (pNode , pArr);
            pNode = pArr;
            if (first) {
                first = false;
                *ppRoot = pNode;
            };
            break;
        }
        case QrnDgEvent_08_EndScalarArray   : {
            pNode = nox_GetNodeParent (pNode);
            break;
        }
        case QrnDgEvent_09_StartStructArray : {
            PNOXNODE pArr;
            UCHAR name [256];
            ULONG namelen = XlateBuffer(xlate_1200_to_1208, name , (PUCHAR) &pParms->name.name , pParms->name.len * 2);
            name[namelen] = '\0';

            if (! upperCaseNames) {
                aCamelCase (name, name);
            }

            pArr = nox_NewArray();
            nox_NodeRename(pArr ,  name);
            nox_NodeInsertChildTail (pNode , pArr);
            pNode = pArr;
            if (first) {
                first = false;
                *ppRoot = pNode;
            };
            break;
        }
        case QrnDgEvent_10_EndStructArray   : {
            pNode = nox_GetNodeParent (pNode);
            break;
        }
        case QrnDgEvent_11_ScalarValue      : {
            PNOXNODE pValueNode;
            UCHAR value [pParms->u.scalar.valueLenBytes];
            ULONG valuelen;
            PUCHAR pValue = value;
            UCHAR name [256];
            ULONG namelen;
            NODETYPE  type;

            namelen = XlateBuffer (xlate_1200_to_1208, name , (PUCHAR) &pParms->name.name , pParms->name.len * 2);
            name[namelen] = '\0';

            if (! upperCaseNames) {
                aCamelCase (name, name);
            }

            valuelen = XlateBuffer (xlate_1200_to_1208, value , (PUCHAR) pParms->u.scalar.value  , pParms->u.scalar.valueLenBytes);
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

            pValueNode = nox_NodeInsertNew (pNode , RL_LAST_CHILD , name , pValue, type);
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

// ---------------------------------------------------------------------------
// The main entry point for the data generation
// ---------------------------------------------------------------------------
NOX_DATAGEN  nox_DataGen (PNOXNODE * ppNode, PUCHAR optionsP)
{
    PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
    ppRoot = ppNode; // not reentrant

    // TODO - Sysname !!

    return &nox_dataGenMapper;
}
