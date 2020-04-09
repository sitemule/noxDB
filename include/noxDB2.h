#ifndef NOXDB
#define NOXDB
#include <stdio.h>
#include <iconv.h>
#include <sqlcli.h>
#include "ostypes.h"     //
#include "streamer.h"
#include "apierr.h"
#include "xlate.h"
#ifndef XMLPARSE_H
#define XMLPARSE_H

#ifndef OCCURENS_TYPE
#define OCCURENS_TYPE  
typedef enum {
	OC_NONE = 0,
	OC_NEXT_FOLLOWS = 1,
	OC_EITHER_OR = 2
} OCCURENS , *POCCURENS;
#endif

typedef decimal(30,15) FIXEDDEC, * PFIXEDDEC;

/*
#define UTF8CONST(a) (\
#pragma convert(1252) \ 
a \ 
#pragma convert(0)\
)
*/

#pragma convert(1252)

#define  UBOUND    "UBOUND"
#define  NULLSTR   "null"
#define  TRUESTR   "true"
#define  FALSESTR  "false"
#define  REMARK    "!--"
#define  DOCTYPE   "!DOCTYPE"
#define  ENDREMARK "-->"
#define  SLASHGT   "/>"
#define  BRABRAGT  "]]>"
#define  CDATA     "<![CDATA["

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
#define  DELIMITERS   "/\\@[] .{}'\""
#pragma convert(0)


#define ATTRSIG 0x03
typedef struct _NOXATTR {
	UCHAR  signature; // always hex 03
	LONG   Handle;
	PUCHAR Name;
	PUCHAR Value;
	struct _NOXATTR    * pAttrSibling;
	PVOID pNodeParent;
} NOXATTR, *PNOXATTR;

typedef enum {
	UNKNOWN             = 0,
	OBJECT              = 1,
	ARRAY               = 2,
	PARSE_STRING        = 3,
	POINTER_VALUE       = 4,
	VALUE               = 5,
	NOX_VALUE           = 5,
	ROOT                = 6,
	LITERAL             = 16,
	NOX_LITERAL         = 16,
	CLONE_OLD           = 17,  // Was OBJLNK - Obsolete yes but maps to CLONE in appplication
	CLONE               = 18,  // Obsolete ... NO
	EVALUATE            = 19,  // Obsolete ??
	OBJMOVE             = 2048,
	// Values to be or'ed ( + ) with EVALUATE and PARSE_STRING
	// Note: "Merge options" are fit in here... from belowe
	NT_MOVE             =2048,  // Unlink the source and move it to destination
	NT_ALLOW_PRIMITIVES =4096   // Allow strings ints and other valyes to evaluate with PARSE_STRING

} NODETYPE, *PNODETYPE;
typedef NODETYPE  JSTATE, *PJSTATE;

typedef enum {
	// Values to be or'ed ( + ) with EVALUATE and PARSE_STRING
	MO_MERGE_NEW      =   256,  // Only new elements are merged - existing are left untouched
	MO_MERGE_MATCH    =   512,  // Merge and replace only existing nodes
	MO_MERGE_REPLACE  =  1024   // Merge all: replace if it exists and append new nodes if not exists
} MERGEOPTION , *PMERGEOPTION;

#define NODESIG  0x02
typedef struct _NOXNODE {
	UCHAR  signature; // always hex 02
	LONG   Handle;
	PUCHAR Name;
	SHORT  Seq;
	PNOXATTR pAttrList;
	PUCHAR Value;
	struct _NOXNODE * pNodeParent;
	struct _NOXNODE * pNodeChildHead;
	struct _NOXNODE * pNodeChildTail;
	struct _NOXNODE * pNodeSibling;
	LONG     Count;
	BOOL     newlineInAttrList;
	PUCHAR   Comment;
	NODETYPE type;
	BOOL     doCount;
	LONG     lineNo;
	BOOL     isLiteral;
	SHORT    ccsid;
} NOXNODE, *PNOXNODE;

typedef struct _NOXSEGMENT {
	LONG    nodeCount;
	PNOXNODE * nodeArray;
} NOXSEGMENT , *PNOXSEGMENT;

typedef enum {
	XML_FIND_START_TOKEN,
	XML_DETERMIN_TAG_TYPE,
	XML_FIND_END_TOKEN,
	XML_BUILD_NAME,
	XML_COLLECT_DATA,
	XML_ATTR_NAME,
	XML_ATTR_VALUE,
	XML_DELIMITER,
	XML_EXIT,
	XML_EXIT_ERROR
} XMLSTATE, *PXMLSTATE;


typedef struct {
	PNOXNODE pNodeRoot;
	FILE *  File;
	PUCHAR  FileName;
	XMLSTATE State;
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
} NOXCOM , * PNOXCOM;

typedef enum {
	RL_FIRST_CHILD = 1,
	RL_LAST_CHILD = 2,
	RL_BEFORE_SIBLING = 3,
	RL_AFTER_SIBLING = 4,
	RL_REPLACE = 5
} REFLOC, *PREFLOC;

typedef struct _TOK{
	BOOL    isEof;
	UCHAR   token ;
	BOOL    isLiteral;
	LONG    len;
	PUCHAR  data;
	LONG    count;
} TOK, *PTOK;

typedef _Packed struct  _JWRITE      {
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
} JWRITE, * PJWRITE;

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
} NOXITERATOR , * PNOXITERATOR ;



#endif

// Prototypes  - utilities
LONG xlateMem  (iconv_t xid , PUCHAR out , PUCHAR in, LONG len);
void nox_WriteJsonStmf (PNOXNODE pNode, PUCHAR FileName, int Ccsid, LGL trimOut, PNOXNODE options);
void nox_AsJsonText (PLVARCHAR retVal, PNOXNODE pNode);
void nox_AsJsonTextList (PNOXNODE pNode, PJWRITE pJwrite);
void nox_AsJsonStream (PNOXNODE pNode, PSTREAM pStream);
LONG nox_AsJsonTextMem (PNOXNODE pNode, PUCHAR buf , ULONG maxLenP);
#pragma descriptor ( void nox_AsJsonTextMem                     (void))

LONG nox_fileWriter  (PSTREAM pStream , PUCHAR buf , ULONG len);
LONG nox_memWriter  (PSTREAM pStream, PUCHAR buf , ULONG len);
void  jsonStreamPrintNode (PNOXNODE pNode, PSTREAM pStream, SHORT level);
void  jsonStreamPrintValue   (PNOXNODE pNode, PSTREAM pStream);
void  jsonStreamPrintArray (PNOXNODE pParent, PSTREAM pStream, SHORT level);
void  jsonStreamPrintObject  (PNOXNODE pParent, PSTREAM pStream, SHORT level);
void  indent (PSTREAM pStream , int indent);
PUCHAR nox_EncodeJson (PUCHAR out , PUCHAR in);
void  nox_EncodeJsonStream (PSTREAM p , PUCHAR in);
PUCHAR c2s(UCHAR c);
PUCHAR strTrim(PUCHAR s);
UCHAR hex (UCHAR c)     ;
PUCHAR findchr (PUCHAR base , PUCHAR chars, SHORT charslen) ;
void xlatecpy( PNOXCOM pJxCom ,PUCHAR out , PUCHAR in  , LONG len);
int cpy (PUCHAR out , PUCHAR in)                                  ;
void iconvWrite( FILE * f, iconv_t * pIconv, PUCHAR Value, BOOL Esc);
void iconvPutc( FILE * f, iconv_t * pIconv, UCHAR c);
void swapEndian(PUCHAR buf, LONG len)                                ;
LONG xlate(PNOXCOM pJxCom, PUCHAR outbuf, PUCHAR inbuf , LONG len)    ;
int readBlock(PNOXCOM pJxCom , PUCHAR buf, int size)                  ;
BOOL isTimeStamp(PUCHAR p)                                           ;
int formatTimeStamp(PUCHAR p , PUCHAR s)                             ;
UCHAR unicode2ebcdic (USHORT c)                                      ;
int parsehex(UCHAR c)                                                ;
BOOL isTerm(UCHAR c, PUCHAR term);


// Prototypes  - file reader
void initconst(int ccsid);
PUCHAR nox_GetChar(PNOXCOM pJxCom);
UCHAR SkipBlanks (PNOXCOM pJxCom);
void  nox_SkipChars(PNOXCOM pJxCom , int skip);
void nox_CheckEnd(PNOXCOM pJxCom) ;
int readBlock(PNOXCOM pJxCom , PUCHAR buf, int size);

// Prototypes  - main
void nox_FreeChildren (PNOXNODE pNode);
PUCHAR nox_GetChar(PNOXCOM pJxCom);
void nox_SetMessage (PUCHAR Ctlstr , ... );
void nox_NodeFreeNodeOnly(PNOXNODE pNode);

// Prototypes  - main  - exports
void nox_NodeAddChildHead( PNOXNODE pRoot, PNOXNODE pChild);
void nox_NodeAddChildTail( PNOXNODE pRoot, PNOXNODE pChild);
void nox_NodeAddSiblingBefore( PNOXNODE pRef, PNOXNODE pSibling);
void nox_NodeAddSiblingAfter( PNOXNODE pRef, PNOXNODE pSibling);

LGL nox_ParseStmfFile (PNOXNODE  * ppRoot , PUCHAR FileName , PUCHAR Mode);
#pragma descriptor ( void nox_ParseStmfFile                     (void))

BOOL nox_ParseJson(PNOXCOM pJxCom);
BOOL nox_ParseXml (PNOXCOM pJxCom);
BOOL nox_ParseJsonNode(PNOXCOM pJxCom, JSTATE state,  PUCHAR name , PNOXNODE pCurNode );
PNOXNODE nox_NodeClone  (PNOXNODE pSource);
void nox_NodeMoveAndReplace (PNOXNODE  pDest, PNOXNODE pSource);
/* ------ */
void nox_SetDecPoint(PUCHAR p);
//void nox_SetDelimiters(PNOXDELIM pDelim);
//void nox_SetDelimiters2(PNOXDELIM pDelim);
//void nox_CloneFormat(PNOXNODE pNode, PNOXNODE pSource);

LGL nox_Has  (PNOXNODE pNode, PUCHAR Name);
#pragma descriptor ( void nox_Has                               (void))

LGL nox_IsTrue  (PNOXNODE pNode, PUCHAR Name);
#pragma descriptor ( void nox_IsTrue                            (void))

LGL nox_IsNull  (PNOXNODE pNode, PUCHAR Name);
#pragma descriptor ( void nox_IsNull                            (void))

NOXITERATOR nox_SetIterator (PNOXNODE pNode , PUCHAR path);
#pragma descriptor ( void nox_SetIterator                       (void))

NOXITERATOR nox_SetRecursiveIterator (PNOXNODE pNode , PUCHAR path);
#pragma descriptor ( void nox_SetRecursiveIterator              (void))

LGL nox_ForEach (PNOXITERATOR pIter);
PNOXNODE nox_GetParent(PNOXNODE pNode);
SHORT nox_GetNodeType (PNOXNODE pNode);

VARCHAR nox_GetNodeNameAsPath (PNOXNODE pNode, UCHAR Delimiter);
#pragma descriptor ( void nox_GetNodeNameAsPath                 (void))

void nox_CopyValueByNameVC (PLVARCHAR pRes, PNOXNODE pNodeRoot, PLVARCHAR pName, PLVARCHAR pDefault , BOOL joinString);
#pragma descriptor ( void  nox_CopyValueByNameVC                (void))


void nox_WriteXmlStmfNodeList (FILE * f, iconv_t * pIconv ,PNOXNODE pNode);

void nox_WriteXmlStmf (PNOXNODE pNode, PUCHAR FileName, int Ccsid, LGL trimOut , PNOXNODE options);
#pragma descriptor ( void nox_WriteXmlStmf       (void))

void nox_WriteJsonStmf (PNOXNODE pNode, PUCHAR FileName, int Ccsid, LGL trimOut, PNOXNODE options);
#pragma descriptor ( void nox_WriteJsonStmf      (void))

void nox_WriteCsvStmf (PNOXNODE pNode, PUCHAR FileName, int Ccsid, LGL trimOut, PNOXNODE options);
#pragma descriptor ( void nox_WriteCsvStmf      (void))

PNOXNODE  nox_ParseFile  (PUCHAR FileName);
PNOXNODE  nox_ParseString  (PUCHAR Buf);
PNOXNODE  nox_NewObject (void);
PNOXNODE  nox_NewArray (void);

PUCHAR   nox_GetValueByName (PNOXNODE pNode, PUCHAR Name, PUCHAR Default);
#pragma descriptor ( void nox_GetValueByName (void))

PNOXNODE  nox_SetValueByName (PNOXNODE pNodeRoot, PUCHAR Name, PUCHAR Value, NODETYPE type);
#pragma descriptor ( void nox_SetValueByName (void))

void     nox_AsXmlText (PLVARCHAR retVal, PNOXNODE pNode);
PUCHAR   nox_NodeAsXmlTextList (PNOXNODE pNode, PUCHAR temp);
BOOL     nox_Parse (PNOXCOM pJxCom);
LGL      nox_Error (PNOXNODE pJxNode);
VOID     nox_SetApiErr  (PNOXNODE pJxNode , PAPIERR pApiErr );
PUCHAR   nox_ErrStr(PNOXNODE pJxNode);
VARCHAR1024  nox_MessageVC  (PNOXNODE pJxNode);
void     nox_Dump  (PNOXNODE pJxNode);
void     nox_Free  (PNOXNODE pJxNode);
PNOXNODE  nox_GetNode  (PNOXNODE pNode, PUCHAR Name) ;
#pragma descriptor ( void nox_GetNode                                              (void))

PNOXNODE  nox_GetNodeChild (PNOXNODE pNode);
PNOXNODE  nox_GetNodeChildNo (PNOXNODE pNode, int childNo);
PNOXNODE  nox_GetNodeNext (PNOXNODE pNode);
PNOXNODE  nox_GetNodeParent  (PNOXNODE pNode);
PNOXATTR nox_AttributeLookup   (PNOXNODE pNode, PUCHAR Name);
PNOXATTR nox_NodeAddAttributeValue  (PNOXNODE pNode , PUCHAR AttrName, PUCHAR Value);
PNOXNODE  nox_GetNodeByName   (PNOXNODE pNode, PUCHAR Ctlstr , ... );

PUCHAR   nox_GetNodeValuePtr (PNOXNODE pNode, PUCHAR DefaultValue);
#pragma descriptor ( void nox_GetNodeValuePtr                                      (void))


void    nox_GetNodeValueVC  (PLVARCHAR pRes, PNOXNODE pNode , PLVARCHAR DefaultValue);
#pragma descriptor ( void nox_GetNodeValueVC                                       (void))

FIXEDDEC nox_GetNodeValueNum (PNOXNODE pNode , FIXEDDEC DefaultValue);
#pragma descriptor ( void nox_GetNodeValueNum                                      (void))

PUCHAR   nox_GetNodeNamePtr  (PNOXNODE pNode);
void    nox_GetNodeNameVC   (PLVARCHAR name, PNOXNODE pNode);

PNOXNODE  nox_NodeAdd (PNOXNODE pDest, REFLOC refloc, PUCHAR Name , PUCHAR Value, NODETYPE type) ;
void     nox_NodeSet (PNOXNODE pNode , PUCHAR Value);
void     nox_NodeDelete(PNOXNODE pRoot);
void     nox_NodeReplace (PNOXNODE  pDest, PNOXNODE pSource);
PNOXNODE  nox_NodeCopy (PNOXNODE pDest, PNOXNODE pSource, REFLOC refloc);
void     nox_NodeMerge(PNOXNODE pDest, PNOXNODE pSource, SHORT replace);
PNOXNODE  nox_GetOrCreateNode (PNOXNODE pNodeRoot, PUCHAR Name);

// Attribute navigation:
PNOXATTR nox_GetAttrFirst     (PNOXNODE pNode);
PNOXATTR nox_GetAttrNext      (PNOXATTR pAttr);
PUCHAR   nox_GetAttrNamePtr   (PNOXATTR pAttr);
void     nox_GetAttrNameVC     (PLVARCHAR pRes, PNOXATTR pAttr);

PUCHAR   nox_GetAttrValuePtr  (PNOXATTR pAttr);

void     nox_GetAttrValueVC (PLVARCHAR pRes, PNOXATTR pAttr, PLVARCHAR pDefaultValue);
#pragma descriptor ( void nox_GetAttrValueVC                                       (void))

FIXEDDEC nox_GetAttrValueNum  (PNOXATTR pAttr, FIXEDDEC dftParm);
#pragma descriptor ( void nox_GetAttrValueNum                                      (void))

// Get Node Attribute value variants:
PUCHAR   nox_GetNodeAttrValuePtr  (PNOXNODE pNode, PUCHAR AttrName, PUCHAR DefaultValue);
#pragma descriptor ( void nox_GetNodeAttrValuePtr                                  (void))

void     nox_GetNodeAttrValueVC (PLVARCHAR pRes, PNOXNODE pNode ,PLVARCHAR pAttrName, PLVARCHAR  pDefaultValue);
#pragma descriptor ( void nox_GetNodeAttrValueVC                                   (void))

FIXEDDEC nox_GetNodeAttrValueNum  (PNOXNODE pNode , PUCHAR AttrName, FIXEDDEC DefaultValue);
#pragma descriptor ( void nox_GetNodeAttrValueNum                                  (void))

VOID     nox_SetNodeAttrValue     (PNOXNODE pNode , PUCHAR AttrName, PUCHAR Value);

// Get value variants:
PUCHAR  nox_GetValuePtr (PNOXNODE pNodeRoot, PUCHAR Name, PUCHAR Default) ;
#pragma descriptor ( void nox_GetValuePtr    (void))

void nox_GetValueVC(PLVARCHAR pRes, PNOXNODE pNodeRoot, PLVARCHAR NameP, PLVARCHAR DefaultP);
#pragma descriptor ( void nox_GetValueVC     (void))

FIXEDDEC nox_GetValueNum (PNOXNODE pNode , PUCHAR Name  , FIXEDDEC dftParm);
#pragma descriptor ( void nox_GetValueNum    (void))


void nox_Close(PNOXNODE * pNode);

LGL     nox_IsJson (PNOXNODE pNode);
BOOL    nox_HasMore(PNOXNODE pNode);

/* Internals */
void     nox_SkipBlanks(BOOL skip);
BOOL    JSON_Parse(PNOXCOM pJxCom);
BOOL    jsonParseNode(PNOXCOM pJxCom, JSTATE state,  PUCHAR name , PNOXNODE pCurNode) ;
void    AddNode(PNOXNODE pDest, PNOXNODE pSource, REFLOC refloc);
PNOXNODE DupNode(PNOXNODE pSource);
PNOXNODE NewNode (PUCHAR Name , PUCHAR Value, NODETYPE type);
PNOXNODE CloneNode  (PNOXNODE pSource);
PNOXNODE NewRoot(void);

PNOXNODE  nox_ArrayPush (PNOXNODE pDest, PNOXNODE pSource , BOOL16 copy);
#pragma descriptor ( void nox_ArrayPush      (void))

PNOXNODE  nox_LookupValue (PNOXNODE pDest, PUCHAR expr , BOOL16 ignorecase);
#pragma descriptor ( void nox_LookupValue    (void))

LONG     nox_getLength (PNOXNODE pNode);
ULONG    nox_NodeCheckSum (PNOXNODE pNode);

PNOXNODE  nox_SetStrByName (PNOXNODE pNode, PUCHAR Name, PUCHAR Value);
PNOXNODE  nox_SetBoolByName (PNOXNODE pNode, PUCHAR Name, BOOL Value);
PNOXNODE  nox_SetDecByName (PNOXNODE pNode, PUCHAR Name, FIXEDDEC Value);
PNOXNODE  nox_SetIntByName (PNOXNODE pNode, PUCHAR Name, LONG Value);
PNOXNODE  nox_NodeMoveInto (PNOXNODE  pDest, PUCHAR Name , PNOXNODE pSource);
void nox_NodeCloneAndReplace (PNOXNODE pDest , PNOXNODE pSource);
void nox_Debug(PUCHAR text, PNOXNODE pNode);
void nox_SwapNodes (PNOXNODE * pNode1, PNOXNODE *  pNode2);

PNOXNODE nox_ArraySort(PNOXNODE pNode, PUCHAR fieldsP, BOOL useLocale);
#pragma descriptor ( void nox_ArraySort     (void))


// SQL functions
// -------------
#ifndef NOXSQLSTMT_MAX
#define NOXSQLSTMT_MAX  32
#endif

typedef _Packed struct  {
	 SQLHSTMT      hstmt;
	 BOOL          allocated;
	 BOOL          exec;
} NOXSQLSTMT, * PNOXSQLSTMT;

typedef _Packed struct  {
	 SQLCHAR       colname[256]; // !!!! TODO !!! set len to 32!!
	 SQLSMALLINT   coltype;
	 SQLSMALLINT   colnamelen;
	 SQLSMALLINT   nullable;
	 SQLINTEGER    collen;
	 SQLSMALLINT   scale;
	 SQLINTEGER    outlen;
	 SQLCHAR *     data;
	 SQLINTEGER    displaysize;
	 NODETYPE      nodeType;
	 SQLCHAR       header[256];
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
}  SQLOPTIONS, * PSQLOPTIONS;

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
}  NOXTRACE  , * PNOXTRACE;

#define  COMMENT_SIZE 4096
#define  DATA_SIZE 65535
#define  INVALIDCHAR 0x3f
#define  LOOK_AHEAD_SIZE (65535-512)

typedef _Packed struct  {
	 SQLHENV       henv;
	 SQLHDBC       hdbc;
	 PNOXNODE      pOptions;
	 BOOL          pOptionsCleanup;
	 SQLOPTIONS    options;
	 PXLATEDESC    pCd;
	 UCHAR         sqlState[5];
	 LONG          sqlCode;
	 UCHAR         sqlMsgDta[SQL_MAX_MESSAGE_LENGTH + 1];
	 NOXSQLSTMT    stmts[NOXSQLSTMT_MAX];
	 SHORT         stmtIx;
	 NOXTRACE      sqlTrace;
} NOXSQLCONNECT , * PNOXSQLCONNECT;

typedef _Packed struct  {
// SQLHENV       henv;
// SQLHDBC       hdbc;
// SQLHSTMT      hstmt;
	 PNOXSQLSTMT   pstmt;
	 PUCHAR        sqlstmt;
	 SQLSMALLINT   nresultcols;
	 SQLINTEGER    rowcount;
	 SQLRETURN     rc;
// PNOXNODE       pRowNode;
// SQLOPTIONS    options;
// PNOXNODE       pOptions;
// BOOL          deleteOptions;
	 PNOXCOL        cols;
	 PNOXSQLCONNECT pCon;

} NOXSQL, * PNOXSQL;


typedef enum _NOX_RESULTSET {
	 NOX_META       = 1,
	 NOX_FIELDS     = 2,
	 NOX_TOTALROWS  = 4,
	 NOX_UPPERCASE  = 8,
	 NOX_APROXIMATE_TOTALROWS = 16
} NOX_RESULTSET, *PNOX_RESULTSET;

typedef _Packed struct _SQLCHUNK {
   SQLINTEGER actLen;
   SQLINTEGER chunkLen;
   SQLINTEGER offset;
   PUCHAR value;
} SQLCHUNK, *PSQLCHUNK;


VOID TRACE ( UCHAR lib[11] , PLGL doTrace , UCHAR job [32]);

PNOXNODE nox_sqlResultRow ( PNOXSQLCONNECT pCon, PUCHAR sqlstmt, PNOXNODE pSqlParmsP, LONG startAt) ;
#pragma descriptor ( void nox_sqlResultRow   (void))
PNOXNODE nox_sqlResultRowVC ( PNOXSQLCONNECT pCon, PLVARCHAR sqlstmt,  PNOXNODE pSqlParmsP , LONG startP);
#pragma descriptor ( void nox_sqlResultRowVC   (void))


PNOXNODE nox_sqlResultSet( PNOXSQLCONNECT pCon, PUCHAR sqlstmt, LONG startP, LONG limitP, LONG formatP , PNOXNODE pSqlParmsP);
#pragma descriptor ( void nox_sqlResultSet   (void))
PNOXNODE nox_sqlResultSetVC( PNOXSQLCONNECT pCon, PLVARCHAR sqlstmt, LONG startP, LONG limitP, LONG formatP , PNOXNODE pSqlParmsP);
#pragma descriptor ( void nox_sqlResultSetVC   (void))


PNOXSQL nox_sqlOpen(PNOXSQLCONNECT pCon, PUCHAR sqlstmt , PNOXNODE pSqlParms, BOOL scroll);
#pragma descriptor ( void nox_sqlOpen        (void))
PNOXSQL nox_sqlOpenVC(PNOXSQLCONNECT pCon, PLVARCHAR sqlstmt , PNOXNODE pSqlParmsP, BOOL scrollP);
#pragma descriptor ( void nox_sqlOpenVC       (void))


LGL nox_sqlUpdate (PNOXSQLCONNECT pCon, PUCHAR table  , PNOXNODE pRow , PUCHAR whereP, PNOXNODE pSqlParmsP);
#pragma descriptor ( void nox_sqlUpdate      (void))
LGL nox_sqlUpdateVC (PNOXSQLCONNECT pCon, PLVARCHAR table  , PNOXNODE pRow , PLVARCHAR whereP, PNOXNODE pSqlParmsP);
#pragma descriptor ( void nox_sqlUpdateVC      (void))


LGL nox_sqlInsert (PNOXSQLCONNECT pCon,PUCHAR table  , PNOXNODE pRow , PUCHAR whereP, PNOXNODE pSqlParmsP);
#pragma descriptor ( void nox_sqlInsert      (void))
LGL nox_sqlInsertVC (PNOXSQLCONNECT pCon,PLVARCHAR table  , PNOXNODE pRow , PLVARCHAR whereP, PNOXNODE pSqlParmsP);
#pragma descriptor ( void nox_sqlInsertVC      (void))


LGL nox_sqlUpsert (PNOXSQLCONNECT pCon, PUCHAR table  , PNOXNODE pRow , PUCHAR whereP, PNOXNODE pSqlParmsP);
#pragma descriptor ( void nox_sqlUpsert      (void))
LGL nox_sqlUpsertVC (PNOXSQLCONNECT pCon, PLVARCHAR table  , PNOXNODE pRow , PLVARCHAR whereP, PNOXNODE pSqlParmsP);
#pragma descriptor ( void nox_sqlUpsertVC    (void))


LONG nox_sqlNumberOfRows(PNOXSQLCONNECT pCon,PUCHAR sqlstmt);
#pragma descriptor ( void nox_sqlNumberOfRows    (void))
LONG nox_sqlNumberOfRowsVC(PNOXSQLCONNECT pCon ,PLVARCHAR sqlstmt);
#pragma descriptor ( void nox_sqlNumberOfRowsVC  (void))

PNOXNODE nox_sqlFetchRelative (PNOXSQL pSQL, LONG fromRow);
PNOXNODE nox_sqlFetchNext (PNOXSQL pSQL);

void nox_sqlClose (PNOXSQL * ppSQL);
PNOXNODE nox_sqlGetMeta (PNOXSQLCONNECT pCon, PUCHAR sqlstmt);


LGL  nox_sqlExec (PNOXSQLCONNECT pCon, PUCHAR sqlstmt , PNOXNODE pSqlParms);
#pragma descriptor ( void nox_sqlExec        (void))
LGL nox_sqlExecVC(PNOXSQLCONNECT pCon,PLVARCHAR sqlstmt , PNOXNODE pSqlParmsP);
#pragma descriptor ( void nox_sqlExecVC      (void))


PNOXSQLCONNECT  nox_sqlConnect(PNOXNODE pSqlParms  );
#pragma descriptor ( void nox_sqlConnect    (void))

void nox_sqlDisconnect (PNOXSQLCONNECT * ppCon);
void nox_traceOpen (PNOXSQLCONNECT pCon);
void nox_traceInsert (PNOXSQL pSQL, PUCHAR stmt , PUCHAR sqlState);

#endif