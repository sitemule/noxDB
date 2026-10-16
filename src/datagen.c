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

/*    ---------------------------------------------------------------------------
    Implement;
    https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/rzasm/roaDataGenExample.htm
    https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_73/rzasm/rzasmpdf.pdf
    --------------------------------------------------------------------------- */
void  nox_dataGenMapper (QrnDgParm_T * pParms)
{
    switch ( pParms->event) {
        case QrnDgEvent_01_StartMultiple    : {
            break;
        }
        case QrnDgEvent_02_EndMultiple      : {
            break;
        }
        case QrnDgEvent_03_Start            : {
            mapper_pNode = NULL;
            mapper_first = true;
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
            ULONG namelen = XlateBuffer (xlate_1200_to_1208, name , (PUCHAR) &pParms->name.name , pParms->name.len * 2);
            name[namelen] = '\0';

            if (! upperCaseNames) {
                a_camel_case (name, name);
            }

            pArr = nox_NewArray();
            nox_NodeRename(pArr ,  name);
            nox_NodeInsertChildTail (mapper_pNode , pArr);
            mapper_pNode = pArr;
            if (mapper_first) {
                mapper_first = false;
                *ppRoot = mapper_pNode;
            };
            break;
        }
        case QrnDgEvent_08_EndScalarArray   : {
            mapper_pNode = nox_GetNodeParent (mapper_pNode);
            break;
        }
        case QrnDgEvent_09_StartStructArray : {
            PNOXNODE pArr;
            UCHAR name [256];

            ULONG namelen = XlateBuffer(xlate_1200_to_1208, name , (PUCHAR) &pParms->name.name , pParms->name.len * 2);
            name[namelen] = '\0';

            if (! upperCaseNames) {
                a_camel_case (name, name);
            }

            pArr = nox_NewArray();
            nox_NodeRename(pArr ,  name);
            nox_NodeInsertChildTail (mapper_pNode , pArr);
            mapper_pNode = pArr;
            if (mapper_first) {
                mapper_first = false;
                *ppRoot = mapper_pNode;
            };
            break;
        }
        case QrnDgEvent_10_EndStructArray   : {
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
// The main entry point for the data generation
// ---------------------------------------------------------------------------
NOX_DATAGEN  nox_DataGen (PNOXNODE * ppNode, PUCHAR optionsP)
{
    PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
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
