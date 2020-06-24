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
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

       //  Globals
       Dcl-S pXml               Pointer;
       Dcl-S p                  VarChar(128);

      /include qrpgleRef,noxdb
       // ' -----------------------------------------------------------
       // ' Mainline
       // ' -----------------------------------------------------------
          p ='/data/TestNFei/XMLSIGN/'
            +'35081145841137000107550010000332506603325076-nfe.xml';
          pXml  = xml_ParseFile(p:'syntax=LOOSE');
          If xml_Error(pXml) ;
             p = xml_Message(pXml);
          Else;
             xml_Dump(pXml);
          EndIf;
          xml_delete(pXml);
          *inlr = *on;
