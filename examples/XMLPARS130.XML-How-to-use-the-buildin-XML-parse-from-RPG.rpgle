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
       // Parse your XML file by caling the "xml_ParseFile" function. It returns
       // logical *ON if the parser completed ok - When an error occures
       // use the function "xml_GetMsg" to retrive the error and/or
       // use the function "xml_Dump"   to display the xml-tree contents

       // Step 4)
       // Use X-Path syntax to retrive datavalues (search the net for a description of Xpath)
       // Locate each element node by the function "xml_Locate".
       // the location can be relative or from the root by prefixinig the location
       // with an "/". Each level is separated by a "/" and attributes is prefixed by "@"
       // "/MyRoot/MyElement@myattibute"

       // Step 5)
       // Last - remember to close the XML tree with "xml_delete"


       // The XML file we want to parse in this sample look like:

       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
       // >>>>> Not converted: File not externally-described
     Fqprint    O    F  132        printer

       //  Globals
       Dcl-S pXml               Pointer;
       Dcl-S id                 VarChar(32);

       //  prototypes
       Dcl-PR Print;
          Str                      Char(132) const;
       End-PR;

      /include qrpgleRef,noxdb
       // ' -----------------------------------------------------------
       // ' Mainline
       // ' -----------------------------------------------------------
          // pXml  = xml_ParseFile('/IceBreak  /demo/oiodemo.xml':'syntax=LOOSE');
          pXml  = xml_ParseFile('/noxdb/xml/XmlSample1.xml':'syntax=LOOSE');
          If xml_Error(pXml) ;
             Print(xml_Message(pXml));
          Else;
             id = xml_Getvalue(pXml: '/invoice/com:id ': 'N/A');
           id = xml_Getvalue(pXml: '/Myroot/myelement[1]@myattribute1 ': 'N/A');
             print(id);
          EndIf;
          xml_delete(pXml);
          *inlr = *on;
          // ------------------------------------------------------------- *
       Dcl-Proc Print;
       Dcl-PI Print;
          Str                      Char(132) const;
       End-PI;
       Dcl-DS Buf                   Len(132);
       End-DS;
          Buf = str;
          Write qprint Buf;
       End-Proc Print;

