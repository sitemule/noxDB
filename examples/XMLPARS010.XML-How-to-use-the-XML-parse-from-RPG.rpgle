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

       // Step 1)
       // When using the XML parser - always bind your program to the NOXDB
       // bind directory - either by the CRTPGM command or add the "H" spec below:

       // Step 2)
       // Include the prototypes for the xml parser found in member "NOXDB"
       // in the source file "QRPGLEREF" in the IceBreak   library

       // Step 3)
       // Parse your XML file by caling the "xml_Parse" function. It returns
       // logical *ON if the parser completed ok - When an error occures
       // use the function "xml_GetMsg" to retrive the error and/or
       // use the function "xml_Dump"   to display the xml-tree contents

       // Step 4)
       // Locate each element node by the function "xml_Locate".
       // the location can be relative or from the root by prefixinig the location
       // with an "/". Each level is separated by a "/" e.g.
       // "/MyRoot/MyElement"  is "myelement" found within "myroot"

       // Step 5)
       // When a element node is sucessfully fetched, then you can
       // can retrieve its value by "xml_GetElemValue" and it attributes
       // with "xml_GetAttr". Note that you can supply a default
       // value forboth - if the node/attribute is not found.
       // Enshure that your result variable is big enough to hold the result
       // - otherwise unpredictble results may occure.

       // Step 6)
       // Itterate through all elements by returning the next element
       // with "xml_GetElemNext" until it returns *NULL

       // Step 7)
       // Last - remember to close the XML tree with "xml_delete"


       // The XML file we want to parse in this sample look like:

       //   <?xml version="1.0" encoding="ISO-8859-1"?>
       //   <Myroot>
       //      <Myelement Myattribute1="My Company name" Myattribute2="1">abc</Myelement>
       //      <Myelement Myattribute1="Another name"    Myattribute2="0">def</Myelement>
       //   </Myroot>

       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );
       Dcl-S pXml               Pointer;
       Dcl-S pElem              Pointer;
       Dcl-S MyString           VarChar(50);
       Dcl-S MyElem             VarChar(50);
       Dcl-S msg                VarChar(50);
      /include qrpgleRef,noxdb
          pXml = xml_ParseFile('/noxdb/xml/xmlsample1.xml');
          If xml_Error(pXml) ;
             msg = xml_Message(pXml);
          Else;
             pElem = xml_locate(pXml:'/MyRoot/MyElement');
             DoW (pElem <> *NULL);
                MyElem   = xml_GetElemValue (pElem : 'N/A');
                MyString = xml_GetAttr      (pElem : 'MyAttribute1' : 'N/A');
                pElem = xml_GetElemNext(pElem);
             EndDo;
          EndIf;
          xml_delete(pXml);
          *inlr = *on;
