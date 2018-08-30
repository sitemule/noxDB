
# XML Functionality

This page documents the XML functionality available in noxDB. Header file: `headers/XMLPARSER.rpgle`.

* xml_ParseFile
* xml_Error
* xml_Message
* xml_Locate
* xml_LocateOrCreate
* xml_GetNext
* xml_GetStr
* xml_SetStr
* xml_GetNum
* xml_SetNum
* xml_GetInt
* xml_SetInt
* xml_GetValue
* xml_GetValueStr
* xml_GetValueNum
* xml_GetValueInt
* xml_GetAttr
* xml_GetNodeAttrValue
* xml_SetNodeAttrValue
* xml_Close

---

## xml_SetDelimiters

```
void xml_SetDelimiters( String characters )
```

*Function is deprecated, has been replaced with `xml_SetDelimiters2`*.

#### Parameters

1. **5 characters** which represent delimiters in a programs characters set. List of characters in their order:
   1. Forward slash
   2. Back slash
   3. Master space (`@`)
   4. Square bracket begin
   5. Square bracket end

---

## xml_SetDelimiters2

```
void xml_SetDelimiters2( String characters )
```

*Function is deprecated, has been replaced with `xml_SetDelimiters2`*.

#### Parameters

1. **11 characters** which represent delimiters in a programs characters set. List of characters in their order:
   1. Forward slash
   2. Back slash
   3. Master space (`@`)
   4. Square bracket begin
   5. Square bracket end
   6. Blank
   7. Dot
   8. Curley bracket begin (`{`)
   9. Curley bracket end (`}`)
   10. Apostrophe (`'`)
   11. Quote / Speech mark (`"`)

#### Example

```
xml_setDelimiters2('/\@[] .{}''"');
```

---

## xml_ParseFile

```
Pointer xml_ParseFile( String path : [String options] )
```

##### Parameters

1. Path relavtive to the current directory.
2. Options for the parser. For example: `syntax=LOOSE` is a valid parameter.

Returns Pointer to created node.

---

## xml_Error

```
Ind xml_Error( Pointer node )
```

##### Parameters

1. Pointer to node created by another XML function.

Returns `*ON` if there was an error.

##### Example

```
pXml = xml_ParseFile('./test/documents/XmlSample1.xml');

If Xml_Error(pXml) ;
  //Do thing
Endif;

xml_Close(pXml);
```

---

## xml_Message

```
Varchar(1024) xml_Message( Pointer node )
```

#### Parameters

1. Pointer to node created by other another XML function.

Returns error message create by another XML function.

---

## xml_Locate

```
Pointer xml_Locate( Pointer node : String nodepath )
```

#### Parameters

1. Pointer to node created by other another XML function.
2. Document path which points to a node.

Returns Pointer to chosen document node.

#### Example

```
pXml = xml_ParseFile('./test/documents/XmlSample.xml');
pElem = xml_Locate(pXml:'/MyRoot/MyElement');

MyElem = xml_GetValueStr(pElem : 'N/A');

xml_Close(pXml);
```

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<Myroot>
    <Myelement Myattribute1="My Company name">
   	    abc
    </Myelement>
</Myroot>
```

---

## xml_LocateOrCreate

Similar to `xml_Locate`, but if the node does not exist, it will be created. Can be used when creating an XML document.

```
Pointer xml_LocateOrCreate( Pointer node : String nodepath )
```

#### Parameters

1. Pointer to node created by other another XML function.
2. Document path which points to a node.

Returns Pointer to chosen document node.

---

## xml_GetNext

```
Pointer xml_GetNext( Pointer node )
```

#### Parameters

1. Pointer to existing node

Returns next node in current block.

#### Example

```
pXml = xml_ParseFile('./test/documents/XmlSample.xml');
pElem = xml_locate(pXml:'/MyRoot/MyElement');

dow (pElem <> *NULL);
  MyElem   = xml_GetValueStr (pElem : 'N/A');
  MyString = xml_GetAttr     (pElem : 'MyAttribute1' : 'N/A');

  pElem = xml_GetNext(pElem);
enddo;

xml_Close(pXml);
```

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<Myroot>
    <Myelement Myattribute1="First attr">
   	    abc
    </Myelement>
    <Myelement Myattribute1="Second attr">
   	    def
    </Myelement>
</Myroot>
```

---

## xml_GetStr

```
Varchar(32767) xml_GetStr( Pointer node : [String relativeNode] : [String defaultvalue] )
```

#### Parameters

1. Pointer to existing node
2. Relative path to node
3. Default value if not node value is found.

#### Example

Fetching a value or attribute.

```
//Fetches first element always

charVar = xml_GetStr(pXml:'/Myroot/Myelement'); //Fetch value
charVar = xml_GetStr(pXml:'/Myroot/Myelement@Myattribute1'); //Fetch attribute with the @ symbol
```

---

## xml_SetStr

```
Pointer xml_SetStr( Pointer node : [String relativeNode] : [String newvalue] )
```

#### Parameters

1. Pointer to existing node
2. Relative path to node
3. New value.

---

## xml_GetNum

```
Packed(30:15) xml_GetNum( Pointer node : [String relativeNode] : [Packed(30:15) defaultvalue] )
```

#### Parameters

1. Pointer to existing node
2. Relative path to node
3. Default value if not node value is found.

---

## xml_SetNum

```
Pointer xml_SetNum( Pointer node : [String relativeNode] : [Packed(30:15) newvalue] )
```

#### Parameters

1. Pointer to existing node
2. Relative path to node
3. New value.

---

## xml_GetInt

```
Int(20) xml_GetInt( Pointer node : [String relativeNode] : [Int(20) defaultvalue] )
```

#### Parameters

1. Pointer to existing node
2. Relative path to node
3. Default value if not node value is found.

#### Example

Fetching count of nodes inside a node.

```xml
<a>
    <l>1</l>
    <l>2</l>
    <k>x</k>
    <l>3</l>
</a>
```

```
lCount = xml_getInt(pXml:'/a/l[UBOUND]');
kCount = xml_getInt(pXml:'/a/k[UBOUND]');

// relative Count number of l and k tags
pA = xml_locate(pXml:'/a');
lCount = xml_getInt(pA:'l[UBOUND]');
kCount = xml_getInt(pA:'k[UBOUND]');

// relative Count number childrens of a
pA = xml_locate(pXml:'/a');
countChildren = xml_getInt(pA:'[UBOUND]');
```

---

## xml_SetInt

```
Pointer xml_SetInt( Pointer node : [String relativeNode] : [Int(20) newvalue] )
```

#### Parameters

1. Pointer to existing node
2. Relative path to node
3. New value.

---

## xml_GetValue

*Deprecated*: use `xml_GetValueStr` or `xml_GetStr` instead.

```
Varchar(32767) xml_GetValue( Pointer node : [String relativeNode] : [String defaultvalue] )
```

#### Parameters

1. Pointer to existing node
2. Relative path to node
3. Default value if not node value is found.

#### Example

```
charResult = xml_GetValue (pXml : '/Myroot/Myelement':'null');
```

---

## xml_GetValueStr

Used to get the node value as a string.

```
Varchar(32767) xml_GetValueStr( Pointer node : [String defaultvalue] )
```

#### Parameters

1. Pointer to existing node
2. Default value if not node value is found.

---

## xml_GetValueNum

Used to get the node value as numeric decimal.

```
Packed(30:15) xml_GetValueNum( Pointer node : [Packed(30:15) defaultvalue] )
```

#### Parameters

1. Pointer to existing node
2. Default value if not node value is found.

---

## xml_GetValueInt

Used to get the node value as integer.

```
Int(20) xml_GetValueNum( Pointer node : [Int(20) defaultvalue] )
```

#### Parameters

1. Pointer to existing node
2. Default value if not node value is found.

---

## xml_GetAttr

*Deprecated*: use `xml_GetNodeAttrValue` instead.

```
Varchar(32767) xml_GetElemValue( Pointer node : String attrname : [String defaultvalue] )
```

#### Parameters

1. Pointer to existing node
2. Attribute name on chosen node.
2. Default value if not attribute is found.

---

## xml_GetNodeAttrValue

```
Varchar(32767) xml_GetNodeAttrValue( Pointer node : String attrname : [String defaultvalue] )
```

#### Parameters

1. Pointer to existing node
2. Attribute name on chosen node.
2. Default value if not attribute is found.

---

## xml_SetNodeAttrValue

Not only does this API update an existing attribute on a node, but will add the attribute if it does not exist.

```
void xml_SetNodeAttrValue( Pointer node : String attrname : String newValue )
```

#### Parameters

1. Pointer to existing node
2. Attribute name on chosen node.
2. New value for selected attribute.

---

## xml_Close

Close all nodes in this node/tree.

```
void xml_Close( Pointer node )
```

#### Parameters

1. Pointer to existing node.