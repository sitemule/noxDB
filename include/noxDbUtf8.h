// TODO: make NOX_BUILD in one section

#ifndef NOXDB
#define NOXDB
#include <stdio.h>
#include <iconv.h>
#include <sqlcli.h>
#include <pointer.h>
#include "ostypes.h"     //

#include "apierr.h"
#ifdef NOX_BUILD
#include "streamer.h"
#include "xlate.h"
#endif
// #ifndef OCCURENS_TYPE
// #define OCCURENS_TYPE
// typedef enum {
//    OC_NONE = 0,
//    OC_NEXT_FOLLOWS = 1,
//    OC_EITHER_OR = 2
// } OCCURENS, *POCCURENS;
// #endif

typedef decimal(30,15) FIXEDDEC, * PFIXEDDEC;

/*
#define UTF8CONST(a) (\
#pragma convert(1252) \
a \
#pragma convert(0)\
)
*/
#ifdef NOX_BUILD

#pragma convert(1252)
#define  UBOUND      "UBOUND"
#define  PARENT_PATH "../"
#define  NULLSTR     "null"
#define  TRUESTR     "true"
#define  FALSESTR    "false"
#define  REMARK      "!--"
#define  DOCTYPE     "!DOCTYPE"
#define  ENDREMARK   "-->"
#define  SLASHGT     "/>"
#define  BRABRAGT    "]]>"
#define  CDATA       "<![CDATA["
#define  DELIMITERS  "/\\@[] .{}'\""
#pragma convert(0)

#define  APOS         0x27
#define  QUOT         0x22
#define  QUESTION     0x3f
#define  EQ           0x3d
#define  GT           0x3e
#define  LT           0x3c
#define  UNDERSCORE   0x5f
#define  COLON        0x3a
#define  DOT          0x2e
#define  SLASH        0x2f
#define  EXCLMARK     0x21
#define  BACKSLASH    0x5c
#define  MASTERSPACE  0x40
#define  BRABEG       0x5b
#define  BRAEND       0x5d
#define  CURBEG       0x7b
#define  CUREND       0x7d
#define  MINUS        0x2d
#define  BLANK        0x20
#define  AMP          0x26
#define  HASH         0x23
#define  CR           0x0d
#define  COMMA        0x2c


typedef enum {
   NOX_EXPR_DONE,
   NOX_EXPR_ROOT,
   NOX_EXPR_CHILD,
   NOX_EXPR_PARENT,
   NOX_EXPR_COUNT,
   NOX_EXPR_FIND_SIBLING,
   NOX_EXPR_FIND_CHILD,
   NOX_EXPR_SUBSTRIPTION_PATH,
   NOX_EXPR_SUBSTRIPTION_INDEX,
   NOX_EXPR_SUBSTRIPTION_UBOUND
} NOX_EXPR_STATE, *PNOX_EXPR_STATE;

typedef struct _NOX_EXPR_PATH {
   UCHAR  current[256];
   PUCHAR pStart;
   PUCHAR pNext;
   LONG   index;
   BOOL   skipNameSpace;
   NOX_EXPR_STATE state;
   int (*cmp)(const char *s1, const char *s2);  // function pointer for strcmp
} NOX_EXPR_PATH, *PNOX_EXPR_PATH;
#endif


typedef enum {
   NOX_FORMAT_DEFAULT     = 0,
   NOX_FORMAT_CDATA       = 1
} NOX_FORMAT_OPTION, *PNOX_FORMAT_OPTION;

typedef enum {
	NOX_FMT_JSON,
	NOX_FMT_XML,
	NOX_FMT_TEXT
} NOX_DATAFORMAT, *PNOX_DATAFORMAT;


typedef enum {
   NOX_STREAM_JSON     = 0,
   NOX_STREAM_XML      = 1,
   NOX_STREAM_CSV      = 2
} STREAM_OPTION, *PSTREAM_OPTION;


#define NOX_ATTRSIG 0x05
typedef struct _NOXATTR {
   UCHAR  signature; // always hex 05
   PUCHAR Name;
   PUCHAR Value;
   struct _NOXATTR    * pAttrSibling;
   PVOID pNodeParent;
} NOXATTR, *PNOXATTR;

typedef enum {
   NOX_UNKNOWN             = 0,
   NOX_OBJECT              = 1,
   NOX_ARRAY               = 2,
   NOX_PARSE_STRING        = 3,
   NOX_POINTER_NOX_VALUE       = 4,
   NOX_VALUE               = 5,
   NOX_ROOT                = 6,
   NOX_LITERAL             = 16,
   NOX_CLONE_OLD           = 17,  // Was OBJLNK - Obsolete yes but maps to NOX_CLONE in appplication
   NOX_CLONE               = 18,  // Obsolete ... NO
   NOX_EVALUATE            = 19,  // Obsolete ??
   NOX_POINTER         = 20,  // Internal objects
   NOX_SUBGRAPH        = 21,  // Sub-graph, will be serialized but maintained elsewhere
   NOX_OBJMOVE             = 2048,
   // Values to be or'ed ( + ) with NOX_EVALUATE and NOX_PARSE_STRING
   // Note: "Merge options" are fit in here... from belowe
   NOX_NT_MOVE             =2048,  // Unlink the source and move it to destination
   NOX_NT_ALLOW_PRIMITIVES =4096   // Allow strings ints and other valyes to evaluate with NOX_PARSE_STRING

} NOX_NODETYPE, *PNOX_NODETYPE;

#pragma enum (2)
typedef enum {
   // Values to be or'ed ( + ) with NOX_EVALUATE and NOX_PARSE_STRING
  NOX_MO_MERGE_NEW      =   256,  // Only new elements are merged - existing are left untouched
  NOX_MO_MERGE_MATCH    =   512,  // Merge and replace only existing nodes
  NOX_MO_MERGE_REPLACE  =  1024,   // Merge all: replace if it exists and append new nodes if not exists
  NOX_MO_MERGE_MOVE     =  2048   // Extra parm to be OR'ed for movine and not clone / copy
} NOX_MERGEOPTION, *PNOX_MERGEOPTION;
#pragma enum (pop)

#define NOX_NODESIG  0x04
typedef struct _NOXNODE {
   UCHAR  signature; // always hex 04
   PUCHAR Name;
   PNOXATTR pAttrList;
   PUCHAR Value;
   struct _NOXNODE * pNodeParent;
   struct _NOXNODE * pNodeChildHead;
   struct _NOXNODE * pNodeChildTail;
   struct _NOXNODE * pNodeSiblingNext;
   struct _NOXNODE * pNodeSiblingPrevious; // TODO !! Implement back-chain
   LONG     Count;
   BOOL     newlineInAttrList;
   PUCHAR   Comment;
   NOX_NODETYPE type;
   BOOL     doCount;
   LONG     lineNo;
   BOOL     isLiteral;
   SHORT    ccsid;
   NOX_FORMAT_OPTION options;
} NOXNODE, *PNOXNODE;

#ifdef NOX_BUILD

typedef enum {
   NOX_FIND_START_TOKEN,
   NOX_DETERMIN_TAG_TYPE,
   NOX_FIND_END_TOKEN,
   NOX_BUILD_NAME,
   NOX_COLLECT_DATA,
   NOX_ATTR_NAME,
   NOX_ATTR_VALUE,
   NOX_DELIMITER,
   NOX_EXIT,
   NOX_EXIT_ERROR
} NOX_XMLSTATE, *PNOX_XMLSTATE;


typedef struct {
   PNOXNODE pNodeRoot;
   FILE *  File;
   PUCHAR  FileName;
   NOX_XMLSTATE State;
   //UCHAR   FileBuf[65535];
   UCHAR   dummy[32]; // Extra space after buffer for swapping
   PUCHAR  pFileBuf;
   PUCHAR  Data;
   LONG    DataIx;
   LONG    DataSize;
   UCHAR   StartName [32768];
   LONG    StartNameIx;
   UCHAR   EndName [32768];
   LONG    EndNameIx;
   PUCHAR  pName;
   PLONG   pNameIx;
   LONG    Level;
   PNOXNODE pNodeWorkRoot;
   PNOXNODE pNodeCurrent;
   PNOXATTR *pAttr;
   LONG    Count;
   UCHAR   fnyt;
   LONG    LineCount;
   LONG    ColCount;
   PUCHAR  StreamBuf;
   UCHAR   e2aTbl[256];
   BOOL    UseIconv;
   iconv_t Iconv;
   BOOL    LittleEndian;
   LONG    StartLine;
   PUCHAR  Comment;
   BOOL    isJson;
   BOOL    hasRoot;
   LONG    tokenNo;
} NOXCOM, * PNOXCOM;
#endif

typedef enum {
   NOX_RL_FIRST_CHILD = 1,
   NOX_RL_LAST_CHILD = 2,
   NOX_RL_BEFORE_SIBLING = 3,
   NOX_RL_AFTER_SIBLING = 4,
   NOX_RL_REPLACE = 5
} NOX_REFLOC, *PNOX_REFLOC;

#ifdef NOX_BUILD

typedef struct _NOX_TOK{
   BOOL    isEof;
   UCHAR   token ;
   BOOL    isLiteral;
   LONG    len;
   PUCHAR  data;
   LONG    count;
} NOX_TOK, *PNOX_TOK;

typedef _Packed struct  _NOXWRITER      {
   FILE *  outFile;
   iconv_t iconv;
   PUCHAR  buf;
   SHORT   level;
   SHORT   prevLevel;
   LONG    lineNo;
   BOOL    doTrim;
   BOOL    useDefaultFormat;
   BOOL    isDefaultFormatDetected;
   ULONG   bufLen;
   ULONG   maxSize;
   BOOL    wasHere;
   PVOID   scratchPad; // Pointer to any user data
} NOXWRITER, * PNOXWRITER;
#endif

typedef _Packed struct  _NOXITERATOR {
   PNOXNODE   root;
   PNOXNODE   this;
   LGL       isList;
   LGL       isFirst;
   LGL       isLast;
   LGL       isRecursive;
   VARCHAR1  comma;
   LONG      count;
   LONG      length;
   LONG      size;
   PNOXNODE * list;
   LGL       doBreak;
   PNOXNODE   next;
} NOXITERATOR, * PNOXITERATOR ;


#ifdef NOX_BUILD

#pragma enum (1)
typedef enum {
	NOX_DTYPE_CHAR       = 'C',
	NOX_DTYPE_VARCHAR    = 'V',
	NOX_DTYPE_INT        = 'I',
	NOX_DTYPE_BYTE       = 'B',
	NOX_DTYPE_BOOL       = 'b',
	NOX_DTYPE_PACKED     = 'P',
	NOX_DTYPE_ZONED      = 'Z',
	NOX_DTYPE_DATE       = 'D',
	NOX_DTYPE_TIME       = 'T',
	NOX_DTYPE_TIME_STAMP = 'S',
	NOX_DTYPE_STRUCTURE  = 's',
	NOX_DTYPE_NOX_UNKNOWN    = '?',
} NOX_DTYPE, *PNOX_DTYPE;
#pragma enum (pop)

#define PROC_NAME_MAX 64
typedef struct _NOXMETHOD  {
   PNOXNODE pMetaNode;
   _SYSPTR userProgram; // program or service program
   _SYSPTR userMethod;
   BOOL    userMethodIsProgram;
   ULONG   ccsid;
   UCHAR   library   [10];
	UCHAR   null1;
   UCHAR   program   [10];
	UCHAR   null2;
   UCHAR   procedure [PROC_NAME_MAX];
	UCHAR   null3;
	PNOXNODE pLib;
	PNOXNODE pPgm;
	PNOXNODE pProc;
} NOX_METHOD, * PNOX_METHOD;

typedef struct _NOXPARMMETA  {
	UCHAR    signature; // always hex 00
	UCHAR    name[PROC_NAME_MAX];
	NOX_DTYPE dType;
	UCHAR    use;
	ULONG    offset;
	ULONG    size;
	ULONG    precision;
	ULONG    length;
	ULONG    dim;
	UCHAR    format[10];
	UCHAR    separatorChar;
	NOX_NODETYPE graphDataType;
	PNOXNODE  pStructure;
	struct _NOXPARMMETA* pLengthMeta;
	BOOL     dontRender;
} NOX_PARMMETA, * PNOX_PARMMETA;
#endif


// Prototypes  - utilities
void nox_AsJsonText (PLVARCHAR retVal, PNOXNODE pNode);

#ifdef NOX_BUILD
void nox_AsJsonTextList (PNOXNODE pNode, PNOXWRITER pNOXWRITER);
#endif

void nox_AsJsonStream (PNOXNODE pNode, PSTREAM pStream);

LONG nox_AsJsonTextMem (PNOXNODE pNode, PUCHAR buf, ULONG maxLenP);
#pragma descriptor ( void nox_AsJsonTextMem       (void))


#ifdef NOX_BUILD
void  csvStreamRunner   (PSTREAM pStream);
void  xmlStreamRunner   (PSTREAM pStream);
void  jsonStreamRunner  (PSTREAM pStream);
#endif


LONG nox_fileWriter  (PSTREAM pStream, PUCHAR buf, ULONG len);
LONG nox_memWriter  (PSTREAM pStream, PUCHAR buf, ULONG len);
void  nox_jsonStreamPrintNode (PNOXNODE pNode, PSTREAM pStream, SHORT level);
void  nox_jsonStreamPrintValue   (PNOXNODE pNode, PSTREAM pStream);
void  nox_jsonStreamPrintArray (PNOXNODE pParent, PSTREAM pStream, SHORT level);
void  nox_jsonStreamPrintObject  (PNOXNODE pParent, PSTREAM pStream, SHORT level);
void  indent (PSTREAM pStream, int indent);
PUCHAR nox_EncodeJson (PUCHAR out, PUCHAR in);
void  nox_EncodeJsonStream (PSTREAM p, PUCHAR in);

/* Internals */
#ifdef NOX_BUILD
PUCHAR c2s(UCHAR c);
PUCHAR strTrim(PUCHAR s);
UCHAR hex (UCHAR c)     ;
PUCHAR findchr (PUCHAR base, PUCHAR chars, SHORT charslen) ;
LONG nox_xlateMem  (iconv_t xid, PUCHAR out, PUCHAR in, LONG len);
void nox_xlatecpy( PNOXCOM pJxCom ,PUCHAR out, PUCHAR in , LONG len);
int cpy (PUCHAR out, PUCHAR in)                                  ;
void iconvWrite( FILE * f, iconv_t * pIconv, PUCHAR Value, BOOL Esc);
void iconvPutc( FILE * f, iconv_t * pIconv, UCHAR c);
void swapEndian(PUCHAR buf, LONG len)                                ;
LONG xlate(PNOXCOM pJxCom, PUCHAR outbuf, PUCHAR inbuf, LONG len)    ;
int readBlock(PNOXCOM pJxCom, PUCHAR buf, int size)                  ;
BOOL isTimeStamp(PUCHAR p)                                           ;
int formatTimeStamp(PUCHAR p, PUCHAR s)                             ;
UCHAR unicode2ebcdic (USHORT c)                                      ;
int unicode2utf8 (PUCHAR out, USHORT c);

int parsehex(UCHAR c)                                                ;
BOOL isTerm(UCHAR c, PUCHAR term);

void nox_Initialize(void);
void     nox_SkipBlanks(BOOL skip);
BOOL    JSON_Parse(PNOXCOM pJxCom);
BOOL    jsonParseNode(PNOXCOM pJxCom, NOX_NODETYPE state,  PUCHAR name, PNOXNODE pCurNode) ;

PNOXNODE DupNode(PNOXNODE pSource);
PNOXNODE NewNode (PUCHAR Name, PUCHAR Value,NOX_NODETYPE type);
PNOXNODE CloneNode  (PNOXNODE pSource);
PNOXNODE NewRoot(void);


// Prototypes  - file reader
void initconst(int ccsid);
PUCHAR nox_GetChar(PNOXCOM pJxCom);
UCHAR SkipBlanks (PNOXCOM pJxCom);
void  nox_SkipChars(PNOXCOM pJxCom, int skip);
void nox_CheckEnd(PNOXCOM pJxCom) ;
int readBlock(PNOXCOM pJxCom, PUCHAR buf, int size);

// Prototypes  - main
void nox_FreeChildren (PNOXNODE pNode);
PUCHAR nox_GetChar(PNOXCOM pJxCom);
void nox_SetMessage (PUCHAR Ctlstr, ... );
void nox_NodeFreeNodeOnly(PNOXNODE pNode);

VOID TRACE ( UCHAR lib[11], PLGL doTrace, UCHAR job [32]);
void CheckBufSize(PNOXCOM pJxCom);
BOOL nox_Parse (PNOXCOM pJxCom);

#endif



// Prototypes  - main  - exports
LGL nox_isNode  (PNOXNODE pNode);
void nox_NodeRename(PNOXNODE pNode, PUCHAR name);
PNOXNODE nox_NodeUnlink  (PNOXNODE  pNode);
void nox_NodeInsert (PNOXNODE pDest, PNOXNODE pSource, NOX_REFLOC refloc);
void nox_NodeInsertChildHead( PNOXNODE pRoot, PNOXNODE pChild);
void nox_NodeInsertChildTail( PNOXNODE pRoot, PNOXNODE pChild);
void nox_NodeInsertSiblingBefore( PNOXNODE pRef, PNOXNODE pSibling);
void nox_NodeInsertSiblingAfter( PNOXNODE pRef, PNOXNODE pSibling);

LGL nox_ParseStmfFile (PNOXNODE  * ppRoot, PUCHAR FileName, PUCHAR Mode);
#pragma descriptor ( void nox_ParseStmfFile       (void))

#ifdef NOX_BUILD
BOOL nox_ParseJson(PNOXCOM pJxCom);
BOOL nox_ParseXml (PNOXCOM pJxCom);
BOOL nox_ParseJsonNode(PNOXCOM pJxCom, NOX_NODETYPE state, PUCHAR name, PNOXNODE pCurNode);
#endif


PNOXNODE nox_NodeClone  (PNOXNODE pSource);
void nox_NodeMoveAndReplace (PNOXNODE  pDest, PNOXNODE pSource);
/* ------ */
void nox_SetDecPoint(PUCHAR p);
//void nox_SetDelimiters(PNOXDELIM pDelim);
//void nox_SetDelimiters2(PNOXDELIM pDelim);
//void nox_CloneFormat(PNOXNODE pNode, PNOXNODE pSource);

LGL nox_Has  (PNOXNODE pNode, PUCHAR Name);
#pragma descriptor ( void nox_Has                 (void))

LGL nox_IsTrue  (PNOXNODE pNode, PUCHAR Name);
#pragma descriptor ( void nox_IsTrue              (void))

LGL nox_IsNull  (PNOXNODE pNode, PUCHAR Name);
#pragma descriptor ( void nox_IsNull              (void))

NOXITERATOR nox_SetIterator (PNOXNODE pNode, PUCHAR path);
#pragma descriptor ( void nox_SetIterator         (void))

NOXITERATOR nox_SetRecursiveIterator (PNOXNODE pNode, PUCHAR path);
#pragma descriptor ( void nox_SetRecursiveIterator(void))

LGL nox_ForEach (PNOXITERATOR pIter, PLVARCHAR filterP);
#pragma descriptor ( void nox_ForEach   (void))

PNOXNODE nox_GetParent(PNOXNODE pNode);
SHORT nox_GetNodeType (PNOXNODE pNode);

void nox_GetNodeNameAsPath (PLVARCHAR pRes, PNOXNODE pNode, UCHAR Delimiter);
#pragma descriptor ( void nox_GetNodeNameAsPath   (void))

void nox_CopyValueByNameVC (
   PLVARCHAR pRes, PNOXNODE pNodeRoot, PLVARCHAR pName, PLVARCHAR pDefault, BOOL joinString);
#pragma descriptor ( void  nox_CopyValueByNameVC  (void))


void nox_WriteXmlStmfNodeList (FILE * f, iconv_t * pIconv ,PNOXNODE pNode);

void nox_WriteXmlStmf (
   PNOXNODE pNode, PUCHAR FileName, int Ccsid, LGL trimOut, PNOXNODE options);
#pragma descriptor ( void nox_WriteXmlStmf       (void))

void nox_WriteJsonStmf (
   PNOXNODE pNode, PUCHAR FileName, int Ccsid, LGL trimOut, PNOXNODE options);
#pragma descriptor ( void nox_WriteJsonStmf      (void))

void nox_WriteCsvStmf (
   PNOXNODE pNode, PUCHAR FileName, int Ccsid, LGL trimOut, PNOXNODE options);
#pragma descriptor ( void nox_WriteCsvStmf      (void))

PNOXNODE  nox_ParseFile  (PUCHAR FileName);
PNOXNODE  nox_ParseString  (PUCHAR Buf);
PNOXNODE  nox_NewObject (void);
PNOXNODE  nox_NewArray (void);

PUCHAR   nox_GetValueByName (
   PNOXNODE pNode, PUCHAR Name, PUCHAR Default);
#pragma descriptor ( void nox_GetValueByName (void))

PNOXNODE  nox_SetValueByName (
   PNOXNODE pNodeRoot, PUCHAR Name, PUCHAR Value,NOX_NODETYPE type);
#pragma descriptor ( void nox_SetValueByName (void))

void     nox_AsXmlText (PLVARCHAR retVal, PNOXNODE pNode);
PUCHAR   nox_NodeAsXmlTextList (PNOXNODE pNode, PUCHAR temp);

VOID     nox_SetApiErr  (PNOXNODE pJxNode, PAPIERR pApiErr );

LGL      nox_Error (PNOXNODE pJxNode);
PUCHAR   nox_ErrStr(PNOXNODE pJxNode);
VARCHAR1024  nox_MessageVC  (PNOXNODE pJxNode);
void     nox_Dump  (PNOXNODE pJxNode);
void     nox_Free  (PNOXNODE pJxNode);

PNOXNODE  nox_GetNode  (
   PNOXNODE pNode, PUCHAR Name) ;
#pragma descriptor ( void nox_GetNode    (void))

PNOXNODE  nox_GetNodeChild (PNOXNODE pNode);
PNOXNODE  nox_GetNodeChildNo (PNOXNODE pNode, int childNo);
PNOXNODE  nox_GetNodeNext (PNOXNODE pNode);
PNOXNODE  nox_GetNodeParent  (PNOXNODE pNode);
PNOXATTR nox_AttributeLookup   (PNOXNODE pNode, PUCHAR Name);
PNOXATTR nox_NodeInsertAttributeValue  (PNOXNODE pNode, PUCHAR AttrName, PUCHAR Value);
PNOXNODE  nox_GetNodeByName   (PNOXNODE pNode, PUCHAR Ctlstr, ... );

PUCHAR   nox_GetNodeValuePtr (PNOXNODE pNode, PUCHAR DefaultValue);
#pragma descriptor ( void nox_GetNodeValuePtr         (void))


void    nox_GetNodeValueStrVC  (
   PLVARCHAR pRes, PNOXNODE pNode, PLVARCHAR DefaultValue);
#pragma descriptor ( void nox_GetNodeValueStrVC             (void))

FIXEDDEC nox_GetNodeValueDec (PNOXNODE pNode, FIXEDDEC DefaultValue);
#pragma descriptor ( void nox_GetNodeValueDec (void))

PUCHAR   nox_GetNodeNamePtr  (PNOXNODE pNode);
void    nox_GetNodeNameVC   (PLVARCHAR name, PNOXNODE pNode);

PNOXNODE  nox_NodeInsertNew (
   PNOXNODE pDest, NOX_REFLOC refloc, PUCHAR Name, PUCHAR Value,NOX_NODETYPE type) ;
void     nox_NodeSet (PNOXNODE pNode, PUCHAR Value);
void     nox_NodeDelete(PNOXNODE pRoot);
void     nox_NodeReplace (PNOXNODE  pDest, PNOXNODE pSource);
PNOXNODE  nox_NodeCopy (PNOXNODE pDest, PNOXNODE pSource, NOX_REFLOC refloc);
void     nox_NodeMerge(PNOXNODE pDest, PNOXNODE pSource, SHORT replace);
PNOXNODE  nox_GetOrCreateNode (PNOXNODE pNodeRoot, PUCHAR Name);

// Attribute navigation:
PNOXATTR nox_GetAttrFirst     (PNOXNODE pNode);
PNOXATTR nox_GetAttrNext      (PNOXATTR pAttr);
PUCHAR   nox_GetAttrNamePtr   (PNOXATTR pAttr);
void     nox_GetAttrNameVC     (PLVARCHAR pRes, PNOXATTR pAttr);

PUCHAR   nox_GetAttrValuePtr  (PNOXATTR pAttr);

void     nox_GetAttrValueVC (
   PLVARCHAR pRes, PNOXATTR pAttr, PLVARCHAR pDefaultValue);
#pragma descriptor ( void nox_GetAttrValueVC                         (void))

FIXEDDEC nox_GetAttrValueDec  (
   PNOXATTR pAttr, FIXEDDEC dftParm);
#pragma descriptor ( void nox_GetAttrValueDec                        (void))

// Get Node Attribute value variants:
PUCHAR   nox_GetNodeAttrValuePtr  (
   PNOXNODE pNode, PUCHAR AttrName, PUCHAR DefaultValue);
#pragma descriptor ( void nox_GetNodeAttrValuePtr                    (void))

void     nox_GetNodeAttrValueVC (
   PLVARCHAR pRes, PNOXNODE pNode ,PLVARCHAR pAttrName, PLVARCHAR  pDefaultValue);
#pragma descriptor ( void nox_GetNodeAttrValueVC                     (void))

FIXEDDEC nox_GetNodeAttrValueDec  (
   PNOXNODE pNode, PUCHAR AttrName, FIXEDDEC DefaultValue);
#pragma descriptor ( void nox_GetNodeAttrValueDec                    (void))

VOID     nox_SetNodeAttrValue     (PNOXNODE pNode, PUCHAR AttrName, PUCHAR Value);

// Get value variants:
PUCHAR  nox_GetValuePtr (
   PNOXNODE pNodeRoot, PUCHAR Name, PUCHAR Default);
#pragma descriptor ( void nox_GetValuePtr    (void))

void nox_GetValueStrVC(
   PLVARCHAR pRes, PNOXNODE pNodeRoot, PLVARCHAR NameP, PLVARCHAR DefaultP);
#pragma descriptor ( void nox_GetValueStrVC     (void))

FIXEDDEC nox_GetValueNum (
   PNOXNODE pNode, PUCHAR Name , FIXEDDEC dftParm);
#pragma descriptor ( void nox_GetValueNum    (void))


void nox_Close(PNOXNODE * pNode);

LGL     nox_IsJson (PNOXNODE pNode);
BOOL    nox_HasMore(PNOXNODE pNode);



PNOXNODE  nox_ArrayPush (PNOXNODE pDest, PNOXNODE pSource, BOOL16 copy);
#pragma descriptor ( void nox_ArrayPush      (void))

PNOXNODE  nox_LookupValue (PNOXNODE pDest, PUCHAR expr, BOOL16 ignorecase);
#pragma descriptor ( void nox_LookupValue    (void))

LONG     nox_getLength (PNOXNODE pNode);
ULONG    nox_NodeCheckSum (PNOXNODE pNode);

PNOXNODE  nox_SetAsciiByName (PNOXNODE pNode, PUCHAR Name, PUCHAR Value);
PNOXNODE  nox_SetStrByName (PNOXNODE pNode, PUCHAR Name, PUCHAR Value);
PNOXNODE  nox_SetDecByName (PNOXNODE pNode, PUCHAR Name, FIXEDDEC Value);
PNOXNODE  nox_SetIntByName (PNOXNODE pNode, PUCHAR Name, INT64  Value);
PNOXNODE  nox_NodeMoveInto (PNOXNODE  pDest, PUCHAR Name, PNOXNODE pSource);
PNOXNODE  nox_SetBoolByName (PNOXNODE pNode, PUCHAR Name, LGL Value);
PNOXNODE  nox_SetBoolByNameVC (PNOXNODE pNode, PLVARCHAR pName, LGL Value, LGL nullIf);
PNOXNODE  nox_Bool (LGL Value);

void nox_NodeCloneAndReplace (PNOXNODE pDest, PNOXNODE pSource);
void nox_Debug(PUCHAR text, PNOXNODE pNode);
void nox_SwapNodes (PNOXNODE * pNode1, PNOXNODE *  pNode2);

PNOXNODE nox_ArraySort(PNOXNODE pNode, PUCHAR fieldsP, BOOL useLocale);
#pragma descriptor ( void nox_ArraySort     (void))


_SYSPTR nox_loadServiceProgram (PUCHAR lib, PUCHAR srvPgm);
_SYSPTR nox_loadProc (_SYSPTR srvPgm,  PUCHAR procName);
_SYSPTR nox_loadServiceProgramProc (PUCHAR lib, PUCHAR srvPgm, PUCHAR procName);
_SYSPTR nox_loadProgram (PUCHAR lib, PUCHAR pgm);
void nox_callProc ( _SYSPTR proc, void * args [64], SHORT parms);
void nox_callPgm  ( _SYSPTR proc, void * args  [], SHORT parms);
void getLibraryForSysPtr (_SYSPTR proc, UCHAR * lib);


// SQL functions
// -------------
#ifndef NOX_SQLSTMT_MAX
#define NOX_SQLSTMT_MAX  32
#endif

#define NOXDB_FIRST_ROW 1
#define NOXDB_ALL_ROWS -1
#define NOXDB_NOX_UNKNOWN_SQL_DATATYPE -99
#define NOXDB_MAX_PARMS  4096


typedef _Packed struct  {
   SQLHSTMT      hstmt;
   BOOL          allocated;
   BOOL          exec;
} NOX_SQLSTMT, * PNOX_SQLSTMT;

typedef _Packed struct  {
   SQLCHAR       colname[256]; // !!!! TODO !!! set len to 32!!
   SQLCHAR       sysname  [64];
   SQLCHAR       realname [64];
   SQLSMALLINT   coltype;
   SQLSMALLINT   colnamelen;
   SQLSMALLINT   nullable;
   SQLINTEGER    collen;
   SQLSMALLINT   scale;
   SQLINTEGER    outlen;
   SQLCHAR *     data;
   SQLINTEGER    displaysize;
   NOX_NODETYPE  nodeType;
   SQLCHAR       header[256];
   SQLCHAR       text[128];
   BOOL          isId;
} NOXCOL, * PNOXCOL;


typedef _Packed struct  {
   LGL         hexSort;
   LGL         sqlNaming;
   UCHAR       DateSep;
   LONG        DateFmt;
   UCHAR       TimeSep;
   LONG        TimeFmt;
   UCHAR       DecimalPoint;
   LGL         upperCaseColName;
   LGL         autoParseContent;
}  NOX_SQLOPTIONS, * PNOX_SQLOPTIONS;

typedef struct {
   SQLINTEGER  inLen ;
   SQLINTEGER  bufLen;
   PUCHAR      buffer   ;
   PUCHAR      name  ;
   SHORT       type  ;
   SQLSMALLINT mode     ;
   SQLSMALLINT sqlType  ;
   PNOXNODE    pNode        ;
   PUCHAR      pData       ;
   BOOL        isBool;
} NOX_PROCPARM ,* PNOX_PROCPARM;

typedef _Packed struct  {
   LGL         doTrace;
   UCHAR       lib[11];
   SQLHSTMT    handle;
   UCHAR       tsStart [27];
   UCHAR       tsEnd   [27];
   LONG        sqlCode;
   UCHAR       text  [256];
   UCHAR       job [29];
   INT64       trid;
}  NOX_TRACE , * PNOX_TRACE;

#define  COMMENT_SIZE 4096
#define  DATA_SIZE 65535
#define  INVALIDCHAR 0x3f
#define  LOOK_AHEAD_SIZE (65535-512)

typedef _Packed struct  {
   SQLHENV       henv;
   SQLHDBC       hdbc;
   PNOXNODE      pOptions;
   BOOL          pOptionsCleanup;
   NOX_SQLOPTIONS    options;
   iconv_t       iconv;
   UCHAR         sqlState[5];
   LONG          sqlCode;
   UCHAR         sqlMsgDta[SQL_MAX_MESSAGE_LENGTH + 1];
   NOX_SQLSTMT    stmts[NOX_SQLSTMT_MAX];
   SHORT         stmtIx;
   NOX_TRACE      sqlTrace;
   BOOL          transaction;
} NOX_SQLCONNECT, * PNOX_SQLCONNECT;

typedef _Packed struct  {
// SQLHENV       henv;
// SQLHDBC       hdbc;
// SQLHSTMT      hstmt;
   PNOX_SQLSTMT   pstmt;
   PUCHAR        sqlstmt;
   SQLSMALLINT   nresultcols;
   SQLINTEGER    rowcount;
   SQLRETURN     rc;
// PNOXNODE       pRowNode;
// NOX_SQLOPTIONS    options;
// PNOXNODE       pOptions;
// BOOL          deleteOptions;
   PNOXCOL        cols;
   PNOX_SQLCONNECT pCon;
   LONG           maxColSize;

} NOX_SQL, * PNOX_SQL;


typedef enum _NOX_RESULTSET {
   NOX_CAMEL_CASE = 0,
   NOX_META       = 1,
   NOX_FIELDS     = 2,
   NOX_TOTALROWS  = 4,
   NOX_SYSTEM_CASE  = 8,
   NOX_APROXIMATE_TOTALROWS = 16,
   NOX_SYSTEM_NAMES       = 32,
   NOX_GRACEFUL_ERROR       = 128,
   NOX_COLUMN_TEXT         = 256
} NOX_RESULTSET, *PNOX_RESULTSET;

typedef _Packed struct _NOX_SQLCHUNK {
   SQLINTEGER actLen;
   SQLINTEGER chunkLen;
   SQLINTEGER offset;
   PUCHAR value;
} NOX_SQLCHUNK, *PNOX_SQLCHUNK;


PNOXNODE nox_sqlResultRow (
   PNOX_SQLCONNECT pCon, PUCHAR sqlstmt, PNOXNODE pSqlParms, LONG format, LONG start );
#pragma descriptor ( void nox_sqlResultRow   (void))

PNOXNODE nox_sqlResultRowVC (
   PNOX_SQLCONNECT pCon, PLVARCHAR sqlstmt, PNOXNODE pSqlParmsP, LONG format ,LONG start );
#pragma descriptor ( void nox_sqlResultRowVC   (void))

PNOXNODE nox_sqlResultSet(
   PNOX_SQLCONNECT pCon ,PUCHAR sqlstmt, PNOXNODE pSqlParms, LONG format, LONG start, LONG limit);
#pragma descriptor ( void nox_sqlResultSet   (void))

PNOXNODE nox_sqlResultSetVC(
   PNOX_SQLCONNECT pCon, PLVARCHAR sqlstmt, PNOXNODE pSqlParms, LONG format, LONG start, LONG limit );
#pragma descriptor ( void nox_sqlResultSetVC   (void))

PNOX_SQL nox_sqlOpen(
   PNOX_SQLCONNECT pCon, PUCHAR sqlstmt, PNOXNODE pSqlParms, LONG format, LONG start, LONG limit);
#pragma descriptor ( void nox_sqlOpen        (void))

PNOX_SQL nox_sqlOpenVC(
   PNOX_SQLCONNECT pCon, PLVARCHAR sqlstmt, PNOXNODE pSqlParmsP, LONG format, LONG start, LONG limit);
#pragma descriptor ( void nox_sqlOpenVC       (void))

LGL nox_sqlUpdate (
   PNOX_SQLCONNECT pCon, PUCHAR table, PNOXNODE pRow, PUCHAR whereP, PNOXNODE pSqlParmsP);
#pragma descriptor ( void nox_sqlUpdate      (void))

LGL nox_sqlUpdateVC (
   PNOX_SQLCONNECT pCon, PLVARCHAR table, PNOXNODE pRow, PLVARCHAR whereP, PNOXNODE pSqlParmsP);
#pragma descriptor ( void nox_sqlUpdateVC      (void))

LGL nox_sqlInsert (
   PNOX_SQLCONNECT pCon,PUCHAR table, PNOXNODE pRow, PUCHAR whereP, PNOXNODE pSqlParmsP);
#pragma descriptor ( void nox_sqlInsert      (void))

LGL nox_sqlInsertVC (
   PNOX_SQLCONNECT pCon,PLVARCHAR table, PNOXNODE pRow, PLVARCHAR whereP, PNOXNODE pSqlParmsP);
#pragma descriptor ( void nox_sqlInsertVC      (void))

LGL nox_sqlUpsert (
   PNOX_SQLCONNECT pCon, PUCHAR table, PNOXNODE pRow, PUCHAR whereP, PNOXNODE pSqlParmsP);
#pragma descriptor ( void nox_sqlUpsert      (void))

LGL nox_sqlUpsertVC (
   PNOX_SQLCONNECT pCon, PLVARCHAR table, PNOXNODE pRow, PLVARCHAR whereP, PNOXNODE pSqlParmsP);
#pragma descriptor ( void nox_sqlUpsertVC    (void))

LONG nox_sqlNumberOfRows(
   PNOX_SQLCONNECT pCon, PUCHAR sqlstmt);
#pragma descriptor ( void nox_sqlNumberOfRows    (void))

LONG nox_sqlNumberOfRowsVC(
   PNOX_SQLCONNECT pCon ,PLVARCHAR sqlstmt);
#pragma descriptor ( void nox_sqlNumberOfRowsVC  (void))

PNOXNODE nox_sqlFetchRelative (PNOX_SQL pSQL, LONG fromRow);
PNOXNODE nox_sqlFetchNext (PNOX_SQL pSQL);
void nox_sqlClose (PNOX_SQL * ppSQL);

PNOXNODE nox_sqlGetMeta (
   PNOX_SQLCONNECT pCon, PUCHAR sqlstmt);

LGL  nox_sqlExec (
   PNOX_SQLCONNECT pCon, PUCHAR sqlstmt, PNOXNODE pSqlParms);
#pragma descriptor ( void nox_sqlExec        (void))

LGL nox_sqlExecVC(
   PNOX_SQLCONNECT pCon,PLVARCHAR sqlstmt, PNOXNODE pSqlParmsP);
#pragma descriptor ( void nox_sqlExecVC      (void))

PNOX_SQLCONNECT  nox_sqlConnect(PNOXNODE pSqlParms  );
#pragma descriptor ( void nox_sqlConnect    (void))

void nox_sqlDisconnect (
   PNOX_SQLCONNECT * ppCon);
void nox_traceOpen (
   PNOX_SQLCONNECT pCon);
void nox_traceInsert (PNOX_SQL pSQL, PUCHAR stmt, PUCHAR sqlState);

typedef void (*NOX_TRACE_PROC) ( PUCHAR text, PNOXNODE pNode);
typedef void (*NOX_DATAINTO)();



PUCHAR getSystemColumnName (
   PUCHAR sysColumnName, PUCHAR columnText, PUCHAR schema, PUCHAR table, PUCHAR column );

INT64 nox_GetValueInt (PNOXNODE pNode, PUCHAR NameP , INT64 dftParm);


#endif