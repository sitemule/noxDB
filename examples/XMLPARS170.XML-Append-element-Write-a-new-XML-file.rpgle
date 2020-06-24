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
       //   <Myroot>
       //      <Myelement Myattribute1="My Company name" Myattribute2="1">abc</Myelement>
       //      <Myelement Myattribute1="Another name"    Myattribute2="0">def</Myelement>
       //   </Myroot>

       // which will produce:

       //   <?xml version="1.0" encoding="UTF-8"?>
       //   <Myelement Myattribute1="Another name" Myattribute2="0">def</Myelement>

       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );
       Dcl-S pXml1              Pointer;
       Dcl-S pXml2              Pointer;
       Dcl-S pSrcElm            Pointer;
       Dcl-S pDstElm            Pointer;
       Dcl-S pDelete            Pointer;
       Dcl-S pOut               Pointer;
       Dcl-S msg                VarChar(50);
      /include qrpgleRef,noxdb
          pXml1 = xml_ParseFile('/noxdb/xml/simple1.xml':'syntax=LOOSE');
          If xml_Error(pXml1) ;
             msg = xml_Message(pXml1);
             xml_delete(pXml1);
             Return;
          EndIf;
          pOut    = xml_locate(pXml1:'/A');
          xml_writeStmf(pXml1 : '/noxdb/xml/simpleout1.xml' : 1208);

          pXml2 = xml_ParseFile('/noxdb/xml/simple2.xml':'syntax=LOOSE');
          If xml_Error(pXml2) ;
             msg = xml_Message(pXml2);
             xml_delete(pXml2);
             Return;
          EndIf;

          xml_writeStmf(pXml2 : '/noxdb/xml/simpleout2.xml' : 1208);

          // initial locatores in the XML tree
          pOut    = xml_locate(pXml1:'/A');
          pOut    = xml_locate(pXml2:'/X');
          xml_delete(pXml1);
          xml_delete(pXml2);
          *inlr = *on;
