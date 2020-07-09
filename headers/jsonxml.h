#ifndef JSONXML
#define JSONXML
#include <stdio.h>
#include <iconv.h>
#include <sqlcli.h>
#ifdef IFSCOMPILE
 #include "/qsys.lib/include.lib/h.file/ostypes.mbr"
#else
 #include "ostypes.h"     //
 #include "streamer.h"
 #include "apierr.h"
 #include "xlate.h"
#endif
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

#define ATTRSIG 0x03
typedef struct _XMLATTR {
	UCHAR  signature; // always hex 03
	LONG   Handle;
	PUCHAR Name;
	PUCHAR Value;
	struct _XMLATTR    * pAttrSibling;
	PVOID pNodeParent;
} XMLATTR, *PXMLATTR;

typedef enum {
	UNKNOWN             = 0,
	OBJECT              = 1,
	ARRAY               = 2,
	PARSE_STRING        = 3,
	POINTER_VALUE       = 4,
	VALUE               = 5,
	JX_VALUE            = 5,
	ROOT                = 6,
	LITERAL             = 16,
	JX_LITERAL          = 16,
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
typedef struct _JXNODE {
	UCHAR  signature; // always hex 02
	LONG   Handle;
	PUCHAR Name;
	SHORT  Seq;
	PXMLATTR pAttrList;
	PUCHAR Value;
	struct _JXNODE * pNodeParent;
	struct _JXNODE * pNodeChildHead;
	struct _JXNODE * pNodeChildTail;
	struct _JXNODE * pNodeSibling;
	LONG     Count;
	BOOL     newlineInAttrList;
	PUCHAR   Comment;
	NODETYPE type;
	BOOL     doCount;
	LONG     lineNo;
	BOOL     isLiteral;
	SHORT    ccsid;
} JXNODE, *PJXNODE;

typedef struct _JXSEGMENT {
	LONG    nodeCount;
	PJXNODE * nodeArray;
} JXSEGMENT , *PJXSEGMENT;

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
	PJXNODE pNodeRoot;
	FILE *  File;
	PUCHAR  FileName;
	XMLSTATE State;
	UCHAR   FileBuf[65535];
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
	PJXNODE pNodeWorkRoot;
	PJXNODE pNodeCurrent;
	PXMLATTR *pAttr;
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
} JXCOM , * PJXCOM;

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
	UCHAR 	braBeg;
	UCHAR 	braEnd;
	UCHAR 	curBeg;
	UCHAR 	curEnd;
	UCHAR 	backSlash;
	UCHAR 	quote;
	UCHAR   filler[256];
} JWRITE, * PJWRITE;

typedef _Packed struct  _JXITERATOR {
	PJXNODE   root;
	PJXNODE   this;
	LGL       isList;
	LGL       isFirst;
	LGL       isLast;
	LGL       isRecursive;
	VARCHAR1  comma;
	LONG      count;
	LONG      length;
	LONG      size;
	PJXNODE * list;
	LGL       doBreak;
	PJXNODE   next;
} JXITERATOR , * PJXITERATOR ;

typedef _Packed struct  _JXDELIM     {
	UCHAR     Slash       ;
	UCHAR     BackSlash   ;
	UCHAR     Masterspace ;
	UCHAR     BraBeg      ;
	UCHAR     BraEnd      ;
	UCHAR     Blank       ;
	UCHAR     Dot         ;
	UCHAR     CurBeg      ;
	UCHAR     CurEnd      ;
	UCHAR     Apos        ;
	UCHAR     Quot        ;
	UCHAR     Dollar      ;
} JXDELIM , * PJXDELIM;

#endif

// Prototypes  - utilities
LONG xlateMem  (iconv_t xid , PUCHAR out , PUCHAR in, LONG len);
void jx_WriteJsonStmf (PJXNODE pNode, PUCHAR FileName, int Ccsid, LGL trimOut, PJXNODE options);
VARCHAR jx_AsJsonText (PJXNODE pNode);
LONG jx_AsJsonTextMem (PJXNODE pNode, PUCHAR buf , ULONG maxLenP);
#pragma descriptor ( void jx_AsJsonTextMem                     (void))

LONG jx_fileWriter  (PSTREAM pStream , PUCHAR buf , ULONG len);
LONG jx_memWriter  (PSTREAM pStream, PUCHAR buf , ULONG len);
void  jx_AsJsonStream (PJXNODE pNode, PSTREAM pStream);
void  jsonStreamPrintNode (PJXNODE pNode, PSTREAM pStream, SHORT level);
void  jsonStreamPrintValue   (PJXNODE pNode, PSTREAM pStream);
void  jsonStreamPrintArray (PJXNODE pParent, PSTREAM pStream, SHORT level);
void  jsonStreamPrintObject  (PJXNODE pParent, PSTREAM pStream, SHORT level);
void  indent (PSTREAM pStream , int indent);
PUCHAR jx_EncodeJson (PUCHAR out , PUCHAR in);
void  jx_EncodeJsonStream (PSTREAM p , PUCHAR in);
PUCHAR c2s(UCHAR c);
PUCHAR strTrim(PUCHAR s);
UCHAR hex (UCHAR c)     ;
PUCHAR findchr (PUCHAR base , PUCHAR chars, SHORT charslen) ;
void xlatecpy( PJXCOM pJxCom ,PUCHAR out , PUCHAR in  , LONG len);
int cpy (PUCHAR out , PUCHAR in)                                  ;
void iconvWrite( FILE * f, iconv_t * pIconv, PUCHAR Value, BOOL Esc);
void iconvPutc( FILE * f, iconv_t * pIconv, UCHAR c);
void swapEndian(PUCHAR buf, LONG len)                                ;
LONG xlate(PJXCOM pJxCom, PUCHAR outbuf, PUCHAR inbuf , LONG len)    ;
int readBlock(PJXCOM pJxCom , PUCHAR buf, int size)                  ;
BOOL isTimeStamp(PUCHAR p)                                           ;
int formatTimeStamp(PUCHAR p , PUCHAR s)                             ;
UCHAR unicode2ebcdic (USHORT c)                                      ;
int parsehex(UCHAR c)                                                ;
BOOL isTerm(UCHAR c, PUCHAR term);

// Prototypes - segments
void  SegmentNodeDelete(PJXNODE pNode);
void SegmentNodeAdd (PJXNODE pNode)    ;
VOID jx_SegmentDispose(PJXSEGMENT pSeg) ;
PJXSEGMENT jx_SegmentSelectNo(SHORT  i)  ;


// Prototypes  - file reader
void initconst(int ccsid);
PUCHAR jx_GetChar(PJXCOM pJxCom);
UCHAR SkipBlanks (PJXCOM pJxCom);
void  jx_SkipChars(PJXCOM pJxCom , int skip);
void jx_CheckEnd(PJXCOM pJxCom) ;
int readBlock(PJXCOM pJxCom , PUCHAR buf, int size);

// Prototypes  - main
void jx_FreeChildren (PJXNODE pNode);
PUCHAR jx_GetChar(PJXCOM pJxCom);
void jx_SetMessage (PUCHAR Ctlstr , ... );
void jx_NodeFreeNodeOnly(PJXNODE pNode);

// Prototypes  - main  - exports
void jx_NodeAddChildHead( PJXNODE pRoot, PJXNODE pChild);
void jx_NodeAddChildTail( PJXNODE pRoot, PJXNODE pChild);
void jx_NodeAddSiblingBefore( PJXNODE pRef, PJXNODE pSibling);
void jx_NodeAddSiblingAfter( PJXNODE pRef, PJXNODE pSibling);

LGL jx_ParseStmfFile (PJXNODE  * ppRoot , PUCHAR FileName , PUCHAR Mode);
#pragma descriptor ( void jx_ParseStmfFile                     (void))

BOOL jx_ParseJson(PJXCOM pJxCom);
BOOL jx_ParseXml (PJXCOM pJxCom);
BOOL jx_ParseJsonNode(PJXCOM pJxCom, JSTATE state,  PUCHAR name , PJXNODE pCurNode );
PJXNODE jx_NodeClone  (PJXNODE pSource);
void jx_NodeMoveAndReplace (PJXNODE  pDest, PJXNODE pSource);
/* ------ */
void jx_SetDecPoint(PUCHAR p);
void jx_SetDelimiters(PJXDELIM pDelim);
void jx_SetDelimiters2(PJXDELIM pDelim);
void jx_CloneFormat(PJXNODE pNode, PJXNODE pSource);
LGL jx_Has  (PJXNODE pNode, PUCHAR Name);
#pragma descriptor ( void jx_Has                               (void))

LGL jx_IsTrue  (PJXNODE pNode, PUCHAR Name);
#pragma descriptor ( void jx_IsTrue                            (void))

LGL jx_IsNull  (PJXNODE pNode, PUCHAR Name);
#pragma descriptor ( void jx_IsNull                            (void))

JXITERATOR jx_SetIterator (PJXNODE pNode , PUCHAR path);
#pragma descriptor ( void jx_SetIterator                       (void))

JXITERATOR jx_SetRecursiveIterator (PJXNODE pNode , PUCHAR path);
#pragma descriptor ( void jx_SetRecursiveIterator              (void))

LGL jx_ForEach (PJXITERATOR pIter);
PJXNODE jx_GetParent(PJXNODE pNode);
SHORT jx_GetNodeType (PJXNODE pNode);

VARCHAR jx_GetNodeNameAsPath (PJXNODE pNode, UCHAR Delimiter);
#pragma descriptor ( void jx_GetNodeNameAsPath                 (void))

void jx_CopyValueByNameVC (PVARCHAR pRes, PJXNODE pNodeRoot, PUCHAR Name, PUCHAR Default , BOOL joinString);
#pragma descriptor ( void  jx_CopyValueByNameVC                (void))

void jx_WriteXmlStmf (PJXNODE pNode, PUCHAR FileName, int Ccsid, LGL trimOut , PJXNODE options);
#pragma descriptor ( void jx_WriteXmlStmf       (void))

void jx_WriteJsonStmf (PJXNODE pNode, PUCHAR FileName, int Ccsid, LGL trimOut, PJXNODE options);
#pragma descriptor ( void jx_WriteJsonStmf      (void))

void jx_WriteCsvStmf (PJXNODE pNode, PUCHAR FileName, int Ccsid, LGL trimOut, PJXNODE options);
#pragma descriptor ( void jx_WriteCsvStmf      (void))

PJXNODE  jx_ParseFile (PUCHAR FileName, PUCHAR Options);
#pragma descriptor ( void jx_ParseFile       (void))

PJXNODE  jx_ParseString  (PUCHAR Buf, PUCHAR Options);
#pragma descriptor ( void jx_ParseString     (void))

PJXNODE jx_parseStringCcsid(PUCHAR buf, int ccsid);
void    jx_setDelimitersByCcsid (int ccsid);


PJXNODE jx_NewObject (PJXNODE pDest);
#pragma descriptor ( void jx_NewObject (void))

PJXNODE jx_NewArray (PJXNODE pDest);
#pragma descriptor ( void jx_NewArray  (void))

PUCHAR   jx_GetValueByName (PJXNODE pNode, PUCHAR Name, PUCHAR Default);
#pragma descriptor ( void jx_GetValueByName (void))

PJXNODE  jx_SetValueByName (PJXNODE pNodeRoot, PUCHAR Name, PUCHAR Value, NODETYPE type);
#pragma descriptor ( void jx_SetValueByName (void))

VARCHAR  jx_AsXmlText (PJXNODE pNode);
PUCHAR   jx_NodeAsXmlTextList (PJXNODE pNode, PUCHAR temp);
BOOL     jx_Parse (PJXCOM pJxCom);
LGL      jx_Error (PJXNODE pJxNode);
VOID     jx_SetApiErr  (PJXNODE pJxNode , PAPIERR pApiErr );
PUCHAR   jx_ErrStr(PJXNODE pJxNode);
// VARCHAR1024 jx_Msg (PJXNODE pJxNode);
VARCHAR1024 jx_Message (PJXNODE pJxNode);
void     jx_Dump  (PJXNODE pJxNode);
void     jx_Free  (PJXNODE pJxNode);
PJXNODE  jx_GetNode  (PJXNODE pNode, PUCHAR Name) ;
#pragma descriptor ( void jx_GetNode                                              (void))

PJXNODE  jx_GetNodeChild (PJXNODE pNode);
PJXNODE  jx_GetNodeChildNo (PJXNODE pNode, int childNo);
PJXNODE  jx_GetNodeNext (PJXNODE pNode);
PJXNODE  jx_GetNodeParent  (PJXNODE pNode);
PXMLATTR jx_AttributeLookup   (PJXNODE pNode, PUCHAR Name);
PXMLATTR jx_NodeAddAttributeValue  (PJXNODE pNode , PUCHAR AttrName, PUCHAR Value);
PJXNODE  jx_GetNodeByName   (PJXNODE pNode, PUCHAR Ctlstr , ... );
PUCHAR   jx_GetNodeValuePtr (PJXNODE pNode, PUCHAR DefaultValue);
#pragma descriptor ( void jx_GetNodeValuePtr                                      (void))
VARCHAR  jx_GetNodeValueVC  (PJXNODE pNode , PUCHAR DefaultValue);
#pragma descriptor ( void jx_GetNodeValueVC                                       (void))
FIXEDDEC jx_GetNodeValueNum (PJXNODE pNode , FIXEDDEC DefaultValue);
#pragma descriptor ( void jx_GetNodeValueNum                                      (void))
PUCHAR   jx_GetNodeNamePtr  (PJXNODE pNode);
VARCHAR  jx_GetNodeNameVC   (PJXNODE pNode);

PJXNODE  jx_NodeAdd (PJXNODE pDest, REFLOC refloc, PUCHAR Name , PUCHAR Value, NODETYPE type) ;
void     jx_NodeSet (PJXNODE pNode , PUCHAR Value);
void     jx_NodeDelete(PJXNODE pRoot);
void     jx_NodeReplace (PJXNODE  pDest, PJXNODE pSource);
PJXNODE  jx_NodeCopy (PJXNODE pDest, PJXNODE pSource, REFLOC refloc);
void     jx_NodeMerge(PJXNODE pDest, PJXNODE pSource, SHORT replace);
PJXNODE  jx_GetOrCreateNode (PJXNODE pNodeRoot, PUCHAR Name);

// Attribute navigation:
PXMLATTR jx_GetAttrFirst     (PJXNODE pNode);
PXMLATTR jx_GetAttrNext      (PXMLATTR pAttr);
PUCHAR   jx_GetAttrNamePtr   (PXMLATTR pAttr);
VARCHAR  jx_GetAttrNameVC    (PXMLATTR pAttr);
PUCHAR   jx_GetAttrValuePtr  (PXMLATTR pAttr);
VARCHAR  jx_GetAttrValueVC   (PXMLATTR pAttr, PUCHAR DefaultValue);
#pragma descriptor ( void jx_GetAttrValueVC                                       (void))
FIXEDDEC jx_GetAttrValueNum  (PXMLATTR pAttr, FIXEDDEC dftParm);
#pragma descriptor ( void jx_GetAttrValueNum                                      (void))

// Get Node Attribute value variants:
PUCHAR   jx_GetNodeAttrValuePtr  (PJXNODE pNode, PUCHAR AttrName, PUCHAR DefaultValue);
#pragma descriptor ( void jx_GetNodeAttrValuePtr                                  (void))
VARCHAR  jx_GetNodeAttrValueVC   (PJXNODE pNode ,PUCHAR AttrName, PUCHAR DefaultValue);
#pragma descriptor ( void jx_GetNodeAttrValueVC                                   (void))
FIXEDDEC jx_GetNodeAttrValueNum  (PJXNODE pNode , PUCHAR AttrName, FIXEDDEC DefaultValue);
#pragma descriptor ( void jx_GetNodeAttrValueNum                                  (void))

VOID     jx_SetNodeAttrValue     (PJXNODE pNode , PUCHAR AttrName, PUCHAR Value);
void     jx_SetCcsid(int pInputCcsid, int pOutputCcsid);

// Get value variants:
PUCHAR  jx_GetValuePtr (PJXNODE pNodeRoot, PUCHAR Name, PUCHAR Default) ;
#pragma descriptor ( void jx_GetValuePtr    (void))

VARCHAR jx_GetValueVC (PJXNODE pNodeRoot, PUCHAR NameP, PUCHAR DefaultP);
#pragma descriptor ( void jx_GetValueVC     (void))

FIXEDDEC jx_GetValueNum (PJXNODE pNode , PUCHAR Name  , FIXEDDEC dftParm);
#pragma descriptor ( void jx_GetValueNum    (void))


void jx_Close(PJXNODE * pNode);

void    jx_AsJsonTextList (PJXNODE pNode, PJWRITE pJwrite);
LONG    jx_AsJsonTextMem (PJXNODE pNode, PUCHAR buf, ULONG maxSize);
VARCHAR jx_AsJsonText(PJXNODE pNode);
LGL     jx_IsJson (PJXNODE pNode);
BOOL    jx_HasMore(PJXNODE pNode);

/* Internals */
void     jx_SkipBlanks(BOOL skip);
BOOL    JSON_Parse(PJXCOM pJxCom);
BOOL    jsonParseNode(PJXCOM pJxCom, JSTATE state,  PUCHAR name , PJXNODE pCurNode) ;
void    AddNode(PJXNODE pDest, PJXNODE pSource, REFLOC refloc);
PJXNODE DupNode(PJXNODE pSource);
PJXNODE NewNode (PUCHAR Name , PUCHAR Value, NODETYPE type);
PJXNODE CloneNode  (PJXNODE pSource);
PJXNODE NewRoot(void);

void SegmentNodeAdd   (PJXNODE pNode);
void SegmentNodeDelete(PJXNODE pNode);

PJXSEGMENT jx_SegmentSelectNo(SHORT i);
VOID jx_SegmentDisplose(PJXSEGMENT pSeg);

PJXDELIM jx_GetDelimiters(void);

PJXNODE  jx_ArrayPush (PJXNODE pDest, PJXNODE pSource , BOOL16 copy);
#pragma descriptor ( void jx_ArrayPush      (void))

PJXNODE  jx_LookupValue (PJXNODE pDest, PUCHAR expr , BOOL16 ignorecase);
#pragma descriptor ( void jx_LookupValue    (void))

LONG     jx_getLength (PJXNODE pNode);
ULONG     jx_NodeCheckSum (PJXNODE pNode);

PJXNODE  jx_SetStrByName (PJXNODE pNode, PUCHAR Name, PUCHAR Value);
PJXNODE  jx_SetBoolByName (PJXNODE pNode, PUCHAR Name, LGL Value);
PJXNODE  jx_SetDecByName (PJXNODE pNode, PUCHAR Name, FIXEDDEC Value);
PJXNODE  jx_SetIntByName (PJXNODE pNode, PUCHAR Name, LONG Value);
PJXNODE  jx_NodeMoveInto (PJXNODE  pDest, PUCHAR Name , PJXNODE pSource);
void jx_NodeCloneAndReplace (PJXNODE pDest , PJXNODE pSource);
void jx_Debug(PUCHAR text, PJXNODE pNode);

// SQL functions
#ifndef JXSQLSTMT_MAX
#define JXSQLSTMT_MAX  32
#endif

typedef _Packed struct  {
	 SQLHSTMT      hstmt;
	 BOOL          allocated;
	 BOOL          exec;
} JXSQLSTMT, * PJXSQLSTMT;

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
} JXCOL, * PJXCOL;


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
}  JXTRACE  , * PJXTRACE;

#define  COMMENT_SIZE 4096
#define  DATA_SIZE 65535
#define  INVALIDCHAR 0x3f
#define  LOOK_AHEAD_SIZE (65535-512)
typedef _Packed struct  {
// SQLHENV       henv;
// SQLHDBC       hdbc;
// SQLHSTMT      hstmt;
	 PJXSQLSTMT    pstmt;
	 PUCHAR        sqlstmt;
	 SQLSMALLINT   nresultcols;
	 SQLINTEGER    rowcount;
	 SQLRETURN     rc;
// PJXNODE       pRowNode;
// SQLOPTIONS    options;
// PJXNODE       pOptions;
// BOOL          deleteOptions;
	 PJXCOL        cols;
} JXSQL, * PJXSQL;

typedef _Packed struct  {
	 SQLHENV       henv;
	 SQLHDBC       hdbc;
	 PJXNODE       pOptions;
	 BOOL          pOptionsCleanup;
	 SQLOPTIONS    options;
	 PXLATEDESC    pCd;
	 UCHAR         sqlState[5];
	 LONG          sqlCode;
	 UCHAR         sqlMsgDta[SQL_MAX_MESSAGE_LENGTH + 1];
	 JXSQLSTMT     stmts[JXSQLSTMT_MAX];
	 SHORT         stmtIx;
	 JXTRACE       sqlTrace;
} JXSQLCONNECT , * PJXSQLCONNECT;

typedef enum _JX_RESULTSET {
	 JX_META       = 1,
	 JX_FIELDS     = 2,
	 JX_TOTALROWS  = 4,
	 JX_UPPERCASE  = 8,
	 JX_APROXIMATE_TOTALROWS = 16
} JX_RESULTSET, *PJX_RESULTSET;

VOID TRACE ( UCHAR lib[11] , PLGL doTrace , UCHAR job [32]);

PJXNODE jx_sqlResultRow ( PUCHAR sqlstmt, PJXNODE pSqlParmsP ) ;
#pragma descriptor ( void jx_sqlResultRow   (void))

PJXNODE jx_sqlResultRowAt ( PUCHAR sqlstmt, LONG startAt , PJXNODE pSqlParmsP ) ;
#pragma descriptor ( void jx_sqlResultRowAt   (void))

PJXNODE jx_sqlResultSet( PUCHAR sqlstmt, LONG startP, LONG limitP, LONG formatP , PJXNODE pSqlParmsP );
#pragma descriptor ( void jx_sqlResultSet   (void))

PJXSQL jx_sqlOpen(PUCHAR sqlstmt , PJXNODE pSqlParms, BOOL scroll);
#pragma descriptor ( void jx_sqlOpen        (void))

LGL jx_sqlUpdate (PUCHAR table  , PJXNODE pRow , PUCHAR whereP, PJXNODE pSqlParmsP  );
#pragma descriptor ( void jx_sqlUpdate      (void))

LGL jx_sqlInsert (PUCHAR table  , PJXNODE pRow , PUCHAR whereP, PJXNODE pSqlParmsP  );
#pragma descriptor ( void jx_sqlInsert      (void))

LGL jx_sqlUpsert (PUCHAR table  , PJXNODE pRow , PUCHAR whereP, PJXNODE pSqlParmsP  );
#pragma descriptor ( void jx_sqlUpsert      (void))

LONG jx_sqlNumberOfRows(PUCHAR sqlstmt);
PJXNODE jx_sqlFetchRelative (PJXSQL pSQL, LONG fromRow);
PJXNODE jx_sqlFetchNext (PJXSQL pSQL);

void jx_sqlClose (PJXSQL * ppSQL);
void jx_sqlKeepConnection (BOOL keep);
PJXNODE jx_sqlGetMeta (PUCHAR sqlstmt);


LGL    jx_sqlExec (PUCHAR sqlstmt , PJXNODE pSqlParms  );
#pragma descriptor ( void jx_sqlExec        (void))

PJXSQLCONNECT  jx_sqlConnect(PJXNODE pSqlParms  );
#pragma descriptor ( void jx_sqlConnect    (void))

void jx_SwapNodes (PJXNODE * pNode1, PJXNODE *  pNode2);

PJXNODE jx_ArraySort(PJXNODE pNode, PUCHAR fieldsP, USHORT options);
#pragma descriptor ( void jx_ArraySort     (void))

void jx_deleteWriter (PJWRITE  pjWrite);
PJWRITE jx_newWriter (void);




#endif