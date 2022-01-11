**FREE
        // ---------------------------------------------------------------------- *
        // This is the prototype for noxDB - JSON, XML and SQL made easy
        // Use the NOXDB binddir when creating your program and include this
        // prototypes like:

        //     Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
        //     /include 'headers/JSONPARSER.rpgle'

        // Note: Both XMLPARSER and JSONPARSER headers are autogenerated from
        // the NOXDB header. so please do not make any changes the there headerfile

        // ---------------------------------------------------------------------- *
      /if defined( NOX_DEF)
      /eof
      /endif
      /define  NOX_DEF

        // 1M minus length of 4 bytes
        Dcl-S UTF8 varchar(1048572) CCSID(*UTF8) Template;
        Dcl-C UTF8_BOM const(-1208);
        
        // ---------------------------------------------------------------------- *
        // Type of a node:
        // ---------------------------------------------------------------------- *
        Dcl-C NOX_UNKNOWN const(0);
        Dcl-C NOX_OBJECT  const(1);
        Dcl-C NOX_ARRAY   const(2);
        Dcl-C NOX_EVAL    const(3);
        Dcl-C NOX_POINTER_VALUE const(4);
        Dcl-C NOX_VALUE   const(5);
        Dcl-C NOX_ROOT    const(6);
        Dcl-C NOX_LITERAL const(16);
        Dcl-C NOX_OBJLINK const(17);
        Dcl-C NOX_OBJREPLACE const(18);
        Dcl-C NOX_OBJCOPY const(18);
        Dcl-C NOX_BY_CONTEXT const(19);
        Dcl-C NOX_OBJMOVE const(2048);

        // Node reference location for nodeCopy / nodeAdd etc.
        Dcl-C NOX_FIRST_CHILD const(1);
        Dcl-C NOX_LAST_CHILD const(2);
        Dcl-C NOX_BEFORE_SIBLING const(3);
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

        // ---------------------------------------------------------------------- 
        // Returns node to the nox_object tree
        Dcl-PR nox_ParseFile Pointer extproc(*CWIDEN:'nox_ParseFile');
          // File to parse
          FileName       pointer value  options(*string);
        End-PR;

        // Returns node nox_object tree
        Dcl-PR nox_ParseString Pointer extproc(*CWIDEN:'nox_ParseStringVC');
          // String to parse
          String         Like(UTF8) const options(*varsize);
        End-PR;

        // Set , or . for numeri decimal point
        Dcl-PR nox_setDecPoint  extproc(*CWIDEN : 'nox_SetDecPoint');
          // decimal point char
          decPoint       char(1) const ccsid(*utf8);
        End-PR;

        // Bool true if errors occures
        Dcl-PR nox_Error Ind extproc(*CWIDEN:'nox_Error');
          // nox_Object  node
          pNode          Pointer    value;
        End-PR;

        // Return error description
        // NL-OK 
        Dcl-PR nox_Message varchar(1024) extproc(*CWIDEN:'nox_MessageVC');
          // nox_Object
          pNode          Pointer    value;
        End-PR;

        // Without parameters you will get the last internal error
        // Otherwise it will format an error object
        // NL-OK 
        Dcl-PR nox_GetMessageObject Pointer // Return error description
                                   extproc(*CWIDEN:'nox_GetMessageObject');
          MessageId      Like(UTF8) const options(*nopass:*varsize);
          MessageData    Like(UTF8) const options(*nopass:*varsize);
        End-PR;

        // simple courtesy function to return a {"success":true} object
        // Return success:true object
        Dcl-PR nox_SuccessTrue Pointer extproc(*CWIDEN:'nox_SuccessTrue');
          MessageId      Like(UTF8) const options(*nopass:*varsize);
          MessageData    Like(UTF8) const options(*nopass:*varsize);
        End-PR;

        // Returns pointer to node
        // NL-OK
        Dcl-PR nox_Locate Pointer extproc(*CWIDEN : 'nox_GetNodeVC');
          // Pointer to tree or node
          pNode          Pointer    value;
          // location expression
          Expression     Like(UTF8) const options(*varsize);
        End-PR;

        // Returns pointer to node
        Dcl-PR nox_LocateOrCreate Pointer extproc(*CWIDEN : 'nox_GetOrCreateNodeVC');
          // Pointer to tree or node
          pNode          Pointer    value;
          // location expression
          Expression     Like(UTF8) const options(*varsize);
        End-PR;

        // Returns 'ON' if node exists
        Dcl-PR nox_Has Ind extproc(*CWIDEN : 'nox_HasVC');
          // Pointer to tree or node
          pNode          Pointer    value;
          // Path to node
          NodeName       Like(UTF8) const options(*varsize);
        End-PR;

        // Returns 'ON' if node exists and has value <> 0 and <> false
        Dcl-PR nox_isTrue Ind extproc(*CWIDEN : 'nox_IsTrueVC');
          // Pointer to tree or node
          pNode          Pointer    value;
          // Path to node
          NodeName       Like(UTF8) const options(*varsize);
        End-PR;

        // Returns 'ON' if node exists and has value <> 0 and <> false
        // This is an alias from isTrue 
        Dcl-PR nox_getBool  Ind extproc(*CWIDEN : 'nox_IsTrueVC');
          // Pointer to tree or node
          pNode          Pointer    value;
          // Path to node
          NodeName       Like(UTF8) const options(*varsize);
        End-PR;

        // Returns 'ON' if node exists and has <> 0
        Dcl-PR nox_isNull Ind extproc(*CWIDEN : 'nox_IsNullVC');
          // Pointer to tree or node
          pNode          Pointer    value;
          // Path to node
          NodeName       Like(UTF8) const options(*varsize);
        End-PR;

        // Returns 'ON' if it is a valid node
        Dcl-PR nox_isNode Ind extproc(*CWIDEN : 'nox_isNode');
          // a.k.a. false for strings
          pNode          Pointer    value;
        End-PR;

        // renames the node name
        Dcl-PR nox_NodeRename Ind extproc(*CWIDEN : 'nox_NodeRenameVC');
          // Pointer to tree or node
          pNode          Pointer    value;
          // Path to node
          NodeName       Like(UTF8) const options(*varsize);
        End-PR;

        // Returns pointer to next sibling (elem)
        Dcl-PR nox_GetNext Pointer extproc(*CWIDEN : 'nox_GetNodeNext');
          // Pointer to current node (elem)
          pNode          Pointer    value;
        End-PR;

        // Returns pointer to first child (elem)
        Dcl-PR nox_GetChild Pointer extproc(*CWIDEN : 'nox_GetNodeChild');
          // Pointer to current node (elem)
          pNode          Pointer    value;
        End-PR;

        // Returns pointer to parent node
        Dcl-PR nox_GetParent Pointer extproc(*CWIDEN : 'nox_GetNodeParent');
          // Pointer to current node (elem)
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
          Expresion      Like(UTF8) const options(*varsize);
        End-PR;

        Dcl-PR nox_SetEval pointer extproc(*CWIDEN:'nox_SetEvalByNameVC');
          pNode          Pointer    value;
          Expresion      Like(UTF8) const options(*varsize);
          Value          Like(UTF8) const options(*varsize);
        End-PR;

        Dcl-PR nox_SetStr Pointer extproc(*CWIDEN: 'nox_SetStrByNameVC');
          // Pointer to nox_ tree
          pNode          Pointer    value;
          // Path locations to node or attributes
          Expresion      Like(UTF8) const options(*varsize);
          // New value to set / pointer to object
          Value          Like(UTF8) const options(*varsize);
        End-PR;

        Dcl-PR nox_SetInt Pointer extproc(*CWIDEN: 'nox_SetIntByNameVC');
          // Pointer to nox_ tree
          pNode          Pointer    value;
          // Path locations to node or attributes
          Expresion      Like(UTF8) const options(*varsize);
          // New value to set / pointer to object
          Value          Int(10)    value;
        End-PR;

        Dcl-PR nox_SetDate Pointer extproc(*CWIDEN: 'nox_SetDateByNameVC');
          // Pointer to nox_ tree
          pNode          Pointer    value;
          // Path locations to node or attributes
          Expresion      Like(UTF8) const options(*varsize);
          // New value to set / pointer to object
          Value          date    value;
        End-PR;


        Dcl-PR nox_SetNum Pointer extproc(*CWIDEN: 'nox_SetDecByNameVC');
          // Pointer to nox_ tree
          pNode          Pointer    value;
          // Path locations to node or attributes
          Expresion      Like(UTF8) const options(*varsize);
          // New value to set / pointer to object
          Value          Packed(30:15) value;
        End-PR;

        Dcl-PR nox_SetBool Pointer extproc(*CWIDEN: 'nox_SetBoolByNameVC');
          // Pointer to nox_ tree
          pNode          Pointer    value;
          // Path locations to node or attributes
          Expresion      Like(UTF8) const options(*varsize);
          // New value to set / pointer to object
          Value          Ind        value;
        End-PR;

        Dcl-PR nox_SetPtr Pointer extproc(*CWIDEN: 'nox_SetPtrByNameVC');
          // Pointer to nox_ tree
          pNode          Pointer    value;
          // Path locations to node or attributes
          Expresion      Like(UTF8) const options(*varsize);
          // Pointer to anything - You do the cleanup
          Value          Pointer    value;
          // *ON=String escape, *OFF=If literals
          isString       Ind        value options(*nopass);
        End-PR;

        Dcl-PR nox_SetProcPtr Pointer extproc(*CWIDEN: 'nox_SetPtrByNameVC');
          pNode          Pointer    value; // Pointer to nox_ tree
          // Path locations to node or attributes
          Expresion      Like(UTF8) const options(*varsize);
          Proc           Pointer(*Proc); // Pointer to a procedure
        End-PR;

        Dcl-PR nox_GetValueStr Like(UTF8) 
                              extproc(*CWIDEN : 'nox_GetNodeValueVC');
          // Pointer to node
          pNode          Pointer    value;
          // If not found - default value
          Defaultvalue   Like(UTF8) const options(*nopass:*varsize);
        End-PR;

        Dcl-PR nox_GetValueNum Packed(30:15)     
                              extproc(*CWIDEN : 'nox_GetNodeValueNum');
          // Pointer to node
          pNode          Pointer    value;
          // If not found - default value
          Defaultvalue   Packed(30:15) value options(*NOPASS);
        End-PR;

        Dcl-PR nox_GetValueInt Int(20) extproc(*CWIDEN : 'nox_GetNodeValueInt');
          pNode          Pointer    value; // Pointer to node
          // If not found - default value
          Defaultvalue   Int(20)    value options(*NOPASS);
        End-PR;

        Dcl-PR nox_GetValuePtr Pointer extproc(*CWIDEN : 'nox_GetNodeValuePtr');
          // Pointer to node
          pNode          Pointer    value;
          // If not found - default value
          Defaultvalue   Like(UTF8) const options(*nopass:*varsize);
        End-PR;

        Dcl-PR nox_GetName Like(UTF8) 
                          extproc(*CWIDEN : 'nox_GetNodeNameVC');
          // Pointer to node
          pNode          Pointer    value;
        End-PR;

        Dcl-PR nox_GetNameAsPath Like(UTF8)
                                extproc(*CWIDEN : 'nox_GetNodeNameAsPath');
          // Pointer to node
          pNode          Pointer    value;
          // Delimiter like - or . or / or \
          Delimiter      Char(1)    value CCSID(*UTF8);
        End-PR;

        // * Refer to node type above
        Dcl-PR nox_NodeType Int(5) extproc(*CWIDEN : 'nox_GetNodeType');
          // Pointer to nox_ tree to receive format
          pNode          Pointer    value;
        End-PR;

      // Get string by expresion
      //  /object/array[123]/name
      //  .object.array[123].name
      // NL-OK
        Dcl-PR nox_GetStr Like(UTF8) rtnparm extproc(*CWIDEN : 'nox_GetValueVC');
          // Pointer to relative node
          pNode          Pointer    value;
          // Locations expression to node
          Expression     Like(UTF8) const options(*nopass:*varsize);
          // If not found - default value
          Defaultvalue   Like(UTF8) const options(*nopass:*varsize);
        End-PR;

      //  will join all subsequent array nodes into one resulting string
        Dcl-PR nox_GetStrJoin Like(UTF8) 
                             extproc(*CWIDEN : 'nox_GetStrJoinVC');
          // Pointer to relative node
          pNode          Pointer    value;
          // Locations expression to node
          Expression     Like(UTF8) const options(*nopass:*varsize);
          // If not found - default value
          Defaultvalue   Like(UTF8) const options(*nopass:*varsize);
        End-PR;

      // Get number by expresion like:
      //  /object/array[123]/name
      //  .object.array[123].name
      // NL-OK 
        Dcl-PR nox_GetNum Packed(30:15) extproc(*CWIDEN : 'nox_GetValueNumVC');
          // Pointer to relative node
          pNode          Pointer    value;
          // Locations expression to node
          Expression     Like(UTF8) const  options(*nopass:*varsize);
          // If not found - default value
          Defaultvalue   Packed(30:15) value options(*nopass);
        End-PR;

        Dcl-PR nox_GetInt Int(20) extproc(*CWIDEN : 'nox_GetValueIntVC');
          // Pointer to relative node
          pNode          Pointer    value;
          // Locations expression to node
          Expression     Like(UTF8) const options(*nopass:*varsize);
          // If not found - default value
          Defaultvalue   Int(20)    value options(*nopass);
        End-PR;

        Dcl-PR nox_GetDate date  extproc(*CWIDEN : 'nox_GetValueDateVC');
          // Pointer to relative node
          pNode          Pointer    value;
          // Locations expression to node
          Expression     Like(UTF8) const options(*nopass:*varsize);
          // If not found - default value
          Defaultvalue   date   value options(*nopass);
        End-PR;

        Dcl-PR nox_CopyValue Pointer extproc(*CWIDEN : 'nox_CopyValueVC');
          // destination node
          pDest          Pointer    value;
          // destiantion name (or *NULL or '')
          destName       Like(UTF8) const options(*varsize);
          // source node
          pSource        Pointer    value;
          // source name (or omit if object)
          sourceName     Like(UTF8) const options(*varsize:*nopass);
        End-PR;


        // returns the new node
        Dcl-PR nox_NodeAdd Pointer extproc(*CWIDEN : 'nox_NodeAddVC');
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
        
        // Clone a node and insert 
        Dcl-PR nox_NodeCopy extproc(*CWIDEN : 'nox_NodeCopy');
          //node. Retrive from Locate()
          pRootNode      Pointer    value;
          //node. Retrive from Locate()
          pNewChild      Pointer    value;
          //Reference location to where it arrive
          RefLocation    Int(10)    value;
        End-PR;

        Dcl-PR nox_NodeClone Pointer extproc(*CWIDEN : 'nox_NodeClone');
          // node. Retrive from Locate()
          pSource        Pointer    value;
        End-PR;

        // Delete and set ref pointer to zero:
        Dcl-PR nox_Delete extproc(*CWIDEN : 'nox_Delete');
          // element. Retrive from Locate()
          pRootNode      Pointer;
        End-PR;


        // Unlink the note from its previous and promote it as a new root node
        Dcl-PR nox_NodeUnlink Pointer extproc(*CWIDEN : 'nox_NodeUnlink');
          // Targenode. Retrive from Locate(
          pNode          Pointer    value;
        End-PR;

        Dcl-PR nox_NodeSanitize extproc(*CWIDEN : 'nox_NodeSanitize');
          // node. Retrive from Locate()
          pRootNode      Pointer    value;
        End-PR;

        // CheckSum of all names and values
        Dcl-PR nox_NodeCheckSum Uns(10) extproc(*CWIDEN : 'nox_NodeCheckSum');
          pRootNode      Pointer    value; // node. Retrive from Locate()
        End-PR;
     
        // returns the new node
        Dcl-PR nox_NewObject Pointer extproc(*CWIDEN : 'nox_NewObject');
        End-PR;

      // Array functions
        // returns the new node
        Dcl-PR nox_NewArray Pointer extproc(*CWIDEN : 'nox_NewArray');
        End-PR;

        // returns the new node added to the end of
        Dcl-PR nox_ArrayPush Pointer extproc(*CWIDEN : 'nox_ArrayPush');
          // Destination. Retrive from Locate()
          pDestArray     Pointer    value;
          // source node to append
          pSourceNode    Pointer   value;
          // 0=(Dft) Unlink and move, 1=copy a clone
          copy           Uns(5)     value options(*nopass);
        End-PR;

        // Following constants used by nox_ArrayPush:copy
        Dcl-C NOX_MOVE_UNLINK const(0);
        Dcl-C NOX_COPY_CLONE const(1);

        // returns the new node added to the end of
        Dcl-PR nox_ArrayAppend Pointer extproc(*CWIDEN :'nox_ArrayAppend');
          // Destination. Retrive from Locate()
          pDestArray     Pointer    value;
          // source node to append
          pSourceNode    Pointer    value;
          // 0=(Dft) Unlink and move, 1=copy a clone
          copy           Uns(5)     value options(*nopass); 
        End-PR;

        // returns the new array fro source array
        Dcl-PR nox_ArraySlice Pointer extproc(*CWIDEN : 'nox_ArraySlice' );
          // source node 
          pSourceNode    Pointer    value;
          // From entry ( 1=First)
          from           Int(10)    value;
          // To and includ   (-1 = Until end)
          to             Int(10)    value;
          // 0=(Dft) Unlink and move, 1=copy a clone
          copy           Uns(5)     value options(*nopass);
        End-PR;
     
        // returns the new node added to the end of
        Dcl-PR nox_ArraySort Pointer extproc(*CWIDEN : 'nox_ArraySortVC');
          // Destination. Retrive from Locate()
          pArray         Pointer    value;
          // nodenames if any in subobject to comapre
          pkeyNames      Like(UTF8) const ;
          // 0=(Dft) use json numerics, 1=Use locale
          options        uns(5)     value options(*nopass);
        End-PR;

        Dcl-C NOX_USE_LOCALE const(1);
        
        // returns the first node with expr value
        Dcl-PR nox_LookupValue Pointer extproc(*CWIDEN : 'nox_lookupValueVC');
          // Array/ obj to search
          pArray         Pointer    value;
          // What to search for
          expr           Like(UTF8) const options(*varsize);
          // 0=(Dft) Same case, 1=ignore case
          ignoreCase     Uns(5)     value options(*nopass);
        End-PR;

        // Following constants used by nox_LookupValue:ignoreCase
        Dcl-C NOX_SAME_CASE const(0);
        Dcl-C NOX_IGNORE_CASE const(1);

        // returns numer of element in array or obj
        Dcl-PR nox_GetLength Int(10) extproc(*CWIDEN : 'nox_getLength'  );
          // Array to count length
          pArray         Pointer    value;
        End-PR;

        // Following constants used by nox_Merge:Type
        Dcl-C NOX_DONTREPLACE const(0);
        Dcl-C NOX_REPLACE const(1);

        // returns the new node
        Dcl-PR nox_MergeObjects Pointer extproc(*CWIDEN : 'nox_MergeObjects');
          // Destination. Retrive from Locate()
          pDestObj       Pointer    value;
          // Source tree  Retrive from Locate()
          pSourceObj     Pointer    value;
          // NOX_DONTREPLACE or NOX_OBJREPLACE
          Type           Uns(5)     value;
        End-PR;

        // returns the source node
        Dcl-PR nox_MoveObjectInto Pointer extproc(*CWIDEN : 'nox_NodeMoveIntoVC');
          // Destination. Retrive from Locate()
          pDestObj       Pointer    value;
          Name           Like(UTF8) const options(*varsize);
          // Source tree  Retrive from Locate()
          pSourceObj     Pointer    value;
        End-PR;

        Dcl-PR nox_Dump  extproc(*CWIDEN : 'nox_Dump');
          // Pointer to tree
          pNode          Pointer    value;
        End-PR;


        // **  JSON renderes ***
        Dcl-PR nox_WriteJsonStmf  extproc(*CWIDEN : 'nox_WriteJsonStmf');
          // node. Retrive from Locate()
          pNode          Pointer    value;
          // Name of output stream file
          FileName       Pointer    value  options(*string);
          // Ccsid of output file
          Ccsid          Int(10)    value;
          Trim           Ind        value;
          // Extra options
          Options        Pointer    value  options(*nopass:*string);
        End-PR;

        Dcl-PR nox_AsJsonText Like(UTF8) rtnparm extproc(*CWIDEN : 'nox_AsJsonText');
          // node. Retrive from Locate()
          pNode          Pointer    value;
        End-PR;

        Dcl-PR nox_AsJsonTextMem Uns(10) extproc(*CWIDEN : 'nox_AsJsonTextMem');
          // node. Retrive from Locate()
          pNode          Pointer    value;
          // pointer to any memory buffer
          pBuffer        Pointer    value;
          // Max number of bytes in buffer %size()
          maxSize        Uns(10)    value options(*nopass);
        End-PR;

        // **  XML  renderes ***
        Dcl-PR nox_WriteXmlStmf  extproc(*CWIDEN : 'nox_WriteXmlStmf');
          // node. Retrive from Locate()
          pNode          Pointer    value;
          // Name of output stream file
          FileName       Pointer    value  options(*string);
          // Ccsid of output file
          Ccsid          Int(10)    value options(*nopass);
          Trim           Ind        value options(*nopass);
          // Extra options
          Options        Pointer    value  options(*nopass:*string);
        End-PR;

        Dcl-PR nox_AsXmlText Like(UTF8) rtnparm extproc(*CWIDEN : 'nox_AsXmlText');
          // node. Retrive from Locate()
          pNode          Pointer    value;
        End-PR;

        Dcl-PR nox_AsXmlTextMem Uns(10) extproc(*CWIDEN : 'nox_AsXmlTextMem');
          // node. Retrive from Locate()
          pNode          Pointer    value;
          // pointer to any memory buffer
          pBuffer        Pointer    value;
        End-PR;

        // Return a streamer object to be used in own serialisers 
        Dcl-PR nox_Stream pointer extproc(*CWIDEN : 'nox_Stream');
          // node. Retrive from Locate()
          pNode          Pointer    value;
        End-PR;

        // **  CSV  renderes ***
        Dcl-PR nox_WriteCsvStmf  extproc(*CWIDEN : 'nox_WriteCsvStmf');
          // node. Retrive from Locate()
          pNode          Pointer    value;
          // Name of output stream file
          FileName       Pointer    value  options(*string);
          // Ccsid of output file
          Ccsid          Int(10)    value;
          // *ON=Remove inter blanks
          Trim           Ind        value;
          // Options: ';.' for separator and dec
          Options        Pointer    value  options(*nopass:*string);
        End-PR;

        // Iterators: First use the set the use forEach
        Dcl-DS nox_Iterator  based(prototype_only) qualified;
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
          // Pointer to temp array of elms
          listArr        Pointer;
          // Set  this to *ON to teminate loop
          break          Ind;
          filler         Char(64);
        End-DS;

        Dcl-PR nox_setIterator  likeds( nox_Iterator) extproc(*CWIDEN : 'nox_SetIteratorVC');
          // node. Retrive from Locate()
          pNode          Pointer    value;
          // Optional - path to node
          path           Like(UTF8) const options(*nopass:*varsize);
        End-PR;

        Dcl-PR nox_setRecursiveIterator  likeds( nox_Iterator) 
                                        extproc(*CWIDEN : 
                                        'nox_SetRecursiveIteratorVC');
          // node. Retrive from Locate()
          pNode          Pointer    value;
          // Optional - path to node
          path           Like(UTF8) const options(*nopass:*varsize);
        End-PR;

        // Iterator Structure
        Dcl-PR nox_forEach Ind extproc(*CWIDEN : 'nox_ForEach');
          iterator                  likeds( nox_Iterator);
        End-PR;

        // For attributes ( Used mostly in XML )
        Dcl-PR nox_GetNodeAttrValue Like(UTF8) rtnparm extproc(*CWIDEN : 'nox_GetNodeAttrValueVC');
          // Pointer to exsiting element
          pNode          Pointer    value;
          // Attribute Name
          AttrName       Like(UTF8) const options(*varsize);
          // If not found - default value
          Defaultvalue   Like(UTF8) const options(*nopass:*varsize);
        End-PR;

        Dcl-PR nox_SetNodeAttrValue extproc(*CWIDEN : 'nox_SetNodeAttrValueVC');
          // Pointer to exsiting element
          pNode          Pointer    value;
          // Attribute name
          AttrName       Like(UTF8) const options(*varsize);
          // New value
          Value          Like(UTF8) const options(*varsize);
        End-PR;

        Dcl-PR nox_GetAttrValue Like(UTF8) rtnparm 
                               extproc(*CWIDEN : 'nox_GetAttrValueVC');
          // Pointer Attribute
          pAttr          Pointer    value;
          // If not found - default value
          Defaultvalue   Like(UTF8) const options(*nopass:*varsize);
        End-PR;

        Dcl-PR nox_SetAttrValue extproc(*CWIDEN : 'nox_SetAttrValue');
          // Pointer Attribute
          pAttr          Pointer    value;
          // New value
          AttrName       Like(UTF8) const options(*varsize);
          // Default value
          Value          Like(UTF8) const options(*varsize);
        End-PR;

        // Returns pointer to attribute list
        Dcl-PR nox_GetAttrFirst Pointer extproc(*CWIDEN : 'nox_GetAttrFirst');
          // Pointer to element
          pElem          Pointer    value;
        End-PR;

        // Returns pointer to attribute list
        Dcl-PR nox_GetAttrNext Pointer extproc(*CWIDEN : 'nox_GetAttrNext');
          // Pointer to attribute list
          pAttr          Pointer    value;
        End-PR;

        Dcl-PR nox_GetAttrName Like(UTF8) rtnparm
                              extproc(*CWIDEN : 'nox_GetAttrNameVC');
          // Pointer to attribute list
          pAttr          Pointer    value;
        End-PR;

      // Clear the contents of an array or object / delete all children
        Dcl-PR nox_Clear  extproc(*CWIDEN : 'nox_Clear');
          pNode          Pointer    value; // Pointer to tree node
        End-PR;

      // Close all nodes in this tree - also parent and siblings
        Dcl-PR nox_Close  extproc(*CWIDEN : 'nox_Close');
          // Pointer to tree node
          pNode          Pointer  ;
        End-PR;
      // Detect if you have a memry leak: call this when you have closed everything at i will return false
        Dcl-PR nox_MemLeak Ind extproc(*CWIDEN : 'nox_MemLeak');
        End-PR;

      // Print memory report
        Dcl-PR nox_MemStat  extproc(*CWIDEN : 'nox_MemStat');
        End-PR;

      // retune number of bytest used
        Dcl-PR nox_MemUse Uns(20) extproc(*CWIDEN : 'nox_MemUse');
        End-PR;

      // Maintain at list of index numbers to database CLOB/BLOB fields since pointers can not be shared in SQL
        // Returns *ON if found
        Dcl-PR nox_mapIx Ind extproc(*CWIDEN:'nox_MapIx' );
          // pointer to node pointer
          ppNode         Pointer;
          // index of pointer
          Index          Uns(10)    value;
        End-PR;


      // Returns a JSON object from a REST call
        Dcl-PR nox_httpRequest Pointer extproc(*CWIDEN:'nox_httpRequest');
          // Full URL to the resource
          url            Like(UTF8) const options(*varsize);
          // json object or string
          pReqNode       pointer value;
          // extra CURL options
          options        Like(UTF8) const options(*nopass:*varsize); 
        End-PR;


      // ------------------------------------------------------------------------
      // SQL interface:
      // Note: When SQL functions returns *NULL, then use  the nox_Message() 
      // to retrive the messages text. also the getSqlCode() can be usefull
      // ------------------------------------------------------------------------

      // If options need - then it has to be first call made.
      // NOTE: If a pConnection pointer is provided, it will be updated with the conection
        Dcl-PR nox_sqlSetOptions  extproc(*CWIDEN: 'nox_sqlSetOptions');
          // Pointer to database connection provided by nox_sqlConnect()
          pConnection    pointer value;
          // json object with options ( see sample)
          parms          Like(UTF8) const options(*nopass:*varsize);
        End-PR;

      // returns a object node with one resulting row for the SQL statment
        // Returns one SQL row as jx Obejct
        Dcl-PR nox_sqlResultRow Pointer extproc(*CWIDEN: 'nox_sqlResultRowVC');
          // Pointer to database connection provided by nox_sqlConnect()
          pConnection    pointer value;
          // SQL statement to run
          sqlStmt        Like(UTF8) const options(*varsize);
          // json object template
          parms          Like(UTF8) const options(*nopass:*varsize);
          // Starttin row
          start          int(10)    value options(*nopass); 
        End-PR;

      // returns an array (or object with array) of resulting rows for the SQL statment
        // Returns SQL rows as jx Obejct
        Dcl-PR nox_sqlResultSet Pointer extproc(*CWIDEN: 'nox_sqlResultSetVC');
          // Pointer to database connection provided by nox_sqlConnect()
          pConnection    pointer value;
          // SQL statement to run
          sqlStmt        Like(UTF8) const options(*varsize);
          // From row; 1=First
          start          Int(10)    value options(*nopass);
          // max number of rows; NOX_ALLROWS=all
          limit          Int(10)    value options(*nopass);
          // resultset format:
          format         Int(10)    value options(*nopass);
          // json object template
          parms          Like(UTF8) const options(*nopass:*varsize);
        End-PR;

       
        Dcl-C NOX_ALLROWS const(-1);

        // Following constants used by nox_sqlResultSet:format
        // + An array with each row as an object
        Dcl-C NOX_ROWARRAY const(0);
        // + Metaobject: rows, fields
        Dcl-C NOX_META    const(1);
        // + Columns info
        Dcl-C NOX_FIELDS  const(2);
        // + Count all rows in the resultset
        // ( Pricy so awoid it !! )
        Dcl-C NOX_TOTALROWS const(4);
        // + Uppercase column names
        Dcl-C NOX_UPPERCASE const(8);

        // + Appoximate number of rows..
        //  ( unpresise but cheap !! prefered  )
        Dcl-C NOX_APPROXIMATE_TOTALROWS const(16); 
     


      // SQL cursor processing
        // Returns handle to sql statement
        Dcl-PR nox_sqlOpen Pointer extproc(*CWIDEN:'nox_sqlOpenVC'  );
          // Pointer to database connection provided by nox_sqlConnect()
          pConnection    pointer value;
          // SQL statement to run
          sqlStmt        Like(UTF8) const options(*varsize);
          // json object template
          parms          pointer value options(*nopass:*string);
        End-PR;

      // Fetch next from from that open sql handle, starting from rowNumer. 1=First row
        // Returns a row object (or *NULL if EOF)
        Dcl-PR nox_sqlFetchRelative Pointer 
                                   extproc(*CWIDEN: 'nox_sqlFetchRelative');
          // sql statement handle ( from sqlOpen)
          pSqlHndl       Pointer    value;
          // row from where to start 1=First
          fromRow        Int(10)    value;
        End-PR;

      // Fetch next from from that open sql handle
        // Returns a row object (or *NULL if EOF)
        Dcl-PR nox_sqlFetchNext Pointer extproc(*CWIDEN:'nox_sqlFetchNext');
          // sql statement handle ( from sqlOpen)
          pSqlHndl       Pointer    value;
        End-PR;

      // Number of columns in result set ( -1 if error)
        // Returns number of columns
        Dcl-PR nox_sqlColumns Int(10) extproc(*CWIDEN:'nox_sqlColumns');
          // sql statement handle ( from sqlOpen)
          pSqlHndl       Pointer    value;
        End-PR;

      // Number of rows  in result set ( -1 if error)
      // Note: This will run a hidden "select count(*)" which might be a little pricy
        // Returns number of rows
        Dcl-PR nox_sqlRows Int(10) extproc(*CWIDEN:'nox_sqlRows');
          // sql statement handle ( from sqlOpen)
          pSqlHndl       Pointer    value;
        End-PR;

      // Always colse the cursor after use, to release resources
        Dcl-PR nox_sqlClose  extproc(*CWIDEN:'nox_sqlClose');
          // sql statement handle ( from sqlOpen)
          pSqlHndl       Pointer;
        End-PR;

      // Execute any SQL statement not involving a cursor
        // Returns *ON if error
        Dcl-PR nox_sqlExec Ind extproc(*CWIDEN:'nox_sqlExecVC'  );
          // Pointer to database connection provided by nox_sqlConnect()
          pConnection   pointer value;
          // SQL statement to run (template)
          sqlStmt        Like(UTF8) const options(*varsize);
          // json object template data
          parms          Like(UTF8) const options(*nopass:*varsize);
        End-PR;

      // Execute an update table where the row is defined as a json object
        // Returns *ON if error
        Dcl-PR nox_sqlUpdate Ind extproc(*CWIDEN:'nox_sqlUpdateVC');
          // Pointer to database connection provided by nox_sqlConnect()
          pConnection    pointer value;
          // table name
          table          Like(UTF8) const options(*varsize);
          // json object: {a:123,b:"value"}
          row            pointer value;
          // where clause : 'where myKey=$key'
          where          Like(UTF8) const options(*nopass:*varsize);
          // where parameters: { key:777}
          whereParms     pointer value options(*nopass);
        End-PR;

        // Returns *ON if error
        Dcl-PR nox_sqlInsert Ind extproc(*CWIDEN:'nox_sqlInsertVC');
          // Pointer to database connection provided by nox_sqlConnect()
          pConnection    pointer value;
          // table name
          table          Like(UTF8) const options(*varsize);
          // json object: {a:123,b:"value"}
          row            pointer value;
          // extra parms
          parms          Like(UTF8) const options(*nopass:*varsize);
        End-PR;

        // Returns *ON if error
        Dcl-PR nox_sqlUpsert Ind extproc(*CWIDEN:'nox_sqlUpsertVC');
          // Pointer to database connection provided by nox_sqlConnect()
          pConnection    pointer value;
          // table name
          table          Like(UTF8) const options(*varsize);
          // json object: {a:123,b:"value"}
          row            pointer value;
          // where clause : 'where myKey=$key'
          where          Like(UTF8) const options(*varsize);
          // where parameters: { key:777}
          whereParms     pointer value options(*nopass);
        End-PR;

        // Returns id of last insert
        Dcl-PR nox_sqlGetInsertId Int(10) extproc(*CWIDEN:'nox_sqlGetInsertId');
          // Pointer to database connection provided by nox_sqlConnect()
          pConnection    pointer value;
        End-PR;

        // Returns array of column info
        Dcl-PR nox_sqlGetMeta Pointer extproc(*CWIDEN:'nox_sqlGetMetaVC');
          // Pointer to database connection provided by nox_sqlConnect()
          pConnection    pointer value;
          sqlstmt        Like(UTF8) const options(*varsize);
        End-PR;

      // Return pointer to database connection. No options => will be default local database
        Dcl-PR nox_sqlConnect Pointer extproc(*CWIDEN: 'nox_sqlConnect');
          // json object or string with options
          parms          Like(UTF8) const options(*nopass:*varsize);
        End-PR;

      // Return pointer to database connection. No options => will be default local database
        Dcl-PR nox_sqlDisconnect  extproc(*CWIDEN: 'nox_sqlDisconnect');
           pConnection   pointer;
        End-PR;

      // Return sql code for previous statement
        Dcl-PR nox_sqlCode Int(10) extproc(*CWIDEN: 'nox_sqlCode');
           pConnection   pointer value;
        End-PR;

      // when the dataarea SQLTRACE is set, your SQL statements 
      // are logged into SQLTRACE table.
      // you can supply an exta eye-catch wariable :trcid
        Dcl-PR nox_traceSetId  extproc(*CWIDEN : 'nox_traceSetId');
          traceId        Int(20)    value; // Ccsid of inpur file
        End-PR;


  


     
   