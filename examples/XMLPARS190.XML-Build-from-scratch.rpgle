
       // -------------------------------------------------------------
       // noxDB - Not only XML. JSON, SQL and XML made easy for RPG
       //
       // Company . . . : System & Method A/S - Sitemule
       // Design  . . . : Niels Liisberg
       //
       // Unless required by applicable law or agreed to in writing, software
       // distributed under the License is distributed on an "AS IS" BASIS,
       // WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
       //
       // Look at the header source file "QRPGLEREF" member "NOXDB"
       // for a complete description of the functionality
       //
       //
       // -------------------------------------------------------------

       // The aim is to produce a XML document from scratch

       // Step 1)
       // When using the XML parser - always bind your program to the NOXDB
       // bind directory - either by the CRTPGM command or add the "H" spec below:

       // Step 2)
       // Include the prototypes for the xml parser found in member "NOXDB"
       // in the source file "QRPGLEREF" in the IceBreak   library

       // Step 3)
       // Parse your XML file by caling the "xml_Parse" function. It returns
       // logical a pointer to an XML object tree.
       // Examine if the parser ran ok with xml_Error() which return *ON if an
       // error did occur. In that case you can examine the reason with
       // the function "xml_GetMsg()" to retrive the error and/or
       // use the function "xml_Dump()"   to display the xml-tree contents

       // Step 4)
       // Locate each element node by the function "xml_Locate".
       // the location can be relative or from the root by prefixinig the location
       // with an "/". Each level is separated by a "/" e.g.
       // "/MyRoot/MyElement"  is "myelement" found within "myroot"

       // Step 5)
       // When a element node is sucessfully fetched, you can write
       // a new XML document with this element as a root element.
       // Use the xml_writeStmf(pElm: FileName : Ccsid)  to produce that task
       // the ccsid can be other than the source XMl document. it will
       // convert it to the selected ccsid. Note: Comments not reproduced.

       // Step 6)
       // Last - remember to close the XML tree with "xml_delete"


       // The XML file we want to parse in this sample look like:

       //   <?xml version="1.0" encoding="ISO-8859-1"?>
       //   <root>
       //      <first>
       //        <subnode2>Sub stuff</subnode2>
       //      <first>
       //      <last>Some stuff<last>
       //   </root>
       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );
       Dcl-S pRoot              Pointer;
       Dcl-S pt                 Pointer;
       Dcl-S msg                VarChar(50);
      /include qrpgleRef,noxdb

        // Produce the root int the object graph and give ti a name
        pRoot = xml_newObject();
        xml_nodeRename(pRoot:'root');


        // elements are now added sucessivly using the reference location and element pointer
        // note the order..
        pt = xml_elementAdd(pRoot : xml_LAST_CHILD  : 'last' : 'Some value');
        pt = xml_elementAdd(pRoot : xml_FIRST_CHILD : 'first' : 'More value');
        pt = xml_elementAdd(pt    : xml_LAST_CHILD  : 'subnode2' : 'Sub-stuff');
        xml_SetAttrValue(pt    : 'MyAttribute' : 'First value');
        xml_SetAttrValue(pt    : 'MyAttribute' : 'New Value');
        xml_SetAttrValue(pt    : 'a2'          : 'a2 1');
        xml_SetAttrValue(pt    : 'a2'          : 'a2 2');

        // Finally we can produce the XML file
        xml_writeStmf(pRoot : '/prj/noxdb/testout/xml190out.xml' : 1208);
        xml_delete(pRoot);
        *inlr = *on;
