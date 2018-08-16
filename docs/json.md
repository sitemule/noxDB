# JSON Functionality

This page documents the JSON functionality available in noxDB. Header file: `headers/JSONPARSER.rpgle`.

---

## json_ParseFile

```
Pointer json_ParseFile( String path : [String options] )
```

##### Parameters

1. Path relavtive to the current directory.
2. Options for the parser.

Returns Pointer to created node.

---

## json_ParseString

```
Pointer json_ParseString (String json : [String options])
```

#### Parameters

1. JSON document string.
2. Options for the parser.

Returns Pointer to created node.

---

## json_WriteJsonStmf

```
void json_WriteJsonStmf( Pointer node : String filepath : Int(10) ccsid : Ind trim : [String options] )
```

#### Parameters

1. Pointer to existing node.
2. File in which to write the JSON to.
3. CCSID of the file (`1208` is always a good option)
4. Trim down the JSON in the output. 
5. Options for the generator

---

## json_AsJsonText

```
Varchar(32767) json_AsJsonText( Pointer node )
```

#### Parameters

1. Pointer to existing node. Usually the node which is at the top of the document.

---

## json_Error

```
Ind json_Error( Pointer node )
```

##### Parameters

1. Pointer to node created by another JSON function.

Returns `*ON` if there was an error.

##### Example

```
pJson = json_ParseFile('./test/documents/simple.json');

If json_Error(pJson) ;
  //Do thing
Endif;

json_Close(pJson);
```

---

## json_Message

```
Varchar(1024) json_Message( Pointer node )
```

#### Parameters

1. Pointer to node created by other another JSON function.

Returns error message create by another JSON function.

---

## json_Locate

```
Pointer json_Locate( Pointer node : String nodepath )
```

#### Parameters

1. Pointer to node created by other another JSON function.
2. Document path which points to a node.

Returns Pointer to chosen document node.

#### Example

```
pJson = Json_ParseFile ('./test/documents/simple.json');

pNode = Json_Locate(pJson: '/price');
price = Json_GetNum(pNode);
```

```json
{ 
	"price": 1234,
	"text" : "System & Method",
	"anObject" : {
		"country" : "Denmark"
	}
}
```

---

## json_LocateOrCreate

Similar to `json_Locate`, but if the node does not exist, it will be created.

```
Pointer json_LocateOrCreate( Pointer node : String nodepath )
```

#### Parameters

1. Pointer to node created by other another JSON function.
2. Document path which points to a node.

Returns Pointer to chosen document node.

#### Example

```
pObj = json_newObject();
pA   = json_locateOrCreate(pObj : 'aValue');
pA2  = json_setStr(pA : '' : 'Value for a');
```

---

## json_NewObject

```
Pointer json_NewObject( Pointer node )
```

#### Parameters

1. Destination JSON node. For example, you could pass in the Pointer from `json_Locate` or `json_LocateOrCreate`.

Returns object pointer.

---

## json_MoveObjectInto

```
Pointer json_MoveObjectInto( Pointer destinationObject : String objectname : Pointer sourceObject )
```

#### Parameters

1. Existing destination object node
2. New name of object in destination object
3. Contents of new object from an existing object node

#### Example

```
pObj = json_newObject();
json_setStr(pObj : 'a' : 'Value for a');

pB   = json_newObject();
json_setStr(pB : 'bValue' : 'Value for b');

json_MoveObjectInto(pObj : 'bObject': pB);
```

---

## json_NewArray

```
Pointer json_NewArray( Pointer node )
```

#### Parameters

1. Existing JSON node. For example, you could pass in the Pointer from `json_Locate` or `json_LocateOrCreate`.

Returns array pointer.

---

## json_ArrayPush

```
Pointer json_ArrayPush( Pointer existingArray : Pointer sourceNode : Uns(5) type )
```

#### Parameters

1. An existing array. Either locate one or use the pointer from `json_NewArray`.
2. What existing node to push to the array.
3. One of the following constants:
  * `JSON_MOVE_UNLINK` - push the existing node by reference.
  * `JSON_COPY_CLONE` - make a duplicate of your node and push the duplicate.

Returns pointer to node in array.

---

## json_GetStr

```
Varchar(32767) json_GetStr( Pointer node : [String relativeNode] : [String defaultvalue] )
```

#### Parameters

1. Pointer to existing node
2. Relative path to node
3. Default value if not node value is found.

---

## json_SetStr

```
Pointer json_SetStr( Pointer node : [String relativeNode] : [String newvalue] )
```

#### Parameters

1. Pointer to existing node
2. Relative path to node
3. New value.

---

## json_GetNum

```
Packed(30:15) json_GetNum( Pointer node : [String relativeNode] : [Packed(30:15) defaultvalue] )
```

#### Parameters

1. Pointer to existing node
2. Relative path to node
3. Default value if not node value is found.

---

## json_SetNum

```
Pointer json_SetNum( Pointer node : [String relativeNode] : [Packed(30:15) newvalue] )
```

#### Parameters

1. Pointer to existing node
2. Relative path to node
3. New value.

---

## json_GetInt

```
Int(20) json_GetInt( Pointer node : [String relativeNode] : [Int(20) defaultvalue] )
```

#### Parameters

1. Pointer to existing node
2. Relative path to node
3. Default value if not node value is found.

#### Example

```json
{  
  o: { 
    e:[],  
    n:123,                             
    a: [1,2,3,4,5],                     
    m:"yyyy",          
    f: "john"
  },
  u: "This is a unicode \u00b5 string" ,     
  "s":"abc" ,   
  a:[1,2,3],                              
  x:"xxxxx",
  "yo":{a:[],b:1}
}                                   
```

```
pJson = Json_ParseFile ('./test/documents/demo.json');

pNode   = Json_locate(pJson:'/o/n');
n       = json_GetInt(pNode); //123

pNode   = Json_locate(pJson:'/a[1]');
n       = json_GetInt(pNode); //2

pNode   = Json_locate(pJson:'/o/a[2]');
n       = json_GetInt(pNode); //3

//To fetch the length of an array
pNode   = Json_locate(pJson:'/o/a[UBOUND]');
n       = json_GetInt(pNode); //5

n       = json_GetInt(pJson:'/o/a[UBOUND]');
```

---

## json_SetInt

```
Pointer json_SetInt( Pointer node : [String relativeNode] : [Int(20) newvalue] )
```

#### Parameters

1. Pointer to existing node
2. Relative path to node
3. New value.

---

## json_SetBool

```
Pointer json_SetInt( Pointer node : [String relativeNode] : [Ind newvalue] )
```

#### Parameters

1. Pointer to existing node
2. Relative path to node
3. New value.

---

## json_GetNext

```
Pointer json_GetNext( Pointer node )
```

#### Parameters

1. Pointer to existing node

Returns next node in current block.

#### Example

```json
{  
  o: { 
    e:[],  
    n:123,                             
    a: [1,2,3,4,5],                     
    m:"yyyy",          
    f: "john"
  }
}                                   
```

```
pJson = Json_ParseFile ('./test/documents/demo.json');

pArr  = Json_locate(pJson: '/o/a[0]'); // First array element
dow (pArr <> *NULL) ;
  n     = Json_GetNum(pArr);

  pArr  = Json_GetNext(pArr);
endDo;

Json_Close(pJson);
```

---

## json_GetName

```
Varchar(32767) json_GetName( Pointer node )
```

#### Parameters

1. Pointer to existing node.

---

## json_SetIterator

```
JSON_ITERATOR json_SetIterator( Pointer node : [String path] )
```

#### Parameters

1. Pointer to existing node
2. Relative path to object or array

#### Example

```json
{
  "a":123,
  "b":"text",
  "c":"More text"
}
```

```
pJson = Json_ParseFile('./test/documents/demo.json');
list = json_SetIterator(pJson);
dow json_ForEach(list);
  n = json_GetName(list.this);
  v = json_GetStr(list.this);
enddo;
```

---

## json_ForEach

```
Ind json_ForEach( JSON_ITERATOR iterator )
```

#### Parameters

1. Iterator struct from either `json_SetIterator` or `json_setRecursiveIterator`

---

## json_NodeDelete

Deletes node.

```
void json_NodeDelete( Pointer node )
```

#### Parameters

1. Pointer to existing node.

---

## json_Close

Close all nodes in this node.

```
void json_Close( Pointer node )
```

#### Parameters

1. Pointer to existing node.