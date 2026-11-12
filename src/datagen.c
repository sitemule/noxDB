/* SYSIFCOPT(*IFSIO) TERASPACE(*YES *TSIFC) STGMDL(*SNGLVL) */
/* --------------------------------------------------------------- *
 * Company . . . : System & Method A/S                             *
 * Design  . . . : Niels Liisberg                                  *
 * Function  . . : NOX - Serializer from RPGLE structures          *
 *                                                                 *
 * By     Date       Task    Description                           *
 * NL     09.03.2021 0000000 New program                           *
 *        10.2026            countsuffix option: array length taken *
 *                           from sibling field <array><suffix>      *
 *        10.2026            toplength option: limit the root array  *
 *                           to n elements, n passed in the options  *
 *        10.2026            performance: limits applied while        *
 *                           generating, O(n) trimming               *
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
static iconv_t iconvCd;
static UCHAR countSuffix [64] = "";
static LONG  topLength = -1;      // -1 = not given

static void applyCountSuffix (PJXNODE pNode);
static void trimArray (PJXNODE pArr, LONG n);
static PJXNODE findCountNode (PJXNODE pObj, PUCHAR arrName);
static BOOL getCountValue (PJXNODE pCount, LONG * pN);

// ---------------------------------------------------------------------------
// Limits applied while generating:
// For every open array we keep the max number of elements (from "toplength"
// for the root array, or from a <array><suffix> field that was generated
// BEFORE the array). Elements beyond the limit are skipped - no nodes are
// built for them. A length field that FOLLOWS the array is handled when the
// generation ends (applyCountSuffix).
// ---------------------------------------------------------------------------
#define MAX_ARRAY_DEPTH 64
typedef struct _ARRLIMIT {
    PJXNODE pArr;
    LONG    limit;      // -1 = no limit
    LONG    count;      // elements accepted so far
} ARRLIMIT;
static ARRLIMIT arrStack [MAX_ARRAY_DEPTH];
static int      arrTop = -1;     // index of the innermost open array
static LONG     skipDepth = 0;   // > 0 while skipping an element's events

// Is the next element of the current array (pNode) within the limit ?
static BOOL acceptElement (PJXNODE pNode)
{
    ARRLIMIT * pl;
    if (pNode == NULL || pNode->type != ARRAY) return true;
    if (arrTop < 0 || arrStack[arrTop].pArr != pNode) return true;
    pl = &arrStack[arrTop];
    if (pl->limit >= 0 && pl->count >= pl->limit) return false;
    pl->count++;
    return true;
}
// Register a new open array with its limit
static void pushArray (PJXNODE pArr, PJXNODE pParent, BOOL isRoot)
{
    LONG limit = -1;
    if (isRoot) {
        limit = topLength;
    } else if (countSuffix[0] > '\0' && pParent && pParent->type == OBJECT
           &&  pArr->Name && pArr->Name[0] > '\0') {
        PJXNODE pCount = findCountNode (pParent, pArr->Name);
        LONG n;
        if (pCount && getCountValue (pCount, &n)) {
            limit = n;
        }
    }
    if (arrTop < MAX_ARRAY_DEPTH - 1) {
        arrTop++;
        arrStack[arrTop].pArr  = pArr;
        arrStack[arrTop].limit = limit;
        arrStack[arrTop].count = 0;
    }
}
static void popArray (PJXNODE pArr)
{
    if (arrTop >= 0 && arrStack[arrTop].pArr == pArr) {
        arrTop--;
    }
}

typedef void (*JX_DATAGEN)();

/* 	---------------------------------------------------------------------------
    Implement;
    https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/rzasm/roaDataGenExample.htm
    https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_73/rzasm/rzasmpdf.pdf
    --------------------------------------------------------------------------- */
void  jx_dataGenMapper (QrnDgParm_T * pParms)
{
    static PJXNODE pNode;
    static BOOL first = false;
    static BOOL buildIconv  = true;

    if (buildIconv) {
        buildIconv  = false;
        iconvCd = XlateOpenDescriptor (13488, 0 , false);
    }

    // Skipping an element beyond the array limit: only track the nesting
    if (skipDepth > 0) {
        switch ( pParms->event) {
            case QrnDgEvent_05_StartStruct      :
            case QrnDgEvent_07_StartScalarArray :
            case QrnDgEvent_09_StartStructArray :
                skipDepth++;
                return;
            case QrnDgEvent_06_EndStruct        :
            case QrnDgEvent_08_EndScalarArray   :
            case QrnDgEvent_10_EndStructArray   :
                skipDepth--;
                return;
            case QrnDgEvent_11_ScalarValue      :
                return;
            default:
                skipDepth = 0;   // should not happen - resume normally
                break;
        }
    }

    switch ( pParms->event) {
        case QrnDgEvent_01_StartMultiple    : {
            break;
        }
        case QrnDgEvent_02_EndMultiple      : {
            break;
        }
        case QrnDgEvent_03_Start            : {
            arrTop = -1;
            skipDepth = 0;
            pNode = NULL;
            first = true;
            break;
        }
        case QrnDgEvent_04_End              : {
            // Post-process: trim arrays to the length given in <array><suffix>
            // and remove the length field from the output
            if (ppRoot != NULL && *ppRoot != NULL) {
                // Root array limited by the "toplength" option
                if (topLength >= 0 && (*ppRoot)->type == ARRAY) {
                    trimArray (*ppRoot, topLength);
                }
                applyCountSuffix (*ppRoot);
            }
            break;
        }
        case QrnDgEvent_05_StartStruct      : {
            PJXNODE pObj;
            UCHAR name [256];
            LONG namelen;
            if (!acceptElement (pNode)) {   // element beyond the array limit
                skipDepth = 1;
                break;
            }
            namelen = XlateBuffer (iconvCd, name , (PUCHAR) &pParms->name.name , pParms->name.len * 2);
            name[namelen] = '\0';

            pObj  = jx_NewObject(NULL);
            jx_NodeRename(pObj ,  name);
            jx_NodeInsertChildTail (pNode , pObj);
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
            ULONG namelen;
            BOOL  isRoot = first;
            if (!acceptElement (pNode)) {
                skipDepth = 1;
                break;
            }
            namelen = XlateBuffer (iconvCd, name , (PUCHAR) &pParms->name.name , pParms->name.len * 2);
            name[namelen] = '\0';

            pArr = jx_NewArray(NULL);
            jx_NodeRename(pArr ,  name);
            jx_NodeInsertChildTail (pNode , pArr);
            pushArray (pArr, pNode, isRoot);
            pNode = pArr;
            if (first) {
                first = false;
                *ppRoot = pNode;
            };
            break;
        }
        case QrnDgEvent_08_EndScalarArray   : {
            popArray (pNode);
            pNode = jx_GetNodeParent (pNode);
            break;
        }
        case QrnDgEvent_09_StartStructArray : {
            PJXNODE pArr;
            UCHAR name [256];
            ULONG namelen;
            BOOL  isRoot = first;
            if (!acceptElement (pNode)) {
                skipDepth = 1;
                break;
            }
            namelen = XlateBuffer(iconvCd, name , (PUCHAR) &pParms->name.name , pParms->name.len * 2);
            name[namelen] = '\0';

            pArr = jx_NewArray(NULL);
            jx_NodeRename(pArr ,  name);
            jx_NodeInsertChildTail (pNode , pArr);
            pushArray (pArr, pNode, isRoot);
            pNode = pArr;
            if (first) {
                first = false;
                *ppRoot = pNode;
            };
            break;
        }
        case QrnDgEvent_10_EndStructArray   : {
            popArray (pNode);
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

            if (!acceptElement (pNode)) {   // array element beyond the limit
                break;
            }

            namelen = XlateBuffer (iconvCd, name , (PUCHAR) &pParms->name.name , pParms->name.len * 2);
            name[namelen] = '\0';

            valuelen = XlateBuffer (iconvCd, value , (PUCHAR) pParms->u.scalar.value  , pParms->u.scalar.valueLenBytes);
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

// ---------------------------------------------------------------------------
// Get a parameter value from the options string
// The options string is expected to be in the format: "countsuffix=_length,other=5678"
// If the parameter is not found, parmValue is set to an empty string.
// The value is a single word (no spaces or commas), max maxLen-1 chars
// ---------------------------------------------------------------------------
static void getParmValue (PUCHAR parmValue , LONG maxLen, PUCHAR parmName , PUCHAR options)
{
    PUCHAR p = (PUCHAR) strstr((char *) options, (char *) parmName);
    LONG   len = 0;
    *parmValue = '\0';
    if (p == NULL) return; // Not found
    p += strlen(parmName);
    while (*p == ' ') p++;
    if (*p != '=') return; // Not "name=value"
    p++;
    while (*p == ' ') p++;
    while (*p != ' ' && *p != ',' && *p != '\0' && len < maxLen - 1) {
        parmValue[len++] = *p++;
    }
    parmValue[len] = '\0';
}
// ---------------------------------------------------------------------------
// Case-insensitive test: is "name" equal to "arrName" + "suffix" ?
// ---------------------------------------------------------------------------
static BOOL isCountFieldName (PUCHAR name, PUCHAR arrName, PUCHAR suffix)
{
    size_t arrLen = strlen(arrName);
    size_t sufLen = strlen(suffix);
    size_t i;

    if (strlen(name) != arrLen + sufLen) return false;
    for (i = 0; i < arrLen; i++) {
        if (toupper(name[i]) != toupper(arrName[i])) return false;
    }
    for (i = 0; i < sufLen; i++) {
        if (toupper(name[arrLen + i]) != toupper(suffix[i])) return false;
    }
    return true;
}
// ---------------------------------------------------------------------------
// Find the sibling scalar <arrName><suffix> within the object pObj
// ---------------------------------------------------------------------------
static PJXNODE findCountNode (PJXNODE pObj, PUCHAR arrName)
{
    PJXNODE p;
    for (p = pObj->pNodeChildHead; p ; p = p->pNodeSibling) {
        if (p->Name
        &&  (p->type == LITERAL || p->type == VALUE)
        &&  isCountFieldName (p->Name, arrName, countSuffix)) {
            return p;
        }
    }
    return NULL;
}
// ---------------------------------------------------------------------------
// Parse the numeric value of the count node. Returns false if not numeric
// ---------------------------------------------------------------------------
static BOOL getCountValue (PJXNODE pCount, LONG * pN)
{
    PUCHAR start;
    PUCHAR end;
    LONG   n;

    if (pCount->Value == NULL) return false;
    start = pCount->Value;
    while (*start == ' ') start++;
    n = strtol ((char *) start, (char **) &end, 10);
    if (end == start) return false;   // no digits at all
    *pN = (n < 0) ? 0 : n;
    return true;
}
// ---------------------------------------------------------------------------
// Keep only the first n elements of an array.
// The list is cut in one go (jx_NodeDelete on each element would search the
// previous sibling from the head every time = O(n*n) for large arrays).
// ---------------------------------------------------------------------------
static void trimArray (PJXNODE pArr, LONG n)
{
    PJXNODE pLast = NULL;
    PJXNODE pElem = pArr->pNodeChildHead;
    PJXNODE pNext;
    LONG    i = 0;

    while (pElem && i < n) {
        pLast = pElem;
        pElem = pElem->pNodeSibling;
        i++;
    }
    if (pElem == NULL) return;      // nothing to cut

    // Detach the tail from the array
    if (pLast) {
        pLast->pNodeSibling = NULL;
    } else {
        pArr->pNodeChildHead = NULL;
    }
    pArr->pNodeChildTail = pLast;
    pArr->Count = i;

    // Free the detached elements - each one is now a root, so no unlink search
    while (pElem) {
        pNext = pElem->pNodeSibling;
        pElem->pNodeSibling = NULL;
        pElem->pNodeParent  = NULL;
        jx_NodeDelete (pElem);
        pElem = pNext;
    }
}
// ---------------------------------------------------------------------------
// Walk the generated graph: For each array "x" in an object that also
// contains a numeric field "x<suffix>", trim the array to that many
// elements and remove the length field from the output.
// The length field may be declared before or after the array.
// If no length field exists, the array is left as is.
// ---------------------------------------------------------------------------
static void applyCountSuffix (PJXNODE pNode)
{
    PJXNODE pChild;
    PJXNODE pNext;

    if (pNode == NULL || countSuffix[0] == '\0') return;

    if (pNode->type == OBJECT) {
        for (pChild = pNode->pNodeChildHead; pChild ; pChild = pNext) {
            pNext = pChild->pNodeSibling;
            if (pChild->type == ARRAY && pChild->Name && pChild->Name[0] > '\0') {
                PJXNODE pCount = findCountNode (pNode, pChild->Name);
                LONG    n;
                if (pCount && getCountValue (pCount, &n)) {
                    trimArray (pChild, n);
                    if (pCount == pNext) {
                        pNext = pNext->pNodeSibling;
                    }
                    jx_NodeDelete (pCount);
                }
            }
        }
    }

    // Recurse into what is left (nested structures / arrays of structures)
    for (pChild = pNode->pNodeChildHead; pChild ; pChild = pChild->pNodeSibling) {
        if (pChild->type == OBJECT || pChild->type == ARRAY) {
            applyCountSuffix (pChild);
        }
    }
}
// ---------------------------------------------------------------------------
// The main entry point for the data generation
// Options (second parameter, optional), comma separated:
//    countsuffix=_length   array "x" gets its length from field "x_length"
//                          (the length field is removed from the output)
//    toplength=5           the root array (data-gen on a DS with DIM) is
//                          limited to the first 5 elements
// ---------------------------------------------------------------------------
JX_DATAGEN jx_dataGen (PJXNODE * ppNode, PUCHAR optionsP)
{
    PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
    PUCHAR genOptions = (pParms->OpDescList->NbrOfParms >= 2 && optionsP != NULL) ? optionsP : "";
    UCHAR  temp [16];
    PUCHAR pEnd;
    getParmValue (countSuffix , sizeof(countSuffix), "countsuffix" , genOptions);
    getParmValue (temp        , sizeof(temp)       , "toplength"   , genOptions);
    topLength = strtol ((char *) temp, (char **) &pEnd, 10);
    if (pEnd == temp || topLength < 0) topLength = -1;  // missing or invalid
    ppRoot = ppNode; // not reentrant
    return &jx_dataGenMapper;
}
