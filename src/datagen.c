// CMD:CRTCMOD
/* ---------------------------------------------------------------
 * Company . . . : System & Method A/S
 * Design  . . . : Niels Liisberg
 * Function  . . : NOX - Serializer from RPGLE structures
 *
 * By     Date       Task    Description
 * NL     09.03.2021 0000000 New program
 * trace:
 * ADDENVVAR QIBM_RPG_DATA_GEN_TRACE NOX_VALUE('*STDOUT')
 * --------------------------------------------------------------- */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h>
#include <iconv.h>
#include <unistd.h>
#include <sys/stat.h>

#include  "qoar/h/qrntypes"
#include  "qoar/h/qrndtagen"


#include "ostypes.h"
#include "sndpgmmsg.h"
#include "trycatch.h"
#include "parms.h"
#include "strUtil.h"
#include "memUtil.h"
#include "varchar.h"
#define NOX_BUILD
#include "noxDbUtf8.h"
#include "xlate.h"


// NOTE !!! ALL constants are UTF-8
#pragma convert(1252)

extern iconv_t xlate_1200_to_1208;

// ---------------------------------------------------------------------------
// nox_DataGen state  (thread-local so concurrent threads don't interfere)
// ---------------------------------------------------------------------------
static __thread BOOL       upperCaseNames = false;
static __thread PNOXNODE * ppRoot         = NULL;
static __thread PNOXNODE   mapper_pNode   = NULL;
static __thread BOOL       mapper_first   = false;
static __thread UCHAR      countSuffix[64] = "";
static __thread LONG       topLength = -1;

static void applyCountSuffix(PNOXNODE pNode);
static void trimArray(PNOXNODE pArr, LONG n);
static PNOXNODE findCountNode(PNOXNODE pObj, PUCHAR arrName);
static BOOL getCountValue(PNOXNODE pCount, LONG *pN);

// Limits are applied while generating. Elements beyond a configured limit are
// skipped, so large unused array tails are never added to the object graph.
#define MAX_ARRAY_DEPTH 64
typedef struct _NOX_ARRLIMIT {
    PNOXNODE pArr;
    LONG     limit;
    LONG     count;
} NOX_ARRLIMIT;
static __thread NOX_ARRLIMIT arrStack[MAX_ARRAY_DEPTH];
static __thread int arrTop = -1;
static __thread LONG skipDepth = 0;

static BOOL acceptElement(PNOXNODE pNode)
{
    NOX_ARRLIMIT *pLimit;
    if (pNode == NULL || pNode->type != NOX_ARRAY) return true;
    if (arrTop < 0 || arrStack[arrTop].pArr != pNode) return true;
    pLimit = &arrStack[arrTop];
    if (pLimit->limit >= 0 && pLimit->count >= pLimit->limit) return false;
    pLimit->count++;
    return true;
}

static void pushArray(PNOXNODE pArr, PNOXNODE pParent, BOOL isRoot)
{
    LONG limit = -1;
    if (isRoot) {
        limit = topLength;
    } else if (countSuffix[0] != '\0' && pParent != NULL
            && pParent->type == NOX_OBJECT && pArr->Name != NULL
            && pArr->Name[0] != '\0') {
        PNOXNODE pCount = findCountNode(pParent, pArr->Name);
        LONG n;
        if (pCount != NULL && getCountValue(pCount, &n)) limit = n;
    }
    if (arrTop < MAX_ARRAY_DEPTH - 1) {
        arrTop++;
        arrStack[arrTop].pArr = pArr;
        arrStack[arrTop].limit = limit;
        arrStack[arrTop].count = 0;
    }
}

static void popArray(PNOXNODE pArr)
{
    if (arrTop >= 0 && arrStack[arrTop].pArr == pArr) arrTop--;
}

/*    ---------------------------------------------------------------------------
    Implement;
    https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/rzasm/roaDataGenExample.htm
    https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_73/rzasm/rzasmpdf.pdf
    --------------------------------------------------------------------------- */
void  nox_dataGenMapper (QrnDgParm_T * pParms)
{
    if (skipDepth > 0) {
        switch (pParms->event) {
            case QrnDgEvent_05_StartStruct:
            case QrnDgEvent_07_StartScalarArray:
            case QrnDgEvent_09_StartStructArray:
                skipDepth++;
                return;
            case QrnDgEvent_06_EndStruct:
            case QrnDgEvent_08_EndScalarArray:
            case QrnDgEvent_10_EndStructArray:
                skipDepth--;
                return;
            case QrnDgEvent_11_ScalarValue:
                return;
            default:
                skipDepth = 0;
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
            mapper_pNode = NULL;
            mapper_first = true;
            break;
        }
        case QrnDgEvent_04_End              : {
            if (ppRoot != NULL && *ppRoot != NULL) {
                if (topLength >= 0 && (*ppRoot)->type == NOX_ARRAY) {
                    trimArray(*ppRoot, topLength);
                }
                applyCountSuffix(*ppRoot);
            }
            break;
        }
        case QrnDgEvent_05_StartStruct      : {
            PNOXNODE pObj;
            UCHAR name [256];
            LONG namelen;
            if (!acceptElement(mapper_pNode)) {
                skipDepth = 1;
                break;
            }
            namelen = XlateBuffer (xlate_1200_to_1208, name , (PUCHAR) &pParms->name.name , pParms->name.len * 2);
            name[namelen] = '\0';

            if (! upperCaseNames) {
                a_camel_case (name, name);
            }

            pObj  = nox_NewObject();
            nox_NodeRename(pObj ,  name);
            nox_NodeInsertChildTail (mapper_pNode , pObj);
            mapper_pNode = pObj;
            if (mapper_first) {
                mapper_first = false;
                *ppRoot = mapper_pNode;
            };
            break;
        }
        case QrnDgEvent_06_EndStruct        : {
            mapper_pNode = nox_GetNodeParent (mapper_pNode);
            break;
        }
        case QrnDgEvent_07_StartScalarArray : {
            PNOXNODE pArr;
            UCHAR name [256];
            ULONG namelen;
            BOOL isRoot = mapper_first;
            if (!acceptElement(mapper_pNode)) {
                skipDepth = 1;
                break;
            }
            namelen = XlateBuffer (xlate_1200_to_1208, name , (PUCHAR) &pParms->name.name , pParms->name.len * 2);
            name[namelen] = '\0';

            if (! upperCaseNames) {
                a_camel_case (name, name);
            }

            pArr = nox_NewArray();
            nox_NodeRename(pArr ,  name);
            nox_NodeInsertChildTail (mapper_pNode , pArr);
            pushArray(pArr, mapper_pNode, isRoot);
            mapper_pNode = pArr;
            if (mapper_first) {
                mapper_first = false;
                *ppRoot = mapper_pNode;
            };
            break;
        }
        case QrnDgEvent_08_EndScalarArray   : {
            popArray(mapper_pNode);
            mapper_pNode = nox_GetNodeParent (mapper_pNode);
            break;
        }
        case QrnDgEvent_09_StartStructArray : {
            PNOXNODE pArr;
            UCHAR name [256];
            BOOL isRoot = mapper_first;

            if (!acceptElement(mapper_pNode)) {
                skipDepth = 1;
                break;
            }

            ULONG namelen = XlateBuffer(xlate_1200_to_1208, name , (PUCHAR) &pParms->name.name , pParms->name.len * 2);
            name[namelen] = '\0';

            if (! upperCaseNames) {
                a_camel_case (name, name);
            }

            pArr = nox_NewArray();
            nox_NodeRename(pArr ,  name);
            nox_NodeInsertChildTail (mapper_pNode , pArr);
            pushArray(pArr, mapper_pNode, isRoot);
            mapper_pNode = pArr;
            if (mapper_first) {
                mapper_first = false;
                *ppRoot = mapper_pNode;
            };
            break;
        }
        case QrnDgEvent_10_EndStructArray   : {
            popArray(mapper_pNode);
            mapper_pNode = nox_GetNodeParent (mapper_pNode);
            break;
        }
        case QrnDgEvent_11_ScalarValue      : {
            PNOXNODE pValueNode;
            UCHAR value [pParms->u.scalar.valueLenBytes];
            ULONG valuelen;
            PUCHAR pValue = value;
            UCHAR name [256];
            ULONG namelen;
           NOX_NODETYPE  type;

            if (!acceptElement(mapper_pNode)) break;

            namelen = XlateBuffer (xlate_1200_to_1208, name , (PUCHAR) &pParms->name.name , pParms->name.len * 2);
            name[namelen] = '\0';

            if (! upperCaseNames) {
                a_camel_case (name, name);
            }

            valuelen = XlateBuffer (xlate_1200_to_1208, value , (PUCHAR) pParms->u.scalar.value  , pParms->u.scalar.valueLenBytes);
            value[valuelen] = '\0';

            switch (pParms->u.scalar.dataType) {
                case QrnDatatype_Indicator :
                    pValue = (*value == '1') ? "true" : "false";
                    type = NOX_LITERAL;
                    break;

                // Numeric
                case QrnDatatype_Decimal  :
                case QrnDatatype_Integer  :
                case QrnDatatype_Unsigned :
                case QrnDatatype_Float    :
                    if (*pValue  == '+') pValue ++; // Skip the + sign
                    type = NOX_LITERAL;
                    break;
                default:
                    type = NOX_VALUE;
                    break;
            }

            pValueNode = nox_NodeInsertNew (mapper_pNode , NOX_RL_LAST_CHILD , name , pValue, type);
            if (mapper_first) {
                mapper_first = false;
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
// Generator options and count-suffix post-processing
// ---------------------------------------------------------------------------
static void getParmValue(PUCHAR parmValue, LONG maxLen, PUCHAR parmName, PUCHAR options)
{
    PUCHAR p = (PUCHAR)strstr((char *)options, (char *)parmName);
    LONG len = 0;
    *parmValue = '\0';
    if (p == NULL) return;
    p += strlen((char *)parmName);
    while (*p == ' ') p++;
    if (*p != '=') return;
    p++;
    while (*p == ' ') p++;
    while (*p != ' ' && *p != ',' && *p != '\0' && len < maxLen - 1) {
        parmValue[len++] = *p++;
    }
    parmValue[len] = '\0';
}

static BOOL isCountFieldName(PUCHAR name, PUCHAR arrName, PUCHAR suffix)
{
    size_t i = 0;
    size_t j = 0;
    while (name[i] != '\0' || arrName[j] != '\0' || suffix[0] != '\0') {
        while (name[i] == '_') i++;
        while (arrName[j] == '_') j++;
        if (arrName[j] != '\0') {
            if (name[i] == '\0' || toupper(name[i]) != toupper(arrName[j])) return false;
            i++;
            j++;
            continue;
        }
        while (suffix[0] == '_') suffix++;
        if (*suffix == '\0') break;
        if (name[i] == '\0' || toupper(name[i]) != toupper(*suffix)) return false;
        i++;
        suffix++;
    }
    while (name[i] == '_') i++;
    return name[i] == '\0';
}

static PNOXNODE findCountNode(PNOXNODE pObj, PUCHAR arrName)
{
    PNOXNODE p;
    for (p = pObj->pNodeChildHead; p != NULL; p = p->pNodeSiblingNext) {
        if (p->Name != NULL
            && (p->type == NOX_LITERAL || p->type == NOX_VALUE)
            && isCountFieldName(p->Name, arrName, countSuffix)) {
            return p;
        }
    }
    return NULL;
}

static BOOL getCountValue(PNOXNODE pCount, LONG *pN)
{
    PUCHAR start;
    PUCHAR end;
    LONG n;
    if (pCount->Value == NULL) return false;
    start = pCount->Value;
    while (*start == ' ') start++;
    n = strtol((char *)start, (char **)&end, 10);
    if (end == start) return false;
    *pN = (n < 0) ? 0 : n;
    return true;
}

static void trimArray(PNOXNODE pArr, LONG n)
{
    PNOXNODE pLast = NULL;
    PNOXNODE pElem = pArr->pNodeChildHead;
    PNOXNODE pNext;
    LONG i = 0;
    while (pElem != NULL && i < n) {
        pLast = pElem;
        pElem = pElem->pNodeSiblingNext;
        i++;
    }
    if (pElem == NULL) return;
    if (pLast != NULL) pLast->pNodeSiblingNext = NULL;
    else pArr->pNodeChildHead = NULL;
    pArr->pNodeChildTail = pLast;
    pArr->Count = i;
    while (pElem != NULL) {
        pNext = pElem->pNodeSiblingNext;
        pElem->pNodeSiblingNext = NULL;
        pElem->pNodeParent = NULL;
        nox_NodeDelete(pElem);
        pElem = pNext;
    }
}

static void applyCountSuffix(PNOXNODE pNode)
{
    PNOXNODE pChild;
    PNOXNODE pNext;
    if (pNode == NULL || countSuffix[0] == '\0') return;
    if (pNode->type == NOX_OBJECT) {
        for (pChild = pNode->pNodeChildHead; pChild != NULL; pChild = pNext) {
            pNext = pChild->pNodeSiblingNext;
            if (pChild->type == NOX_ARRAY && pChild->Name != NULL && pChild->Name[0] != '\0') {
                PNOXNODE pCount = findCountNode(pNode, pChild->Name);
                LONG n;
                if (pCount != NULL && getCountValue(pCount, &n)) {
                    trimArray(pChild, n);
                    if (pCount == pNext) pNext = pNext->pNodeSiblingNext;
                    nox_NodeDelete(pCount);
                }
            }
        }
    }
    for (pChild = pNode->pNodeChildHead; pChild != NULL; pChild = pChild->pNodeSiblingNext) {
        if (pChild->type == NOX_OBJECT || pChild->type == NOX_ARRAY) {
            applyCountSuffix(pChild);
        }
    }
}

// ---------------------------------------------------------------------------
// The main entry point for the data generation
// ---------------------------------------------------------------------------
NOX_DATAGEN  nox_DataGen (PNOXNODE * ppNode, PUCHAR optionsP)
{
    PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
    PUCHAR genOptions = (pParms->OpDescList->NbrOfParms >= 2 && optionsP != NULL) ? optionsP : (PUCHAR)"";
    UCHAR temp[16];
    PUCHAR pEnd;
    getParmValue(countSuffix, sizeof(countSuffix), (PUCHAR)"countsuffix", genOptions);
    getParmValue(temp, sizeof(temp), (PUCHAR)"toplength", genOptions);
    topLength = strtol((char *)temp, (char **)&pEnd, 10);
    if (pEnd == temp || topLength < 0) topLength = -1;
    ppRoot = ppNode;

    // TODO - Sysname !!

    return &nox_dataGenMapper;
}

// ---------------------------------------------------------------------------
// nox_DataGenFd state  (thread-local)
// ---------------------------------------------------------------------------
#define DATAGEN_FD_MAX_DEPTH 64

static __thread NOXWRITER  fdNoxWriter;
static __thread PSTREAM    fdStream            = NULL;
static __thread int        fdLevel             = -1;
static __thread BOOL       fdIsFirst[DATAGEN_FD_MAX_DEPTH];
static __thread BOOL       fdIsArray[DATAGEN_FD_MAX_DEPTH];

// Emit comma before the next sibling and key if inside an object.
static void fd_before_child(PUCHAR name)
{
    if (fdLevel >= 0 && !fdIsFirst[fdLevel]) stream_putc(fdStream, ',');
    if (fdLevel >= 0) fdIsFirst[fdLevel] = false;

    if (fdLevel >= 0 && !fdIsArray[fdLevel]) {
        stream_putc(fdStream, '"');
        stream_puts(fdStream, name);
        stream_puts(fdStream, "\":");
    }
}

static void fd_push(BOOL isArray)
{
    fdLevel++;
    fdIsFirst[fdLevel] = true;
    fdIsArray[fdLevel] = isArray;
}

static void fd_get_name(UCHAR name[256], QrnDgParm_T * pParms)
{
    ULONG namelen = XlateBuffer(xlate_1200_to_1208, name, (PUCHAR)&pParms->name.name, pParms->name.len * 2);
    name[namelen] = '\0';
    a_camel_case(name, name);
}

// ---------------------------------------------------------------------------
void nox_dataGenFdMapper (QrnDgParm_T * pParms)
{
    UCHAR name[256];

    switch (pParms->event) {

        case QrnDgEvent_01_StartMultiple: {
            stream_putc(fdStream, '[');
            fd_push(true);
            break;
        }
        case QrnDgEvent_02_EndMultiple: {
            stream_putc(fdStream, ']');
            fdLevel--;
            break;
        }
        case QrnDgEvent_03_Start: {
            fdLevel = -1;
            break;
        }
        case QrnDgEvent_04_End: {
            stream_delete(fdStream);
            fclose(fdNoxWriter.outFile);
            fdStream = NULL;
            break;
        }
        case QrnDgEvent_05_StartStruct: {
            fd_get_name(name, pParms);
            fd_before_child(name);
            stream_putc(fdStream, '{');
            fd_push(false);
            break;
        }
        case QrnDgEvent_06_EndStruct: {
            stream_putc(fdStream, '}');
            fdLevel--;
            break;
        }
        case QrnDgEvent_07_StartScalarArray:
        case QrnDgEvent_09_StartStructArray: {
            fd_get_name(name, pParms);
            fd_before_child(name);
            stream_putc(fdStream, '[');
            fd_push(true);
            break;
        }
        case QrnDgEvent_08_EndScalarArray:
        case QrnDgEvent_10_EndStructArray: {
            stream_putc(fdStream, ']');
            fdLevel--;
            break;
        }
        case QrnDgEvent_11_ScalarValue: {
            ULONG vlen = pParms->u.scalar.valueLenBytes;
            UCHAR value[vlen + 1];
            ULONG valuelen;
            PUCHAR pValue = value;
            BOOL isLiteral = false;

            fd_get_name(name, pParms);

            valuelen = XlateBuffer(xlate_1200_to_1208, value, (PUCHAR)pParms->u.scalar.value, vlen);
            value[valuelen] = '\0';

            switch (pParms->u.scalar.dataType) {
                case QrnDatatype_Indicator:
                    pValue = (*value == '1') ? "true" : "false";
                    isLiteral = true;
                    break;
                case QrnDatatype_Decimal:
                case QrnDatatype_Integer:
                case QrnDatatype_Unsigned:
                case QrnDatatype_Float:
                    if (*pValue == '+') pValue++;
                    isLiteral = true;
                    break;
                default:
                    break;
            }

            fd_before_child(name);

            if (isLiteral) {
                stream_puts(fdStream, pValue);
            } else {
                stream_putc(fdStream, '"');
                nox_EncodeJsonStream(fdStream, pValue);
                stream_putc(fdStream, '"');
            }
            break;
        }
        case QrnDgEvent_12_Terminate: {
            break;
        }
    }
}

// ---------------------------------------------------------------------------
// Entry point: sets up the stream and returns the streaming callback.
// The caller owns fd — nox_DataGenFd dups it internally and will close
// the dup when DATA-GEN fires the End event.
// ---------------------------------------------------------------------------
NOX_DATAGEN nox_DataGenFd (int fd)
{
    if (fdStream != NULL) {
        stream_delete(fdStream);
        fclose(fdNoxWriter.outFile);
        fdStream = NULL;
    }

    memset(&fdNoxWriter, 0, sizeof(fdNoxWriter));
    fdNoxWriter.doTrim  = true;
    fdNoxWriter.outFile = fdopen(dup(fd), "w");

    fdStream = stream_new(4096);
    fdStream->handle = &fdNoxWriter;
    fdStream->writer = nox_fileWriter;
    fdLevel = -1;

    return &nox_dataGenFdMapper;
}
