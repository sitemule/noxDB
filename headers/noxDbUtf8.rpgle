**FREE
// ---------------------------------------------------------------------- *
// This is the prototype for noxDB - JSON, XML and SQL made easy
// Use the NOXDB binddir when creating your program and include this
// prototypes like:

//     Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE');
//     /include QRPGLEREF,NOXDBUTF8.rpgle'


// ---------------------------------------------------------------------- *
/if defined( NOX_DEF)
/eof
/endif
/define  NOX_DEF

// 1M minus length of 4 bytes
Dcl-S UTF8     varchar(1048572:4)  CCSID(*UTF8) Template;
Dcl-S UTF8_MAX varchar(16773100:4) CCSID(*UTF8) Template;
Dcl-S UTF8_1M  varchar(1048572:4)  CCSID(*UTF8) Template;
Dcl-S UTF8_1K  varchar(1024:4)     CCSID(*UTF8) Template;
Dcl-C UTF8_BOM const(-1208);
Dcl-S FIXEDDEC Packed(30:15) Template;


///
// Type of a node:
///
Dcl-C NOX_TYPE_UNKNOWN const(0);
Dcl-C NOX_TYPE_OBJECT  const(1);
Dcl-C NOX_TYPE_ARRAY   const(2);
Dcl-C NOX_TYPE_EVAL    const(3);
Dcl-C NOX_TYPE_POINTER_VALUE const(4);
Dcl-C NOX_TYPE_VALUE   const(5);
Dcl-C NOX_TYPE_ROOT    const(6);
Dcl-C NOX_TYPE_LITERAL const(16);
Dcl-C NOX_TYPE_OBJLINK const(17);
Dcl-C NOX_TYPE_OBJREPLACE const(18);
Dcl-C NOX_TYPE_OBJCOPY const(18);
Dcl-C NOX_TYPE_BY_CONTEXT const(19);
Dcl-C NOX_TYPE_OBJMOVE const(2048);

// Node reference location for nodeCopy / NodeInsert etc.
///
// Reference location : first child
///
Dcl-C NOX_FIRST_CHILD const(1);
///
// Reference location : last child
///
Dcl-C NOX_LAST_CHILD const(2);
///
// Reference location : before sibling
///
Dcl-C NOX_BEFORE_SIBLING const(3);
///
// Reference location : after sibling
///
Dcl-C NOX_AFTER_SIBLING const(4);


// * Modifiers to "add" / "or" into "parseString" and "evaluate"
// !! Type - have to be backwards compat.
// Unlink the source and move it to dest.
Dcl-C NOX_MOVE_NODES const(2048);
// Allow strings ints and other values to
Dcl-C NOX_ALLOW_PRIMITIVES const(4096);

// * Combinations:
// NOX_PARSE  = NOX_EVAL + NOX_MOVE_NODES
Dcl-C NOX_PARSE   const(2051);

// Merge options:
// Modifiers to "add" / "or" into "JSON_EVAL"
/if not defined(MO_MERGE)
/define  MO_MERGE
// Only new elements are merged - existing
// are left untouched
Dcl-C MO_MERGE_NEW const(256);
// Merge and replace only existing nodes.
Dcl-C MO_MERGE_MATCH const(512);
// Merge all: replace if it exists and
// append new nodes if not exists
Dcl-C MO_MERGE_REPLACE const(1024 );
/endif

Dcl-C NOX_CHILD_LIST const('[0]');

///
// Node Option Format : XML Serializer Default Format
///
Dcl-C NOX_FORMAT_DEFAULT const(0);
///
// Node Option Format : XML Serializer CDATA Format
///
Dcl-C NOX_FORMAT_CDATA const(1);


///
// Parse file
//
// Parses a JSON or XML stream file. The encodings ASCII, UTF8, 1252 and
// EBCDIC of the current job are supported.
//
// @param (input) Path to the XML or JSON file (null-terminated)
// @param (input) Options are no longer supported (deprecated)
// @return Pointer to the root node of the noxDB object graph or
//         <code>*null</code> if the file is not readable.
///
Dcl-PR nox_ParseFile Pointer extproc(*CWIDEN:'nox_ParseFile');
  // File to parse
  FileName       pointer value  options(*string);
End-PR;

///
// Parse string
//
// Parses a JSON or XML string.
//
// @param (input) JSON or XML string
// @param (input) Options are no longer supported (deprecated)
// @return Pointer to the root node of the noxDB object graph
///
Dcl-PR nox_ParseString Pointer extproc(*CWIDEN:'nox_ParseStringVC');
  // String to parse
  String         Like(UTF8_MAX) const options(*varsize);
End-PR;

///
// Set decimal separator
//
// Set , or . for decimal separator.
//
// @param (input) Decimal separator character
///
Dcl-PR nox_setDecPoint  extproc(*CWIDEN : 'nox_SetDecPoint');
  // decimal point char
  decPoint       char(1) const ccsid(*utf8);
End-PR;

///
// Check error
//
// Checks if the last operation resulted in an error.
//
// @param (input) Node
// @return *on if the last operation resulted in an error else *off
///
Dcl-PR nox_Error Ind extproc(*CWIDEN:'nox_Error');
  // nox_Object  node
  pNode          Pointer    value;
End-PR;

///
// Get error description
//
// Returns the error description for the last error.
//
// @param (input) Node (omit for last error message)
// @return Error description or <code>*blank</code> if no error occured
///
Dcl-PR nox_Message varchar(1024) extproc(*CWIDEN:'nox_MessageVC');
  // nox_Object
  pNode          Pointer    value;
End-PR;

///
// Get error object
//
// Returns a new noxDB object graph with the boolean attribute "success" = false.
// If no parameters are passed the object will contain the attribute "msg" with
// the last error message. Otherwise the object will contain the attribute "msgId"
// with the passed message id and "msgDta" with the passed message data.
//
// @param (input) Message id
// @param (input) Message data
// @return New noxDB object graph with error message
//
// @info The caller of this procedure needs to take care of freeing the resources
//       of the returned noxDB object graph by calling <em>nox_close(rootNode)</em>.
///
Dcl-PR nox_GetMessageObject Pointer // Return error description
                            extproc(*CWIDEN:'nox_GetMessageObject');
  MessageId      Like(UTF8) const options(*nopass:*varsize);
  MessageData    Like(UTF8) const options(*nopass:*varsize);
End-PR;

///
// Get success object
//
// Convenience function which returns a {"success":true} object.
//
// @param (input) Message id
// @param (input) Message data
// @return New noxDB object graph with success attribute
//
// @info The caller of this procedure needs to take care of freeing the resources
//       of the returned noxDB object graph by calling <em>nox_close(rootNode)</em>.
///
Dcl-PR nox_SuccessTrue Pointer extproc(*CWIDEN:'nox_SuccessTrue');
  MessageId      Like(UTF8) const options(*nopass:*varsize);
  MessageData    Like(UTF8) const options(*nopass:*varsize);
End-PR;

///
// Locate node
//
// Returns the node at the passed expression.
//
// @param (input) Node
// @param (input) Node path expression
// @return Located node or <code>*null</code> of no node is located at the
//         passed expression
///
Dcl-PR nox_Locate Pointer extproc(*CWIDEN : 'nox_GetNodeVC');
  pNode          Pointer    value;
  Expression     Like(UTF8_1K) const options(*varsize);
End-PR;

///
// Locate or create node
//
// Returns the node at the passed expression. If no node is located at the
// passed expression a new node will be created at the passed path expression
// and returned.
//
// @param (input) Node
// @param (input) Node path expression
// @return Node at the passed path expression (either the existing one or a new one)
///
Dcl-PR nox_LocateOrCreate Pointer extproc(*CWIDEN : 'nox_GetOrCreateNodeVC');
  pNode          Pointer    value;
  Expression     Like(UTF8_1K) const options(*varsize);
End-PR;

///
// Has node
//
// Returns <code>*on</code> if node exists.
//
// @param (input) Node
// @param (input) Node path expression
// @return <code>*on</code> if node exists else <code>*off</code>
///
Dcl-PR nox_Has Ind extproc(*CWIDEN : 'nox_HasVC');
  // Pointer to graph or node
  pNode          Pointer    value;
  // Path to node
  NodeName       Like(UTF8_1K) const options(*varsize);
End-PR;

///
// Is node value true
//
// Returns <code>*on</code> if node exists and has non-falsy value.
// "falsy" values would be
//
// <ul>
//   <li>null</li>
//   <li>0</li>
//   <li>false</li>
//   <li>node does not exist</li>
// </ul>
//
// @param (input) Node
// @param (input) Node path expression
// @return <code>*on</code> if node value is not "falsy" else <code>*off</code>
///
Dcl-PR nox_isTrue Ind extproc(*CWIDEN : 'nox_IsTrueVC');
  // Pointer to graph or node
  pNode          Pointer    value;
  // Path to node
  NodeName       Like(UTF8_1K) const options(*varsize);
End-PR;

///
// Is null
//
// Returns <code>*on</code> if the node does not exist or its value is
// <code>*null</code>.
//
// @param (input) Node
// @param (input) Node path expression
// @return <code>*on</code> if node does not exist or has
//         <code>*null</code> value
///
Dcl-PR nox_isNull Ind extproc(*CWIDEN : 'nox_IsNullVC');
  pNode          Pointer    value;
  NodeName       Like(UTF8_1K) const options(*varsize);
End-PR;

///
// Is node
//
// Returns <code>*on</code> if the passed pointer is a valid node.
// a.k.a. false for strings
//
// @param (input) Node
// @return <code>*on</code> if pointer is valid node else <code>*off</code>
///
Dcl-PR nox_isNode Ind extproc(*CWIDEN : 'nox_isNode');
  pNode          Pointer    value;
End-PR;

///
// Rename node
//
// Renames the passed node.
//
// @param (input) Node
// @param (input) New node name
///
Dcl-PR nox_NodeRename Ind extproc(*CWIDEN : 'nox_NodeRenameVC');
  pNode          Pointer    value;
  NodeName       Like(UTF8_1K) const options(*varsize);
End-PR;

///
// Get sibling node
//
// Returns the next sibling relative to the passed node. For objects that would
// be the next attribute on the same level. For arrays that would be the next
// element.
//
// @param (input) Node
// @return Sibling node or <code>*null</code> if there is sibling
///
Dcl-PR nox_GetNext Pointer extproc(*CWIDEN : 'nox_GetNodeNext');
  pNode          Pointer    value;
End-PR;

///
// Get child node
//
// Returns the first child node of the passed node.
//
// @param (input) Node
// @return First child node or <code>*null</code> if there is no child node
///
Dcl-PR nox_GetChild Pointer extproc(*CWIDEN : 'nox_GetNodeChild');
  pNode          Pointer    value;
End-PR;

///
// Get parent node
//
// Returns the parent node.
//
// @param (input) Node
// @return Parent node or <code>*null</code> if the passed node
//         is the root node
///
Dcl-PR nox_GetParent Pointer extproc(*CWIDEN : 'nox_GetNodeParent');
  pNode          Pointer    value;
End-PR;


// Set node with null value
//
// Creates a node at the passed path with the value <code>*null</code>.
// Any existing node will be replaced by this new node.
//
// @param Node
// @param Node path expression
// @return New node
///
Dcl-PR nox_SetNull pointer extproc(*CWIDEN : 'nox_SetNullByNameVC');
  node pointer value;
  Expresion      Like(UTF8_1K) const options(*varsize);
End-PR;

///
// Set expression as node value
//
// Sets the parsed value to the node pointed to by the passed path expression. The value will
// be parsed to a new object graph and added to the node. If the node already contains a node
// at the specified path the attributes of the nodes will be merged.
//
// @param (input) Node
// @param (input) Node path expression
// @param (input) New string value
// @return Changed node
///
Dcl-PR nox_SetEval pointer extproc(*CWIDEN:'nox_SetEvalByNameVC');
  pNode          Pointer    value;
  Expresion      Like(UTF8_1K) const options(*varsize);
  Value          Like(UTF8) const options(*varsize);
End-PR;

///
// Set string value
//
// Sets the passed value to the node pointed to by the passed path expression.
//
// @param (input) Node
// @param (input) Node path expression
// @param (input) New string value
// @param (input) If this is *ON the value will be set to null regardless of the values
// @return Changed node
///
Dcl-PR nox_SetStr Pointer extproc(*CWIDEN: 'nox_SetStrByNameVC');
  pNode          Pointer    value;
  Expresion      Like(UTF8_1K) const options(*varsize);
  Value          Like(UTF8) const options(*varsize);
  nullIf         ind value options(*nopass);
End-PR;

/// TODO - not migrated !!
// create an atomic string node
//
// @param (input) New string value
// @return new node
///
Dcl-PR nox_Str Pointer extproc(*CWIDEN: 'nox_StrVC');
  Value          Like(UTF8) const options(*varsize);
End-PR;

///
// Set integer value
//
// Sets the passed value to the node pointed to by the passed path expression.
//
// @param (input) Node
// @param (input) Node path expression
// @param (input) New value
// @param (input) If this is *ON the value will be set to null regardless of the values
// @return Changed node
///
Dcl-PR nox_SetInt Pointer extproc(*CWIDEN: 'nox_SetIntByNameVC');
  pNode          Pointer    value;
  Expresion      Like(UTF8_1K) const options(*varsize);
  Value          Int(20)    value;
  nullIf         ind value options(*nopass);
End-PR;

/// TODO - not migrated !!
// Create an atomic integer node
//
// @param (input) value
// @return pointer to the new node
///
Dcl-PR nox_Int Pointer extproc(*CWIDEN: 'nox_Int');
  Value          Int(20)    value;
End-PR;


///
// Set decimal value
//
// Sets the passed value to the node pointed to by the passed path expression.
//
// @param (input) Node
// @param (input) Node path expression
// @param (input) New value
// @param (input) If this is *ON the value will be set to null regardless of the values
// @return Changed node
///
Dcl-PR nox_SetDec Pointer extproc(*CWIDEN: 'nox_SetDecByNameVC');
  pNode           Pointer    value;
  Expresion       Like(UTF8_1K) const options(*varsize);
  Value           like(FIXEDDEC) value;
  nullIf          ind value options(*nopass);
End-PR;

/// TODO - not migrated !!
// create an atomic deciaml number node
//
//
// @param (input) New value
// @param (input) If this is *ON the value will be set to null regardless of the values
// @return Changed node
///
Dcl-PR nox_Dec   Pointer OPDESC extproc(*CWIDEN: 'nox_Dec');
  Value          like(FIXEDDEC) value;
End-PR;

///
// Set boolean value
//
// Sets the passed value to the node pointed to by the passed path expression.
//
// @param (input) Node
// @param (input) Node path expression
// @param (input) New value
// @param (input) If this is *ON the value will be set to null regardless of the values
// @return Changed node
///
Dcl-PR nox_SetBool Pointer extproc(*CWIDEN: 'nox_SetBoolByNameVC');
  pNode          Pointer    value;
  Expresion      Like(UTF8_1K) const options(*varsize);
  Value          Ind        value;
  nullIf         ind value options(*nopass);
End-PR;

/// TODO - not migrated !!
// create an atomic boolean value
//
// Sets the passed value to the node pointed to by the passed path expression.
//
// @param (input) Value
// @return new node
///
Dcl-PR nox_Bool Pointer extproc(*CWIDEN: 'nox_Bool');
  Value          Ind        value;
End-PR;

///
// Set date value
//
// Set the passed value to the node pointed to by the passed path expression.
//
// @param (input) Node
// @param (input) Node path expression
// @param (input) New value
// @param (input) If this is *ON the value will be set to null regardless of the values
// @return Changed node
///
Dcl-PR nox_SetDate Pointer extproc(*CWIDEN: 'nox_SetDateByNameVC');
  pNode          Pointer    value;
  Expresion      Like(UTF8_1K) const options(*varsize);
  Value          date(*ISO)    value  ;
  nullIf         ind value options(*nopass);
End-PR;

/// TODO - not migrated !!
// create an atomic  date value
//
//
// @param (input) Value
// @return new  node
///
Dcl-PR nox_Date Pointer extproc(*CWIDEN: 'nox_Date');
  Value          date(*ISO)    value;
End-PR;

///
// Set time value
//
// Set the passed value to the node pointed to by the passed path expression.
//
// @param (input) Node
// @param (input) Node path expression
// @param (input) New value
// @param (input) If this is *ON the value will be set to null regardless of the values
// @return Changed node
///
Dcl-PR nox_SetTime pointer extproc(*CWIDEN : 'nox_SetTimeByNameVC');
  pNode          pointer value;
  Expresion      Like(UTF8_1K) const options(*varsize);
  Value          time(*ISO) value;
  nullIf         ind value options(*nopass);
End-PR;

/// TODO - not migrated !!
// create an atomic time value
//
// @param (input) Value
// @return new  node
///
Dcl-PR nox_Time pointer extproc(*CWIDEN : 'nox_Time');
  Value          time(*ISO) value;
End-PR;

///
// Set timestamp value
//
// Set the passed value to the node pointed to by the passed path expression.
//
// @param (input) Node
// @param (input) Node path expression
// @param (input) New value
// @param (input) If this is *ON the value will be set to null regardless of the values
// @return Changed node
///
Dcl-PR nox_SetTS  pointer extproc(*CWIDEN : 'nox_SetTimeStampByNameVC');
  pNode          pointer value;
  Expresion      Like(UTF8_1K) const options(*varsize);
  Value          timestamp  value;
  nullIf         ind value options(*nopass);
End-PR;

/// TODO - not migrated !!
// create an atomic timestamp value
//
// @param (input) Value
// @return New  node
///
Dcl-PR nox_TS  pointer extproc(*CWIDEN : 'nox_TimeStamp');
  Value          timestamp  value;
End-PR;

///
// Set value by pointer
//
// Set the passed value as is to the node pointed to by the passed path
// expression.
//
// @param (input) Node
// @param (input) Node path expression
// @param (input) Value
// @param (input) <code>*on</code> = pointer points to a string and stringifies the
//        value (add double quotes),
//        <code>*off</code> = contents is already formatted JSON (default)
//        and will be added as is
// @return Changed node
//
// @info The resources of the passed value are not managed by noxDB and must
//       be freed by the caller.
///
Dcl-PR nox_SetPtr Pointer extproc(*CWIDEN: 'nox_SetPtrByNameVC');
  pNode          Pointer    value;
  Expresion      Like(UTF8_1K) const options(*varsize);
  Value          Pointer    value;
  isString       Ind        value options(*nopass);
End-PR;

///
// Set procedure pointer as value
//
// Sets the passed value to the node pointed to by the passed path expression.
//
// @param (input) Node
// @param (input) Node path expression
// @param (input) Procedure pointer
// @param (input) Is string (deprecated)
// @return Changed node
//
// @info Procedure pointers are not intended to be serialized.
///
Dcl-PR nox_SetProcPtr Pointer extproc(*CWIDEN: 'nox_SetPtrByNameVC');
  pNode          Pointer    value;
  Expresion      Like(UTF8_1K) const options(*varsize);
  Proc           Pointer(*Proc);
End-PR;


///
// Data-Into Parser /// TODO - migrated !!
//
// This implemenation of a <em>data-into</em> parser takes a noxDB object graph
// and maps it to a data structure.
//
// @param (input) Node to be mapped to a data structure
// @return Procedure pointer of the data-into parser
///
Dcl-PR nox_DataInto pointer(*proc) extproc(*CWIDEN : 'nox_DataInto');
  pNode pointer value;
End-PR;

///
// Data-Gen Generator /// TODO - migrated !!
//
// This implementation of a <em>data-gen</em> generator takes a data structure
// and maps it to a noxDB object graph. The noxDB object graph will be created by
// this function an does not need to exist.
//
// @param (output) noxDB object graph (output parameter) Note: This is passed by reference pointer to noxDB graph
// @param (input) options, check IBM documentation for data-gen for possible options
// @return Procedure pointer of the data-gen generator function
//
// @info The noxDB object graph returned by this procedure through the output
//       parameter needs to be freed by calling <em>nox_delete(node)</em> by the
//       user of this function.
///
Dcl-PR nox_DataGen pointer(*proc) extproc(*CWIDEN : 'nox_DataGen');
  pNode    pointer;
  Options  pointer value options(*string : *nopass);
End-PR;



///
// Get string value
//
// Returns the value of the passed node.
//
// @param (input) Node
// @param (input) Default value
// @return String value or the default value (or an empty string) if the node
//         does not exist
///
Dcl-PR nox_GetValueStr Like(UTF8) rtnparm extproc(*CWIDEN : 'nox_GetNodeValueStrVC');
  pNode          Pointer    value;
  Defaultvalue   Like(UTF8) const options(*nopass:*varsize);
End-PR;

///
// Get decimal value
//
// Returns the value of the passed node.
//
// @param (input) Node
// @param (input) Default value
// @return Decimal value or the default value (or 0) if the node does not exist
///
Dcl-PR nox_GetValueNum like(FIXEDDEC) extproc(*CWIDEN : 'nox_GetNodeValueDec');
  pNode          Pointer    value;
  Defaultvalue   like(FIXEDDEC) value options(*NOPASS);
End-PR;

///
// Get integer value
//
// Returns the value of the passed node.
//
// @param (input) Node
// @param (input) Default value
// @return Integer value or the default value (or 0) if the node does not exist
///
Dcl-PR nox_GetValueInt Int(20) extproc(*CWIDEN : 'nox_GetNodeValueInt');
  pNode          Pointer    value; // Pointer to node
  Defaultvalue   Int(20)    value options(*NOPASS);
End-PR;

///
// Get pointer value
//
// Returns the value of the passed node.
//
// @param (input) Node
// @param (input) Default value
// @return Pointer value or the default value (or *null) if the node does not
//         exist
///
Dcl-PR nox_GetValuePtr Pointer extproc(*CWIDEN : 'nox_GetNodeValuePtr');
  pNode          Pointer    value;
  Defaultvalue   Like(UTF8) const options(*nopass:*varsize);
End-PR;

///
// Get node name
//
// Returns the name of the node.
//
// @param (input) Node
// @return Node name
///
Dcl-PR nox_GetName Like(UTF8)  rtnparm  extproc(*CWIDEN : 'nox_GetNodeNameVC');
  pNode          Pointer    value;
End-PR;

///
// Get path expression of node
//
// Returns the node path expression for the passed node, f. e. /item/price .
//
// @param (input) Node
// @param (input) Node path element delimiter (for example . or /)
// @return Node path expression
///
Dcl-PR nox_GetNameAsPath Like(UTF8) rtnparm  extproc(*CWIDEN : 'nox_GetNodeNameAsPath');
  pNode          Pointer    value;
  Delimiter      Char(1)    value CCSID(*UTF8);
End-PR;

///
// Get node type
//
// Returns the node type of the passed node.
// * Refer to node type above
//
// @param (input) Node
// @return Node type constant
///
Dcl-PR nox_NodeType Int(5) extproc(*CWIDEN : 'nox_GetNodeType');
  pNode          Pointer    value;
End-PR;



/// TODO - migrated !!
// Set node options
//
// Sets the node format options which will among other things affect how the
// node will be output by the serializers.
//
// @param (input) Node
// @param (input) Format option (NOX_FORMAT_DEFAULT, NOX_FORMAT_CDATA)
// @return Passed node (first parameter)
///
Dcl-PR nox_SetNodeOptions pointer extproc(*CWIDEN : 'nox_SetNodeOptions');
  node pointer value;
  format int(5) value;
End-PR;

///
// Get string value by expression
//
// Returns the string value of the node pointed to by the passed expression.
//
// expresion examples:
//  /object/array[123]/name
//  .object.array[123].name
//
// @param (input) Node
// @param (input) Node path expression (default: current node)
// @param (input) Default value
// @return String value or the default value if the node does not exist
///
Dcl-PR nox_GetStr Like(UTF8) rtnparm extproc(*CWIDEN : 'nox_GetValueStrVC');
  pNode          Pointer    value;
  Expression     Like(UTF8_1K) const options(*nopass:*varsize);
  Defaultvalue   Like(UTF8) const options(*nopass:*varsize);
End-PR;

///
// Join array nodes to string
//
// Joins the values of all <em>array</em> nodes to a string.
// <br><br>
// [12.345, "-", 6, 7, true, { "id" : 358 }] will result in the string
// 12.345-67true . Any object nodes will be ignored.
//  will join all subsequent array nodes into one resulting string
//
// @param (input) Node
// @param (input) Node path expression to the array node (default: current node)
// @param (input) Default value
// @param (input) Delimiter variable length string
// @return String with all values from the array nodes
///
Dcl-PR nox_GetStrJoin Like(UTF8) extproc(*CWIDEN : 'nox_GetStrJoinVC');
  pNode          Pointer    value;
  Expression     Like(UTF8_1K) const options(*nopass:*varsize);
  Defaultvalue   Like(UTF8) const options(*nopass:*varsize);
End-PR;

///
// Get decimal value by expression
//
// Returns the decimal value of the node pointed to by the passed expression.
// Get number by expresion like:
//  /object/array[123]/name
//  .object.array[123].name
//
// @param (input) Node
// @param (input) Node path expression (default: current node)
// @param (input) Default value
// @return Decimal value or the default value if the node does not exist
///
Dcl-PR nox_GetDec like(FIXEDDEC) extproc(*CWIDEN : 'nox_GetValueDecVC');
  pNode          Pointer    value;
  Expression     Like(UTF8_1K) const  options(*nopass:*varsize);
  Defaultvalue   like(FIXEDDEC) value options(*nopass);
End-PR;

///
// Get integer value by expression
//
// Returns the integer value of the node pointed to by the passed expression.
//
// @param (input) Node
// @param (input) Node path expression (default: current node)
// @param (input) Default value
// @return Integer value or the default value if the node does not exist
///
Dcl-PR nox_GetInt Int(20) extproc(*CWIDEN : 'nox_GetValueIntVC');
  pNode          Pointer    value;
  Expression     Like(UTF8_1K) const options(*nopass:*varsize);
  Defaultvalue   Int(20)    value options(*nopass);
End-PR;


///
// get the boolean state for a node. alias for: isTrue
//
// Returns <code>*on</code> if node exists and has non-falsy value.
// "falsy" values would be
//
// <ul>
//   <li>null</li>
//   <li>0</li>
//   <li>false</li>
//   <li>node does not exist</li>
// </ul>
//
// @param (input) Node
// @param (input) Node path expression
// @return <code>*on</code> if node value is not "falsy" else <code>*off</code>
///
Dcl-PR nox_getBool  Ind extproc(*CWIDEN : 'nox_IsTrueVC');
  pNode          Pointer    value;
  NodeName       Like(UTF8) const options(*varsize);
End-PR;


///
// Get date value by expression
//
// Returns the date value of the node pointed to by the passed expression.
//
// @param (input) Node
// @param (input) Node path expression
// @param (input) Default value, If not found
// @return Date value or the default value if the node does not exist
///
Dcl-PR nox_GetDate date  extproc(*CWIDEN : 'nox_GetValueDateVC');
  pNode          Pointer    value;
  Expression     Like(UTF8_1K) const options(*nopass:*varsize);
  Defaultvalue   date   value options(*nopass);
End-PR;

/// TODO - migrated !!
// Get time value by expression
//
// Returns the time value of the node pointed to by the passed expression.
//
// @param (input) Node
// @param (input) Node path expression
// @param (input) Default value
// @return time value or the default value if the node does not exist
///
Dcl-PR nox_GetTime time(*ISO)  extproc(*CWIDEN : 'nox_GetValueTimeVC');
  pNode          Pointer    value;
  Expression     Like(UTF8_1K) const options(*nopass:*varsize);
  Defaultvalue   time(*ISO) value options(*nopass);
End-PR;

/// TODO - migrated !!
// Get TimeStamp value by expression
//
// Returns the TimeStamp value of the node pointed to by the passed expression.
//
// @param (input) Node
// @param (input) Node path expression
// @param (input) Default value
// @return TimeStamp value or the default value if the node does not exist
///
Dcl-PR nox_GetTimeStamp TimeStamp  extproc(*CWIDEN : 'nox_GetValueTimeStampVC');
  pNode          Pointer    value;
  Expression     Like(UTF8_1K) const options(*nopass:*varsize);
  Defaultvalue   TimeStamp   value options(*nopass);
End-PR;

/// TODO - migrated !!
// Get TimeStamp value by expression - alias for nox_GetTimeStamp
//
// Returns the TimeStamp value of the node pointed to by the passed expression.
//
// @param (input) Node
// @param (input) Node path expression
// @param (input) Default value
// @return TimeStamp value or the default value if the node does not exist
///
Dcl-PR nox_GetTS  TimeStamp  extproc(*CWIDEN : 'nox_GetValueTimeStampVC');
  pNode          Pointer    value;
  Expression     Like(UTF8_1K) const options(*nopass:*varsize);
  Defaultvalue   TimeStamp   value options(*nopass);
End-PR;

///
// Copy node value
//
// Copies the value of a node to an new or existing node.
// <br><br>
// If the source node is an object or array (type nox_ARRAY or nox_OBJECT) the
// object or array will be cloned to the destination value.
// <br><br>
// If the source node does not exist nothing will be copied and <code>*null</code>
// is returned.
// <br><br>
// If the source or destination is relative to the node the node path expression
// can be used to specify the location.
//
// @param (output) Destination node
// @param (output) Destination node path expression
// @param (input) Source node
// @param (input) Source node path expression
// @return New node or <code>*null</code> if the operation could not be executed
///
Dcl-PR nox_CopyValue Pointer extproc(*CWIDEN : 'nox_CopyValueVC');
  pDest          Pointer    value;
  destName       Like(UTF8) const options(*varsize);
  pSource        Pointer    value;
  sourceName     Like(UTF8) const options(*varsize:*nopass);
End-PR;

/// TODO - migrated !!
// Move node value
//
// Moves the value of a node to an new or existing node.
// <br><br>
// If the source node is an object or array (type nox_ARRAY or nox_OBJECT) the
// object or array will be moved ( with children) to the destination value.
// <br><br>
// If the source node does not exist nothing will be moved and <code>*null</code>
// is returned.
// <br><br>
// If the source or destination is relative to the node the node path expression
// can be used to specify the location.
//
// @param (output) Destination node
// @param (output) Destination node path expression
// @param (input) Source node
// @param (input) Source node path expression
// @return New node (Destination) or <code>*null</code> if the operation could not be executed
///
Dcl-PR nox_MoveValue Pointer extproc(*CWIDEN : 'nox_MoveValueVC');
  pDest          Pointer    value;
  destName       Like(UTF8) const options(*varsize);
  pSource        Pointer    value;
  sourceName     Like(UTF8) const options(*varsize:*nopass);
End-PR;

///
// Clone node
//
// Deep clone of the passed node.
//
// @param (input) Node
// @return Clone of the passed node
//
// @info The caller of this procedure needs to take care of freeing the resources
//       of the returned noxDB object graph by calling <em>nox_delete(node)</em>.
///
Dcl-PR nox_NodeClone Pointer extproc(*CWIDEN : 'nox_NodeClone');
  pSource        Pointer    value;
End-PR;

/// TODO - migrated !! - check return pointer !!
// Copy node - Clone a node and insert
//
// Adds a copy of an existing node to the noxDB object graph.
// <br><br>
// The reference location indicates where the new node will be added relative
// to the passed node. Possible value are
// <ul>
//   <li>NOX_FIRST_CHILD</li>
//   <li>NOX_LAST_CHILD</li>
//   <li>NOX_BEFORE_SIBLING</li>
//   <li>NOX_AFTER_SIBLING</li>
// </ul>
//
// @param (output) Node
// @param (input) Source node
// @param (input) Reference location
// @return New node or <code>*null</code> if source or destination is
//         <code>*null</code>.
///
Dcl-PR nox_NodeCopy pointer extproc(*CWIDEN : 'nox_NodeCopy');
  //node. Retrive from Locate()
  pRootNode      Pointer    value;
  //node. Retrive from Locate()
  pNewChild      Pointer    value;
  //Reference location to where it arrive
  RefLocation    Int(10)    value;
End-PR;



///
// Node Insert
//
// Creates a new node and insert that into eexisting root node
//
// <br><br>
//
// The reference location indicates where the new node will be moved into relative
// to the passed node. Possible value are
// <ul>
//   <li>NOX_FIRST_CHILD</li>
//   <li>NOX_LAST_CHILD</li>
//   <li>NOX_BEFORE_SIBLING</li>
//   <li>NOX_AFTER_SIBLING</li>
// </ul>
//
// @param (output) Node
// @param (input) Reference location
// @param (input) Name of node
// @param (input) Node value
// @param (input) Node type: Refere to above "node type"
// @return the new created node
///
Dcl-PR nox_NodeInsert Pointer extproc(*CWIDEN : 'nox_NodeInsertVC');
  // node. Retrive from Locate()
  pRootNode      Pointer    value;
  //Reference location to where it arrive
  RefLocation    Int(10)    value;
  //Name of node
  Name           Like(UTF8) const options(*varsize);
  //Value or expression
  Value          Like(UTF8) const options(*varsize);
  //New type (Refer "node type"
  Type           Uns(5)     value options(*nopass);
End-PR;

///
// Delete node
//
// The passed node and all child nodes are remove from the noxDB object graph.
// The memory is freed and the pointer is set to <code>*null</code>.
//
// @param (input) Node (<code>*null</code> will be ignored)
///
Dcl-PR nox_Delete extproc(*CWIDEN : 'nox_Delete');
  pNode      Pointer;
End-PR;

///
// Unlink node from graph
//
// Unlinks the passed node from the graph. The unlinked node will be promoted as
// a new root node and functions as a root in a separate graph
//
// @param (input) Node (<code>*null</code> will be ignored)
// @return Unlinked node
//
// @info The unlinked node is no longer connected to its former object graph
//       and its resources must be freed with a call to
//       <code>nox_close(unlinkedNode)</code>.
///
Dcl-PR nox_NodeUnlink Pointer extproc(*CWIDEN : 'nox_NodeUnlink');
  pNode          Pointer    value;
End-PR;

///
// Sanitize node
//
// Nodes with <code>null</code> values or no values at all will be removed from
// the noxDB object graph.
//
// @param (input/output) Node
///
Dcl-PR nox_NodeSanitize extproc(*CWIDEN : 'nox_NodeSanitize');
  pRootNode      Pointer    value;
End-PR;

///
// Create checksum of graph
//
// Creates a checksum of all node names and values. Names and values
// of <code>*null</code> are ignored.
//
// @param (input) Node
// @return Checksum
///
Dcl-PR nox_NodeCheckSum Uns(10) extproc(*CWIDEN : 'nox_NodeCheckSum');
  pRootNode      Pointer    value; // node. Retrive from Locate()
End-PR;

///
// Create object node
//
// Creates a new atomic noxDB object node.
//
// @info The caller of this procedure needs to take care of freeing the resources
//       of the returned noxDB object graph by calling <em>nox_delete(node)</em>.
///
Dcl-PR nox_NewObject Pointer extproc(*CWIDEN : 'nox_NewObject');
End-PR;


///
// Create array
//
// Creates a new atomic noxDB array node.
//
// @return New array
//
// @info The caller of this procedure needs to take care of freeing the resources
//       of the returned noxDB object tree by calling <em>nox_delete(node)</em>.
///
Dcl-PR nox_NewArray Pointer extproc(*CWIDEN : 'nox_NewArray');
End-PR;



///
// Push node into array
//
// Appends the passed node/value to the array ( or object ). The node can either be an noxDB
// object tree or a string. If a string is passed and it is a JSON expression
// (starting with { or [) it will be parsed else the string will be appended to
// the array as it.
//
// @param (output) Array ( or object)
// @param (input) Node to be appended to the end of the array
// @param (input) Push operation mode (NOX_MOVE_UNLINK (default) or NOX_COPY_CLONE)
// @return New node added to the end of the array
///
Dcl-PR nox_ArrayPush Pointer extproc(*CWIDEN : 'nox_ArrayPush');
  pDestArray     Pointer    value;
  pSourceNode    Pointer   value;
  copy           Uns(5)     value options(*nopass);
End-PR;

// Following constants used by nox_ArrayPush:copy
Dcl-C NOX_MOVE_UNLINK const(0);
Dcl-C NOX_COPY_CLONE  const(1);

///
// Push array or object nodes into array or object
//
// Appends all nodes from one array or object to another array or object.
//
// @param (output) Destination array or object (to)
// @param (input) Source array or object (from)
// @param (input) Push operation mode (nox_MOVE_UNLINK (default) or nox_COPY_CLONE)
// @return Destination array or object
///
Dcl-PR nox_Append Pointer extproc(*CWIDEN :'nox_Append');
  pDestArray     Pointer    value;
  pSourceNode    Pointer    value;
  copy           Uns(5)     value options(*nopass);
End-PR;


///
// Slice array
//
// returns a sub-array from an array. The node specified on the "to" parameter is
// included .
//
// @param (input) Array or JSON array string
// @param (input) From index (1-based)
// @param (input) To index (-1 = all nodes from "from" index to till the end)
// @param (input) Copy operation mode. nox_MOVE_UNLINK (default) removes the "sliced"
//        nodes from the source array. nox_COPY_CLONE leaves the nodes in
//        the source array and just copies the nodes to the new array.
// @return New array with the "sliced" nodes
///
Dcl-PR nox_ArraySlice Pointer extproc(*CWIDEN : 'nox_ArraySlice' );
  pSourceNode    Pointer    value;
  from           Int(10)    value;
  to             Int(10)    value;
  copy           Uns(5)     value options(*nopass);
End-PR;


///
// Sort array
//
// Sorts the array nodes "in place".
//
// @param (input/output) Array
// @param (input) Object attributes to compare
// @param (input) Compare options (0 = use JSON numeric (default) or NOX_USE_LOCALE)
// @return Sorted array
///
Dcl-PR nox_ArraySort Pointer extproc(*CWIDEN : 'nox_ArraySortVC');
  pArray         Pointer    value;
  pkeyNames      Like(UTF8) const ;
  options        uns(5)     value options(*nopass);
End-PR;

Dcl-C NOX_USE_LOCALE const(1);


/// TODO - nmigrated !!
// Convert an array of objects OR an object into a simple array
//
// @param (input/output) Array of objects or an object
// @param (input) Copy operation mode:
//    NOX_MOVE_UNLINK (default) removes the "input array of object" node.
//    NOX_COPY_CLONE leaves the node
// @return New array with the "converted" nodes
///
Dcl-PR nox_ArrayConvertList pointer extproc(*CWIDEN : 'nox_ArrayConvertList' );
  array pointer value options(*string);
  copyMode uns(5) value options(*nopass);
End-PR;

///
// Lookup value
//
// Returns the first node which matches the passed expression.
//
// @param (input) Array or object
// @param (input) Search value
// @param (input) Case sensitivity (NOX_SAME_CASE or NOX_IGNORE_CASE)
// @return First node which matches the expression else <code>*null</code>
//
// @info The search will not be done recursivly. Only the first level (depth)
//       of the node's content will be evaluated.
///
Dcl-PR nox_LookupValue Pointer extproc(*CWIDEN : 'nox_LookupValueVC');
  pArray         Pointer    value;
  expr           Like(UTF8) const options(*varsize);
  ignoreCase     Uns(5)     value options(*nopass);
End-PR;
///
// Following constants used by nox_LookupValue:ignoreCase
///
Dcl-C NOX_SAME_CASE const(0);
Dcl-C NOX_IGNORE_CASE const(1);

///
// Get length
//
// Returns the number of nodes in an array or object.
//
// @param (input) Node
// @return Number of nodes or -1 if the passed node is no array or
//         object node type.
///
Dcl-PR nox_GetLength Int(10) extproc(*CWIDEN : 'nox_getLength'  );
  pNode       Pointer    value;
End-PR;
///


// Following constants used by nox_Merge:Type
Dcl-C NOX_DONTREPLACE const(0);
Dcl-C NOX_REPLACE const(1);

///
// Merge objects
//
// Merges all nodes from the <em>source</em> object into the <em>destination</em>
// object tree. Objects are recursively merged. The nodes (entries) of arrays
// are not merged. The whole array is either replaced or retained depending on
// the options parameter.
// <br><br>
// The options parameter determines what happens if a node with the same name
// exists in both object trees.
//
// @param (input/output) Destination object tree
// @param (input) Source object tree
// @param (input) Merge option:  MO_MERGE_NEW,MO_MERGE_MATCH,MO_MERGE_REPLACE,MO_MERGE_MOVE )
///
Dcl-PR nox_MergeObjects Pointer extproc(*CWIDEN : 'nox_MergeObjects');
  pDestObj       Pointer    value;
  pSourceObj     Pointer    value;
  Type           Uns(5)     value;
End-PR;
///
// Move object into
//
// Moves a <em>source</em> object into a <em>destination</em> object. If the
// source object is no root object it will be unlinked from its current object
// tree. The source object will be available in the destination object under
// the passed name.
// <br><br>
// If no name is passed ('' or *null) then the source object replaces the
// destination object in its current position in the object tree.
// <br><br>
// Any existing node with the passed name in the destination object will be
// replaced by the source object.
//
// @param (input/output) Destination object
// @param (input) New node name
// @param (input) Source object
// @return Source object
//
// @info The <em>name</em> parameter is <b>no</b> node path expression!
//       It is the concrete name of the source object in the destination
//       object.
///
Dcl-PR nox_MoveObjectInto Pointer extproc(*CWIDEN : 'nox_NodeMoveIntoVC');
  pDestObj       Pointer    value;
  Name           Like(UTF8) const options(*varsize);
  pSourceObj     Pointer    value;
End-PR;

///
// Appped to and object or array
//
//
// @param (input/output) Destination object
// @param (input) Sibling to append
// @return Destination object
//
///
Dcl-PR nox_AppendObject Pointer extproc(*CWIDEN : 'nox_NodeAppend');
  pDestObj       Pointer    value;
  pSiblin        Pointer    value;
End-PR;
///
// Move node into object graph
//
// Moves a node into an existing object graph.
//
// @param Destination node
// @param Source node
// @param Destination location (see Node Copy - Reference locations  )
// @return Destination node
//
// @info The source node pointer will be <code>*null</code> after this function
//       call.
///
Dcl-PR nox_DocumentInsert pointer extproc(*CWIDEN : 'nox_DocumentInsert');
  destination pointer value;
  source pointer;
  location int(10) value;
End-PR;

///
// Dump object tree
//
// Outputs the object tree of the passed node via <em>printf</em>.
//
// @param (input) Node
///
Dcl-PR nox_Dump  extproc(*CWIDEN : 'nox_Dump');
  pNode          Pointer    value;
End-PR;


///
// Write JSON to stream file
//
// Writes the object tree as a JSON string to a stream file in the IFS.
//
// @param (input) Node
// @param (input) IFS File name
// @param (input) CCSID of the output file
// @param (input) <code>*off</code> = output will be pretty printed else
//        <code>*on</code> (default)
// @param (input) Object tree node with options (not supported atm)
//
// @info By default a BOM will be prepended for unicode data. If no BOM is
//       needed then the CCSID should be stated as a negative number, like
//       -1208 for UTF-8.
// @info Any existing file will be overwritten.
// @info The trimming of the output refers only to the formatting / pretty
//       printing of the document. Any leading or trailing spaces in any
//       values will be preserved.
///
Dcl-PR nox_WriteJsonStmf  extproc(*CWIDEN : 'nox_WriteJsonStmf');
  pNode          Pointer    value;
  FileName       Pointer    value  options(*string);
  Ccsid          Int(10)    value;
  Trim           Ind        value;
  Options        Pointer    value  options(*nopass:*string);
End-PR;

///
// To JSON string
//
// Returns the passed object tree as a JSON string.
//
// @param (input) Node
// @return Object tree representation as a JSON string
///
Dcl-PR nox_AsJsonText Like(UTF8_MAX) rtnparm OPDESC extproc(*CWIDEN : 'nox_AsJsonText');
  pNode          Pointer    value;
End-PR;


///
// To JSON string (Buffer)
//
// Places the passed object tree as a JSON string into the passed buffer.
//
// @param (input) Node
// @param (output) Buffer
// @param (input) Buffer length (in bytes)
// @return Length of the serialized JSON string
//
// @info If no buffer length is passed the procedure will assume the default
//       buffer size which is about 2GB, see MEMMAX defined in memUtil.h.
///
Dcl-PR nox_AsJsonTextMem Uns(10) extproc(*CWIDEN : 'nox_AsJsonTextMem');
  pNode          Pointer    value;
  pBuffer        Pointer    value;
  maxSize        Uns(10)    value options(*nopass);
End-PR;

///
// Write XML to stream file
//
// Writes the object tree as a XML string to a stream file in the IFS.
// A XML header including the used encoding will be written at the
// start of the XML file.
//
// @param (input) Node
// @param (input) File name (either a literal or null-terminated in a variable)
// @param (input) CCSID of the output file
// @param (input) <code>*off</code> = output will be pretty printed else
//        <code>*on</code> (default)
// @param (input) Object tree node with options (not supported atm)
//
// @info Following CCSIDs are supported: 1200, 1208, 819, 1252. Every
//       other CCSID defaults to 1252.
// @info CCSIDs 1200 and 1208 will get a BOM prepended to the actual XML.
// @info Any existing file will be overwritten.
// @info The trimming of the output refers only to the formatting / pretty
//       printing of the document. Any leading or trailing spaces in any
//       values will be preserved.
///
Dcl-PR nox_WriteXmlStmf  extproc(*CWIDEN : 'nox_WriteXmlStmf');
  pNode          Pointer    value;
  FileName       Pointer    value  options(*string);
  Ccsid          Int(10)    value options(*nopass);
  Trim           Ind        value options(*nopass);
  Options        Pointer    value  options(*nopass:*string);
End-PR;


///
// To XML string
//
// Returns the passed object tree as a XML string.
//
// @param (input) Node
// @return Object tree representation as a XML string
///
Dcl-PR nox_AsXmlText Like(UTF8_MAX) rtnparm OPDESC extproc(*CWIDEN : 'nox_AsXmlText');
  pNode          Pointer    value;
End-PR;


///
// To XML string (Buffer)
//
// Places the passed object tree as a XML string into the passed buffer.
//
// @param (input) Node
// @param (output) Buffer
// @return Length of the serialized XML string
//
// @warning Buffer length is not checked.
///
Dcl-PR nox_AsXmlTextMem Uns(10) extproc(*CWIDEN : 'nox_AsXmlTextMem');
  // node. Retrive from Locate()
  pNode          Pointer    value;
  // pointer to any memory buffer
  pBuffer        Pointer    value;
End-PR;



/// TODO - migrated !!
// String quote - escapes quotes into double quotes and add leading and trailing
// Courtesy function to avoid SQL injection attacks
//
// Returns quote escaped string
//
// @param (input) String to be quoted
// @return Quoted string
///
Dcl-PR nox_strQuote  Like(UTF8) rtnparm  extproc(*CWIDEN : 'nox_strQuote');
  stringToQuote Like(UTF8) const  options(*varsize);
End-PR;

///
// Stream format options
///
Dcl-C NOX_STREAM_JSON const(0);
Dcl-C NOX_STREAM_XML  const(1);
Dcl-C NOX_STREAM_CSV  const(2);



///
// Create stream
//
// Return a streamer object to be used in own serialisers
// Creates a stream object to be used by the noxDB serializers.
//
// @param (input) Node
// @return Stream object
///
Dcl-PR nox_Stream pointer extproc(*CWIDEN : 'nox_Stream');
  pNode          Pointer    value;
  format         int(10)    value;
End-PR;

///
// Write CSV to stream file
//
// Writes the object tree as a CSV (character seperated values) string to a
// stream file in the IFS.
// <br><br>
// The options parameter is a noxDB object tree with following values:
// <ul>
//   <li>delimiter : value separator</li>
//   <li>decPoint : decimal point character</li>
//   <li>headers : true = column headers will be written</li>
// </ul>
//
// @param (input) Node
// @param (input) File name (either a literal or null-terminated in a variable)
// @param (input) CCSID of the output file
// @param (input) <code>*on</code> = output will be trimmed else <code>*off</code>
// @param (input) Options
//
// @info CCSIDs 1200 and 1208 will get a BOM prepended to the actual values.
// @info Any existing file will be overwritten.
///
Dcl-PR nox_WriteCsvStmf  extproc(*CWIDEN : 'nox_WriteCsvStmf');
  pNode          Pointer    value;
  FileName       Pointer    value  options(*string);
  Ccsid          Int(10)    value;
  Trim           Ind        value;
  Options        Pointer    value  options(*nopass:*string);
End-PR;

///
// Iterator template - this data structure holds state of the iteration,
// see nox_ForEach. Thus multiple iterators can be used on the same object
// tree at the same time. All properties are read-only except "break".
//
// <ul>
//   <li>root : node of the origin of the iterator</li>
//   <li>this : current node in the list</li>
//   <li>isList : will be *ON if the iterator is working in the list</li>
//   <li>isFirst : will be *ON only at the first element</li>
//   <li>isLast : will be *ON only at the last element</li>
//   <li>isRecursive : will be on in a recursion </li>
//   <li>comma : Will be ',' as long there are more elements in the list </li>
//   <li>count : current element index (starting at 1)</li>
//   <li>length : number of elements</li>
//   <li>size  : Size of the iterator object ( internal use only)</li>
//   <li>listArr :Pointer to temp array of elms for recursive lists ( internal use only)</li>
//   <li>break : set this to *ON to terminate the loop, and free up memory</li>
// </ul>
///
Dcl-DS nox_Iterator qualified Template;
  root           Pointer;
  this           Pointer;
  isList         Ind;
  isFirst        Ind;
  isLast         Ind;
  isRecursive    Ind;
  comma          Varchar(1);
  count          Int(10);
  length         Int(10);
  size           Int(10);
  listArr        Pointer;
  break          Ind;
  filler         Char(64);
End-DS;

///
// Create iterator
//
// Creates a new iterator instance on the passed object tree.
//
// @param (input) Node
// @param (input) Node path expression to the node which child elements will be iterated
// @return Iterator instance
//
// @info This iterator should be used with the function <em>nox_forEach</em>
///
Dcl-PR nox_setIterator  likeds(nox_Iterator) extproc(*CWIDEN : 'nox_SetIteratorVC');
  pNode          Pointer    value;
  path           Like(UTF8_1K) const options(*nopass:*varsize);
End-PR;

///
// Create recursive iterator
//
// Creates a new iterator instance on the passed object tree. This iterator
// will not stop iterating when the end is reached but will restart at the
// given start node.
//
// @param (input) Node
// @param (input) Node path expression to the node which child elements will be iterated
// @return Iterator instance
///
Dcl-PR nox_setRecursiveIterator  likeds( nox_Iterator)
        extproc(*CWIDEN : 'nox_SetRecursiveIteratorVC');
  pNode          Pointer    value;
  path           Like(UTF8_1K) const options(*nopass:*varsize);
End-PR;

///
// Iterate
//
// Iterates through the child nodes of the iterator start node. The entries
// are either the entries of an array or the keys of an object depending on
// the start node.
// <br><br>
// The current value (iterator.this) and some additional information (isFirst,
//  isLast, ...) can be retrieved from the iterator data structure.
// <br><br>
// The iteration can be interrupted either by leaving the loop or by setting
// iterator.break to *on.
// Note: Always use the "break" property of the iterator to terminate the
// iteration and free up memory.
//
// @param (input) Iterator
// @return *on if there is another entry , *off if the iteration ended
///
Dcl-PR nox_forEach Ind extproc(*CWIDEN : 'nox_ForEach');
  iterator  likeds( nox_Iterator);
End-PR;


//
// XML attributes
//

///
// Get attribute value from node
//
// Returns the attribute value of the attribute from the passed node.
// note: Used mostly in XML, but can be usefull elsewhere
//
// @param (input) Node
// @param (input) Attribute name
// @param (input) Default value
// @return Attribute value or default value if no attriute exists
///
Dcl-PR nox_GetNodeAttrValue Like(UTF8)
          rtnparm extproc(*CWIDEN : 'nox_GetNodeAttrValueVC');
  pNode          Pointer    value;
  AttrName       Like(UTF8_1K) const options(*varsize);
  Defaultvalue   Like(UTF8) const options(*nopass:*varsize);
End-PR;

///
// Set attribute on node
//
// Sets the attribute on the passed node. Any existing attribute value
// will be replaced.
//
// @param (input) Node
// @param (input) Attribute name
// @param (input) Attribute value
//
// @info Attributes will be omitted in JSON output.
///
Dcl-PR nox_SetNodeAttrValue
          extproc(*CWIDEN : 'nox_SetNodeAttrValueVC');
  pNode          Pointer    value;
  AttrName       Like(UTF8_1K) const options(*varsize);
  Value          Like(UTF8) const options(*varsize);
End-PR;

///
// Get attribute value
//
// Returns the value from the passed attribute.
//
// @param (input) Attribute
// @param (input) Default value
// @return Attribute value or default value if the attribute has no value
///
Dcl-PR nox_GetAttrValue
                 Like(UTF8) rtnparm extproc(*CWIDEN : 'nox_GetAttrValueVC');
  pAttr          Pointer    value;
  Defaultvalue   Like(UTF8) const options(*nopass:*varsize);
End-PR;

///
// Append new attibute
//
// Appends a new attribute with the passed name and value to the attribute
// list which the passed attribute is part of. Duplicate attribute names
// are valid.
//
// @param (input) Attribute
// @param (input) Name
// @param (input) Value
///
Dcl-PR nox_SetAttrValue extproc(*CWIDEN : 'nox_SetAttrValue');
  pAttr          Pointer    value;
  AttrName       Like(UTF8_1K) const options(*varsize);
  Value          Like(UTF8) const options(*varsize);
End-PR;


///
// Get first attribute
//
// Returns the first attribute of the attribute list of the passed node.
// This can be used for iterating over the attributes of a node in
// conjunction with the function <em>nox_getAttrNext</em>.
//
// @param (input) Node
// @return First attribute or <code>*null</code> if the node has no
//         attributes.
///
Dcl-PR nox_GetAttrFirst Pointer extproc(*CWIDEN : 'nox_GetAttrFirst');
  pNode          Pointer    value;
End-PR;

///
// Get next attribute
//
// Returns the next attribute of the attribute list.
//
// @param (input) Attribute
// @return Next attribute or <code>*null</code> if there are no more attributes
///
Dcl-PR nox_GetAttrNext Pointer extproc(*CWIDEN : 'nox_GetAttrNext');
  pAttribute   Pointer    value;
End-PR;

///
// Get attribute name
//
// Returns the name of the passed attribute.
//
// @param (input) Attribute
// @return Attribute name
///
Dcl-PR nox_GetAttrName
               Like(UTF8_1K) rtnparm extproc(*CWIDEN : 'nox_GetAttrNameVC');
  pAttribute   Pointer    value;
End-PR;

//
// XML attributes end
//

///
// Clear array / object
//
// Clears the contents of an array or object (deletes all child nodes).
//
// @param (input) Node
///
Dcl-PR nox_Clear  extproc(*CWIDEN : 'nox_Clear');
  pNode          Pointer    value; // Pointer to graph node
End-PR;


///
// Close object graph
//
// Frees all resources allocated by this object graph.
//
// @param (input) Node
//
// @info The passed node does not necessarily has to be the root node of the
//       graph. Any node of the graph will suffice.
///
Dcl-PR nox_Close  extproc(*CWIDEN : 'nox_Close');
  pNode          Pointer  ;
End-PR;

///
// Pprograms and procedures section begin
///

/// TODO - migrated !!
// Programs and procedures : Call program
//
// Call ILE program compiled with ctl-opt pgminfo(*PCML:*MODULE)
//
// @param (input) Library where the ILE program exists or *LIBL
// @param (input) Program name of the ILE program
// @param (input) parms   input parameters for the program in a json object mached by names
// @param (input) options formating and runtime options AND/added togeter
// @return noxDB object tree with output from the program call
//
// @info The caller of this procedure needs to take care of freeing the resources
//       of the returned noxDB object tree by calling <em>nox_delete(node)</em>.
///

Dcl-PR nox_CallProgram pointer extproc(*CWIDEN : 'nox_CallProgram');
  library        char(10) const;
  program        char(10) const;
  parms          pointer  value  options(*string:*nopass) ;
  formatOptions  int(10) value options(*nopass) ;
End-PR;


/// TODO - migrated !!
// Programs and procedures : Load program as procedure pointer
//
//
// @param (input) Library where the ILE program exists or *LIBL
// @param (input) Program name of the ILE program
// @return procedure pointer or null and wrap it in a MONITOR
//
///
Dcl-PR nox_LoadProgram pointer(*proc) extproc(*CWIDEN : 'nox_loadProgram');
  library        char(10) const;
  program        char(10) const;
End-PR;

/// TODO - migrated !!
// Programs and procedures : Call program  - lo level
// @param (input) procedure pointer to the program  to call
// @param (input) parms pointer to array of addresse to parameters to pass to the procedure
// @param (input) numberOfParms number of parameters to pass to the procedure
///
Dcl-PR nox_CallPgm extproc(*CWIDEN : 'nox_callPgm');
  procedure      pointer (*PROC) value;
  parms          pointer value  ;
  numberOfParms  int(10) value  ;
End-PR;


/// TODO - migrated !!
// Programs and procedures : Program meta
//
// Returns the parameter meta information as a noxDb object graph accordin to the PCML format
//
// @param (input) Library where the ILE program exists or *LIBL
// @param (input) Program name of the ILE program
// @param (input) options formating and runtime options AND/added togeter
// @return noxDB object tree with output from the program call
//
// @info The caller of this procedure needs to take care of freeing the resources
//       of the returned noxDB object tree by calling <em>nox_delete(node)</em>.
///

Dcl-PR nox_ProgramMeta pointer extproc(*CWIDEN : 'nox_ProgramMeta');
  library        char(10) const;
  program        char(10) const;
  formatOptions  int(10) value options(*nopass) ;
End-PR;


/// TODO - migrated !!
// Programs and procedures : Call procedure
//
// Call ILE service program procedure compiled with ctl-opt pgminfo(*PCML:*MODULE)
//
// @param (input) Library where the ILE service program exists or *LIBL
// @param (input) service Program name
// @param (input) procedure Name of service program procedure to call
// @param (input) parms   input parameters for the program in a json object mached by names
// @param (input) options formating and runtime options AND/added togeter
// @return noxDB object tree with output from the program call
//
// @info The caller of this procedure needs to take care of freeing the resources
//       of the returned noxDB object tree by calling <em>nox_delete(node)</em>.
///

Dcl-PR nox_CallProcedure pointer extproc(*CWIDEN : 'nox_CallProcedure');
  library        char(10)    const;
  srvpgm         char(10)    const;
  procedure      pointer     value  options(*string);
  parms          pointer     value  options(*string:*nopass) ;
  formatOptions  int(10) value options(*nopass) ;
End-PR;


/// TODO - migrated !!
// Programs and procedures : Load service program procedure as procedure pointer
//
//
// @param (input) Library where the ILE service program exists or *LIBL
// @param (input) Program name of the ILE service program
// @return procedure pointer or null and wrap it in a MONITOR
//
///
Dcl-PR nox_LoadServiceProgramProc pointer(*proc) extproc(*CWIDEN : 'nox_loadServiceProgramProc');
  library        char(10) const;
  program        char(10) const;
  procedure      pointer     value  options(*string);

End-PR;

/// TODO - migrated !!
// Programs and procedures : Call procedure - lo level
// @param (input) procedure pointer to the procedure to call
// @param (input) parms pointer to array of addresse to parameters to pass to the procedure
// @param (input) numberOfParms number of parameters to pass to the procedure
///
Dcl-PR nox_CallProc extproc(*CWIDEN : 'nox_callProc');
  procedure      pointer (*PROC) value;
  parms          pointer value  ;
  numberOfParms  int(10) value  ;
End-PR;

/// TODO - migrated !!
// Programs and procedures : Program meta
//
// Returns the parameter meta information as a noxDb object graph according to the PCML format
//
// @param (input) Library where the ILE service program exists or *LIBL
// @param (input) service Program name
// @param (input) procedure Name of service program procedure or *ALL
// @param (input) options formating and runtime options AND/added togeter
// @return noxDB object tree with meta descript in PCML format
//
// @info The caller of this procedure needs to take care of freeing the resources
//       of the returned noxDB object tree by calling <em>nox_delete(node)</em>.
///

Dcl-PR nox_ProcedureMeta pointer extproc(*CWIDEN : 'nox_ProcedureMeta');
  library        char(10)  const;
  program        char(10)  const;
  procedure      pointer   value options(*string);
  formatOptions  int(10)   value options(*nopass) ;
End-PR;

/// TODO - migrated !!
// Programs and procedures : Program and service program meta
//
// Returns the parameter meta information as a noxDb object graph according to the PCML format
// however in a JSON  format
//
// @param (input) Library where the ILE service program exists or *LIBL
// @param (input) service Program name
// @param (input) procedure Name of service program procedure or *ALL , or *NULL for programs
// @return noxDB object tree with meta description in JSON from the PCML format
//
// @info The caller of this procedure needs to take care of freeing the resources
//       of the returned noxDB object tree by calling <em>nox_delete(node)</em>.
///

Dcl-PR nox_ApplicationMeta pointer extproc(*CWIDEN : 'nox_ApplicationMeta');
  library        char(10)  const;
  program        char(10)  const;
  procedure      pointer   value options(*string);
End-PR;

///
// Pprograms and procedures section end
///




///
// Detect memory leak
//
// Checks if more memory has been allocated than deallocated.
//
// @return <code>*on</code> = more memory allocated than deallocated else
//         <code>*off</code>
///
Dcl-PR nox_MemLeak Ind extproc(*CWIDEN : 'nox_MemLeak');
End-PR;


///
// Print memory statistics
//
// Prints the memory statistics to the console (printf).
///
Dcl-PR nox_MemStat  extproc(*CWIDEN : 'nox_MemStat');
End-PR;

///
// Memory used
//
// Returns the number of bytes currently used by any noxDB object tree in the
// current activation group.
//
// @return Number of bytes used
///

Dcl-PR nox_MemUse Uns(20) extproc(*CWIDEN : 'nox_MemUse');
End-PR;


/// TODO - not migrated !!
// Log message
//
// Sends an info message to the job log. The passed message can either be text
// or a node. If a node is passed it will be serialized to a JSON string before
// being sent to the job log.
//
// @param (input) Message text or node
///
Dcl-PR nox_joblog extproc(*CWIDEN : 'nox_Joblog');
  textOrNode pointer value options(*string);
End-PR;

Dcl-PR nox_joblogUtf8 extproc(*CWIDEN : 'nox_JoblogVC');
  textOrNode Like(UTF8_1K) const options(*varsize);
End-PR;


///
// mapix - map index to pointer
//
// Maintain at list of index numbers to database CLOB/BLOB
// fields since pointers can not be shared in SQL
// @param (input) pointer to pointer to node
// @param (input) index  number ( 1= first )
//
// @return *ON if found
///
Dcl-PR nox_mapIx Ind extproc(*CWIDEN:'nox_MapIx' );
  ppNode         Pointer;
  Index          Uns(10)    value;
End-PR;


///
// Execute HTTP request
//
// Executes an HTTP request. By default it will be a GET request. If a payload
// has been passed the payload will be serialized to a JSON string and the
// request will automatically be a POST request. The payload will be passed
// as unicode to cURL.
// <br><br>
// The returned JSON object contains the attribute "success" (either true or
// false) and "reason" (which contains the cURL error output (to <em>stderr</em>)
// of the request).
//
// @param (input) URL
// @param (input) HTTP request payload (object tree)
// @param (input) Extra cURL options
// @param (input) Format of the request. XML, JSON or TEXT (defaults to JSON). TEXT requires you to set the headers
// @return JSON object
//
// @info This function uses the curl command.
///
Dcl-PR nox_httpRequest Pointer extproc(*CWIDEN:'nox_httpRequest');
  url            Like(UTF8) const options(*varsize);
  pReqNode       pointer value;
  options        Like(UTF8) const options(*nopass:*varsize);
  format         pointer value options(*string : *nopass);
End-PR;


/// TODO - migrated !!
// Set trace procedure
//
// Sets the trace procedure which gets called on any interaction with an
// object tree.
//
// <br/><br/>
//
// The passed procedure must implement the following interface:
// <code>
// dcl-pi *n;
//   text pointer value options(*string);
//   node pointer value;
// end-pi;
// </code>
//
// @param (input) Trace procedure
///
Dcl-PR nox_setTraceProc extproc(*CWIDEN : 'nox_SetTraceProc');
  procedure pointer(*proc) value;
End-PR;


///
// SQL interface
//
// Note: When SQL functions return *NULL, then use  the nox_Message() to
//       retrieve the error message. also the getSqlCode() can be usefull
//

///
// SQL : Set SQL options
//
// This needs to be the first call if any SQL options need to be set.
// Supported SQL options are:
//
// <h4>upperCaseColName</h4>
// <em>true</em> means that the column names in the result set are in upper
// case. Default: false.
//
// <h4>autoParseContent</h4>
// <em>true</em> means that any JSON or XML data in columns will be parsed
// into subobjects in the resulting object. Default: true.
//
// <h4>DecimalPoint</h4>
// The value of this option is used as a decimal point.
//
// <h4>sqlNaming</h4>
// <em>true</em> means that SQL Naming is used and any non qualified tables
// are searched in the current schema. <em>false</em> means that system naming
// is used and the tables are searched in the library list.
//
// NOTE: If a pConnection pointer is provided, it will be updated with the connection
// @param (input) Pointer to connection ( from nox_sqlConnect() ) or *null
// @param (input) Object tree or JSON string containing SQL options or
//        <code>*null</code> to use the default options
///
Dcl-PR nox_sqlSetOptions  extproc(*CWIDEN: 'nox_sqlSetOptions');
  pConnection    pointer value;
  parms          Like(UTF8) const options(*nopass:*varsize);
End-PR;

/// TODO - not migrated !!
// retrive currens SQL setting
Dcl-PR nox_sqlGetOptions Like(UTF8) extproc(*CWIDEN : 'nox_sqlGetOptions');
  pConnection    pointer value;
End-PR;


/// TODO - migrated !!
// SQL : Execute SQL statement "Values"
//
// Returns an value or an array of values like the  "values into" - being array, object or value
//
// @param (input) Pointer to database connection provided by nox_sqlConnect()
// @param (input) SQL statement valid for a SET statmet
// @param (input) Template values (context)
// @param (input) Result value format options
// @return Result object of values : array, object or single values value
///
Dcl-PR nox_sqlValues pointer extproc(*CWIDEN: 'nox_sqlValuesVC');
  pConnection    pointer value;
  statement      pointer value options(*string);
  templateValues pointer value options(*string : *nopass);
  formatOptions  int(10) value options(*nopass);
End-PR;


/// TODO - check templateValues and format
// SQL : Execute SQL statement (single row)
//
// Returns an object node with one (first) resulting row for the SQL statment.
//
// @param (input) Pointer to database connection provided by nox_sqlConnect()
// @param (input) SQL statement
// @param (input) Template values (context)
// @param (input) start row ( 1 = first (default) )
// @param (input) Result set format options
// @return Result set or <code>*null</code> if the SELECT returns no rows
//         that is an object node with one resulting row for the SQL statment
///
Dcl-PR nox_sqlResultRow Pointer extproc(*CWIDEN: 'nox_sqlResultRowVC');
  pConnection    pointer value;
  statement      Like(UTF8) const options(*varsize);
  templateValues pointer value options(*string : *nopass);
  formatOptions  int(10) value options(*nopass);
  start          Int(10)    value options(*nopass);
End-PR;


/// TODO - check templateValues and format
// SQL : Execute SQL statement (multiple rows)
//
// Executes the statement and returns the result set. The result set
// structure depends on the passed options.
//
// @param (input) Pointer to database connection provided by nox_sqlConnect()
// @param (input) SQL statement
// @param (input) Template values (context)
// @param (input) Start ( 1 = first (default) )
// @param (input) Max. number of rows (default: nox_ALLROWS)
// @param (input) Result set format options
// @return Result set
///
Dcl-PR nox_sqlResultSet Pointer extproc(*CWIDEN: 'nox_sqlResultSetVC');
  pConnection    pointer value;
  statement      Like(UTF8) const options(*varsize);
  templateValues pointer value options(*string : *nopass);
  formatOptions  Int(10)    value options(*nopass);
  start          Int(10)    value options(*nopass);
  limit          Int(10)    value options(*nopass);
End-PR;

///
// All rows should be returned.
///
Dcl-C NOX_ALLROWS const(-1);

///
// Result set format option for returning the result set as an array with each
// row contained in a seperate object inside the returned array.
///
Dcl-C NOX_ROWARRAY const(0);
///
// Result set format option for additionally returning meta data with the
// result set in the property "metaData". This option triggers returning the
// result set to be an object instead of the default array.
///
Dcl-C NOX_META    const(1);
///
// Result set format option for additionally returning meta data about the
// table columns with the result set in the property "metaData.fields".
///
Dcl-C NOX_FIELDS  const(2);
///
// Result set format option for returning the total number of rows returned
// in the result set object property "totalRows".
///
Dcl-C NOX_TOTALROWS const(4);
///
// Result set format option for returning the column names in upper case.
///
Dcl-C NOX_UPPERCASE const(8);
///
// Result set format option for returning the approximate number of total
// rows in the result set object property "totalRows". This option executes
// faster than nox_TOTALROWS but is not as precise.
///
Dcl-C NOX_APPROXIMATE_TOTALROWS const(16);
/// TODO - not migrated !!
// Result set format option to return system column names instead of sql
// column names.
///
Dcl-C NOX_SYSTEM_NAMES  const(32);
/// TODO - not migrated !!
// Result set format option to return the column names in camel case.
// "THE_COLUMN_NAME" will be returned as "theColumnName".

/// TODO - not migrated !!
Dcl-C NOX_CAMEL_CASE   const(64);

/// TODO - not migrated !!
// For SQL resultset
// If set: resultSets will return a success:false
// and set the message to the apropiate SQL error text
// If not set:  a *NULL pointer is returned and
// you have to handle the error manually
///
Dcl-C NOX_GRACEFUL_ERROR   const(128);

/// TODO - not migrated !!
// Result set format option to return extra column text label
///
Dcl-C NOX_COLUMN_TEXT   const(256);



///
// SQL : Open SQL cursor
//
// Opens a cursor for processing the SQL data row by row.
//
// @param (input) Pointer to database connection provided by nox_sqlConnect()
// @param (input) SQL statement
// @param (input) Template values (context) - string or noxDb graph
// @param (input) Result set format options
// @return SQL handle
//
// @info Any opened cursor needs to be closed with <code>nox_sqlClose</code>.
///
Dcl-PR nox_sqlOpen Pointer extproc(*CWIDEN:'nox_sqlOpenVC'  );
  pConnection    pointer value;
  sqlStmt        Like(UTF8) const options(*varsize);
  templateValues pointer value options(*string : *nopass);
  format         int(10) value options(*nopass); // TODO - not migrated !!
  startRow       int(10) value options(*nopass); // TODO - not migrated !!
  limitRows      int(10) value options(*nopass); // TODO - not migrated !!
End-PR;


///
// SQL : Fetch row at position n
//
// Returns the next row from the SQL data relative to the current cursor position.
//
// @param (input) SQL handle
// @param (input) Additional offset (relative to the current cursor) (1=next, -1=previous)
// @return Row object or <code>*null</code> if there are no more rows to fetch
///
Dcl-PR nox_sqlFetchRelative Pointer
                            extproc(*CWIDEN: 'nox_sqlFetchRelative');
  pSqlHndl       Pointer    value;
  fromRow        Int(10)    value;
End-PR;

///
// SQL : Fetch next row
//
// Returns the next row from the SQL data.
//
// @param (input) SQL handle
// @return Row object or <code>*null</code> if there are no more rows to fetch
///
Dcl-PR nox_sqlFetchNext Pointer extproc(*CWIDEN:'nox_sqlFetchNext');
  pSqlHndl       Pointer    value;
End-PR;

///
// SQL : Get number of result set columns
//
// Returns the number of columns included in the result set.
//
// @param (input) SQL handle
// @return Number of columns or -1 if an error occured
///
Dcl-PR nox_sqlColumns Int(10) extproc(*CWIDEN:'nox_sqlColumns');
  pSqlHndl       Pointer    value;
End-PR;

///
// SQL : Get number of result set rows
//
// Returns the number of rows the SQL statement used by the SQL handle will
// return in total.
//
// @param (input) SQL handle
// @return Number of rows or -1 if an error occured
//
// @info This will run a hidden "select count(*)" which might be a little pricy.
///
Dcl-PR nox_sqlRows Int(10) extproc(*CWIDEN:'nox_sqlRows');
  pSqlHndl       Pointer    value;
End-PR;

///
// SQL : Close SQL cursor
//
// Closes the passed SQL cursor.
//
// @param (input) SQL handle
//
// @info This function needs to be called for every SQL cursor opened with
//       <code>nox_sqlOpen</code>.
///
Dcl-PR nox_sqlClose  extproc(*CWIDEN:'nox_sqlClose');
  pSqlHndl       Pointer;
End-PR;

///
// SQL : Execute SQL statement
//
// Executes any SQL statement not involving a cursor.
//
// @param (input) Pointer to database connection provided by nox_sqlConnect()
// @param (input) SQL statement
// @param (input) Template values (context)
// @return <code>*on</code> if an error occured else <code>*off</code>
///
Dcl-PR nox_sqlExec Ind extproc(*CWIDEN:'nox_sqlExecVC'  );
  pConnection    pointer value;
  sqlStmt        Like(UTF8) const options(*varsize);
  templateValues pointer value options(*string : *nopass); // TODO - not migrated !!
End-PR;


/// TODO - not migrated !!
// SQL : Call stored procedure
//
// Calls a SQL stored procedure with the passed parameters.
//
// @param (input) Pointer to database connection provided by nox_sqlConnect()
// @param (input) Qualified SQL procedure name
// @param (input) noxDB object tree with input parameters
// @return noxDB object tree with output parameters
//
// @info The caller of this procedure needs to take care of freeing the resources
//       of the returned noxDB object tree by calling <em>nox_delete(node)</em>.
///
Dcl-PR nox_sqlCall pointer extproc(*CWIDEN : 'nox_sqlCall');
  pConnection    pointer value;
  procedureName  Like(UTF8_1K) const options(*varsize);
  inputParms pointer value;
End-PR;

/// TODO - not migrated !!
// SQL : Call stored procedure, select from UDTF table functions, return values from scalar function
//
// Calls a SQL stored procedure / Table Function / value with the passed parameters.
//
// @param (input) Pointer to database connection provided by nox_sqlConnect()
// @param (input) Qualified SQL procedure / UDTF / value  name
// @param (input) noxDB object tree with input ( INOUT) parameters
// @param (input) Result set format options
// @return noxDB object tree with output parameters or reult set
//
// @info The caller of this procedure needs to take care of freeing the resources
//       of the returned noxDB object tree by calling <em>nox_delete(node)</em>.
///
Dcl-PR nox_sqlExecuteRoutine pointer extproc(*CWIDEN : 'nox_sqlExecuteRoutine');
  pConnection     pointer value;
  routineName     Like(UTF8_1K) const options(*varsize);
  parameterObject pointer value options(*nopass);
  formatOptions   int(10) value options(*nopass);
  specific        ind     value options(*nopass);
End-PR;


/// TODO - not migrated !!
// SQL : Call stored procedure (noxDB nodes)
//
// Calls a SQL stored procedure with the passed parameters. The passed
// parameters are either JSON or XML strings or noxDB object trees. Passing
// object trees to the stored procedure lets you use these object trees
// directly in the stored procedure. A passed string will be parsed into
// a new noxDB object tree.
//
// @param (input) Pointer to database connection provided by nox_sqlConnect()
// @param (input) Qualified SQL procedure name
// @param (input) JSON or XML strings or noxDB object tree
// @param (input) JSON or XML strings or noxDB object tree
// @param (input) JSON or XML strings or noxDB object tree
// @param (input) JSON or XML strings or noxDB object tree
// @param (input) JSON or XML strings or noxDB object tree
// @param (input) JSON or XML strings or noxDB object tree
// @param (input) JSON or XML strings or noxDB object tree
// @param (input) JSON or XML strings or noxDB object tree
// @param (input) JSON or XML strings or noxDB object tree
// @param (input) JSON or XML strings or noxDB object tree
// @return <code>*on</code> if an error occured else <code>*off</code>
//
// @info The caller of this procedure needs to take care of freeing the resources
//       of the returned noxDB object tree by calling <em>nox_delete(node)</em>.
///
Dcl-PR nox_sqlCallNode ind extproc(*CWIDEN : 'nox_sqlCallNode');
  pConnection     pointer value;
  procedureName   Like(UTF8_1K) const options(*varsize);
  parm01 pointer value options(*string : *nopass);
  parm02 pointer value options(*string : *nopass);
  parm03 pointer value options(*string : *nopass);
  parm04 pointer value options(*string : *nopass);
  parm05 pointer value options(*string : *nopass);
  parm06 pointer value options(*string : *nopass);
  parm07 pointer value options(*string : *nopass);
  parm08 pointer value options(*string : *nopass);
  parm09 pointer value options(*string : *nopass);
  parm10 pointer value options(*string : *nopass);
End-PR;

///
// SQL : Update row
//
// Executes an UPDATE TABLE where the row is defined as an object tree.
//
// @param (input) Pointer to database connection provided by nox_sqlConnect()
// @param (input) SQL table name
// @param (input) Row data as either object tree or JSON or XML string
// @param (input) SQL WHERE clause (may include template variables like WHERE id = $id)
// @param (input) Input parameter object tree for SQL WHERE clause template variables
//        (f. e. { "id" : 123 } )
// @return <code>*on</code> if an error occured else <code>*off</code>
///
Dcl-PR nox_sqlUpdate Ind extproc(*CWIDEN:'nox_sqlUpdateVC');
  pConnection    pointer value;
  table          Like(UTF8_1K) const options(*varsize);
  row            pointer value;
  where          Like(UTF8) const options(*nopass:*varsize);
  whereParms     pointer value options(*nopass);
End-PR;

///
// SQL : Insert row
//
// Executes an INSERT where the row is defined as an object tree.
//
// @param (input) Pointer to database connection provided by nox_sqlConnect()
// @param (input) SQL table name
// @param (input) Row data as either object tree or JSON or XML string
// @return <code>*on</code> if an error occured else <code>*off</code>
///

Dcl-PR nox_sqlInsert Ind extproc(*CWIDEN:'nox_sqlInsertVC');
  pConnection    pointer value;
  table          Like(UTF8_1K) const options(*varsize);
  row            pointer value;
End-PR;

///
// SQL : Upsert row
//
// Executes an UPDATE TABLE where the row is defined as an object tree if
// the table contains a row matching the passed WHERE clause. If the table
// does not contain any matching row the passed row will be INSERTed into
// the table.
//
// @param (input) Pointer to database connection provided by nox_sqlConnect()
// @param (input) SQL table name
// @param (input) Row data as either object tree or JSON or XML string
// @param (input) Input parameter (don't have to pass anything as it is not needed on INSERT)
// @return <code>*on</code> if an error occured else <code>*off</code>
//
// @info Depending on the WHERE clause more than one row may be updated by
//       this function.
///
Dcl-PR nox_sqlUpsert Ind extproc(*CWIDEN:'nox_sqlUpsertVC');
  pConnection    pointer value;
  table          Like(UTF8_1K) const options(*varsize);
  row            pointer value;
  where          Like(UTF8) const options(*varsize);
  whereParms     pointer value options(*nopass);
End-PR;

///
// SQL : Get last generated id
//
// Returns the last generated id (f. e. id of identity columns).
//
// @param (input) Pointer to database connection provided by nox_sqlConnect()
// @return Last generated id or 0 if there was no INSERT statement previously
//         executed
///
Dcl-PR nox_sqlGetInsertId Int(10) extproc(*CWIDEN:'nox_sqlGetInsertId');
  pConnection    pointer value;
End-PR;

///
// SQL : Get column meta data
//
// Returns an object tree (array) with column meta data. The returned array
// contains one element for each column. This element (object tree) contains
// the following attributes:
// <ul>
//  <li>name : column name</li>
//  <li>datatype : SQL datatype name (like int, varchar, timestamp)</li>
//  <li>sqltype : SQL datatype id (like 4 for int)</li>
//  <li>size : max. number of characters (not bytes)</li>
//  <li>header : column label (column header)</li>
//  <li>text   : column text label. If'text' is set in format option </li>
// </ul>
//
// @param (input) Pointer to database connection provided by nox_sqlConnect()
// @param (input) SQL SELECT statement with the columns to be queried
// @return Object tree (array) with column meta data
//
// @info The caller of this procedure needs to take care of freeing the resources
//       of the returned noxDB object tree by calling <em>nox_delete(node)</em>.
///

Dcl-PR nox_sqlGetMeta Pointer extproc(*CWIDEN:'nox_sqlGetMetaVC');
  pConnection    pointer value;
  sqlstmt        Like(UTF8) const options(*varsize);
End-PR;

///
// SQL : Connect
//
// Returns a connection object to the local database.
//
// @param (input) Options (not supported at the moment)
// @return Connection to local database
///
Dcl-PR nox_sqlConnect Pointer extproc(*CWIDEN: 'nox_sqlConnect');
  parms          Like(UTF8) const options(*nopass:*varsize);
End-PR;

///
// SQL : Disconnect
//
// @param (input) Pointer to database connection provided by nox_sqlConnect()
//
// Disconnects the current database connection.
///
Dcl-PR nox_sqlDisconnect  extproc(*CWIDEN: 'nox_sqlDisconnect');
  pConnection   pointer;
End-PR;

///
// SQL : Get last SQL code
//
// Returns the SQL code for the previous executed statement.
//
// @param (input) Pointer to database connection provided by nox_sqlConnect()
// @return SQL Code or 0 if no SQL statement was previously executed
///
Dcl-PR nox_sqlCode Int(10) extproc(*CWIDEN: 'nox_sqlCode');
    pConnection   pointer value;
End-PR;

///
// SQL : Set trace id
//
// Sets a trace id at the current connection which will be added to the trace
// statements in the trace table.
//
// @param (input) Trace id
///
Dcl-PR nox_TraceSetId  extproc(*CWIDEN : 'nox_TraceSetId');
  traceId        Int(20)    value; // Ccsid of inpur file
End-PR;


/// TODO - not migrated !!
// SQL : Start transaction
//
// Starts a new transaction. If commitment control has not been started yet
// it will be started now. The transaction will end on either commit or
// rollback.
//
// @param (input) Pointer to database connection provided by nox_sqlConnect()
// @return <code>*on</code> if an error occured else <code>*off</code>
//
// @info Transaction Isolation Level (Scope) will be REPEATABLE READ.
///
Dcl-PR nox_sqlStartTransaction ind extproc(*CWIDEN : 'nox_sqlStartTransaction');
    pConnection   pointer value;
End-PR;

/// TODO - not migrated !!
// SQL : Commit
//
// Commits the current transaction.
//
// @param (input) Pointer to database connection provided by nox_sqlConnect()
// @return <code>*on</code> if an error occured else <code>*off</code>
///
Dcl-PR nox_sqlCommit ind extproc(*CWIDEN : 'nox_sqlCommit') ;
    pConnection   pointer value;
End-PR;

/// TODO - not migrated !!
// SQL : Rollback
//
// Rollbacks the current transaction.
//
// @param (input) Pointer to database connection provided by nox_sqlConnect()
// @return <code>*on</code> if an error occured else <code>*off</code>
///
Dcl-PR nox_sqlRollback ind extproc(*CWIDEN : 'nox_sqlRollback');
    pConnection   pointer value;
End-PR;

/// -- Document builder section begin --

///
// Create object node
//
// Create object node - graph builder with name / value pairs
//
// @info The caller of this procedure needs to take care of freeing the resources
//       of the returned noxDB object graph by calling <em>nox_delete(node)</em>.
///
Dcl-PR nox_Object pointer extproc(*CWIDEN : 'nox_Object');
  name00 Like(UTF8_1K) const options(*nopass:*varsize);
  valu00 pointer value options(*nopass:*string);
  name01 Like(UTF8_1K) const options(*nopass:*varsize);
  valu01 pointer value options(*nopass:*string);
  name02 Like(UTF8_1K) const options(*nopass:*varsize);
  valu02 pointer value options(*nopass:*string);
  name03 Like(UTF8_1K) const options(*nopass:*varsize);
  valu03 pointer value options(*nopass:*string);
  name04 Like(UTF8_1K) const options(*nopass:*varsize);
  valu04 pointer value options(*nopass:*string);
  name05 Like(UTF8_1K) const options(*nopass:*varsize);
  valu05 pointer value options(*nopass:*string);
  name06 Like(UTF8_1K) const options(*nopass:*varsize);
  valu06 pointer value options(*nopass:*string);
  name07 Like(UTF8_1K) const options(*nopass:*varsize);
  valu07 pointer value options(*nopass:*string);
  name08 Like(UTF8_1K) const options(*nopass:*varsize);
  valu08 pointer value options(*nopass:*string);
  name09 Like(UTF8_1K) const options(*nopass:*varsize);
  valu09 pointer value options(*nopass:*string);
  name10 Like(UTF8_1K) const options(*nopass:*varsize);
  valu10 pointer value options(*nopass:*string);
  name11 Like(UTF8_1K) const options(*nopass:*varsize);
  valu11 pointer value options(*nopass:*string);
  name12 Like(UTF8_1K) const options(*nopass:*varsize);
  valu12 pointer value options(*nopass:*string);
  name13 Like(UTF8_1K) const options(*nopass:*varsize);
  valu13 pointer value options(*nopass:*string);
  name14 Like(UTF8_1K) const options(*nopass:*varsize);
  valu14 pointer value options(*nopass:*string);
  name15 Like(UTF8_1K) const options(*nopass:*varsize);
  valu15 pointer value options(*nopass:*string);
  name16 Like(UTF8_1K) const options(*nopass:*varsize);
  valu16 pointer value options(*nopass:*string);
  name17 Like(UTF8_1K) const options(*nopass:*varsize);
  valu17 pointer value options(*nopass:*string);
  name18 Like(UTF8_1K) const options(*nopass:*varsize);
  valu18 pointer value options(*nopass:*string);
  name19 Like(UTF8_1K) const options(*nopass:*varsize);
  valu19 pointer value options(*nopass:*string);
  name20 Like(UTF8_1K) const options(*nopass:*varsize);
  valu20 pointer value options(*nopass:*string);
  name21 Like(UTF8_1K) const options(*nopass:*varsize);
  valu21 pointer value options(*nopass:*string);
  name22 Like(UTF8_1K) const options(*nopass:*varsize);
  valu22 pointer value options(*nopass:*string);
  name23 Like(UTF8_1K) const options(*nopass:*varsize);
  valu23 pointer value options(*nopass:*string);
  name24 Like(UTF8_1K) const options(*nopass:*varsize);
  valu24 pointer value options(*nopass:*string);
  name25 Like(UTF8_1K) const options(*nopass:*varsize);
  valu25 pointer value options(*nopass:*string);
  name26 Like(UTF8_1K) const options(*nopass:*varsize);
  valu26 pointer value options(*nopass:*string);
  name27 Like(UTF8_1K) const options(*nopass:*varsize);
  valu27 pointer value options(*nopass:*string);
  name28 Like(UTF8_1K) const options(*nopass:*varsize);
  valu28 pointer value options(*nopass:*string);
  name29 Like(UTF8_1K) const options(*nopass:*varsize);
  valu29 pointer value options(*nopass:*string);

End-PR;

///
// Create array
//
// Creates a new atomic noxDB array node. and fills it with the passed  values
//
// @return New array
//
// @info The caller of this procedure needs to take care of freeing the resources
//       of the returned noxDB object tree by calling <em>nox_delete(node)</em>.
///
Dcl-PR nox_Array pointer extproc(*CWIDEN : 'nox_Array');
  value00 pointer value options(*nopass:*string);
  value01 pointer value options(*nopass:*string);
  value02 pointer value options(*nopass:*string);
  value03 pointer value options(*nopass:*string);
  value04 pointer value options(*nopass:*string);
  value05 pointer value options(*nopass:*string);
  value06 pointer value options(*nopass:*string);
  value07 pointer value options(*nopass:*string);
  value08 pointer value options(*nopass:*string);
  value09 pointer value options(*nopass:*string);
  value10 pointer value options(*nopass:*string);
  value11 pointer value options(*nopass:*string);
  value12 pointer value options(*nopass:*string);
  value13 pointer value options(*nopass:*string);
  value14 pointer value options(*nopass:*string);
  value15 pointer value options(*nopass:*string);
  value16 pointer value options(*nopass:*string);
  value17 pointer value options(*nopass:*string);
  value18 pointer value options(*nopass:*string);
  value19 pointer value options(*nopass:*string);
  value20 pointer value options(*nopass:*string);
  value21 pointer value options(*nopass:*string);
  value22 pointer value options(*nopass:*string);
  value23 pointer value options(*nopass:*string);
  value24 pointer value options(*nopass:*string);
  value25 pointer value options(*nopass:*string);
  value26 pointer value options(*nopass:*string);
  value27 pointer value options(*nopass:*string);
  value28 pointer value options(*nopass:*string);
  value29 pointer value options(*nopass:*string);
End-PR;

/// -- Document builder section begin --

// Need Space arround the nox_OVERLOAD , else the prototype generator will not work
/if defined( nox_OVERLOAD )
///
// Set value
//
// Sets the passed value to the node pointed to by the passed path expression.
// This is an overloaded function and proxies calls to one of the following
// functions depending on the passed parameters.
//
// <ul>
//   <li>nox_setBool</li>
//   <li>nox_setNum</li>
//   <li>nox_setInt</li>
//   <li>nox_setDate</li>
//   <li>nox_setTime</li>
//   <li>nox_setTimestamp</li>
//   <li>nox_setStr</li>
// </ul>
// Note: setBool will have same signature as setStr and setInt will have same
// signature that setNum so they are omitted for now
//
// @param (input) Node
// @param (input) Node path expression
// @param (input) New value
// @return Changed node
///
Dcl-PR nox_set pointer overload (
//  nox_setBool:
    nox_setNum :
//  nox_setInt :
    nox_setDate:
    nox_setTime:
    nox_setTimeStamp:
    nox_setStr
);
/endif





