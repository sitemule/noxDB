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
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include xmlparser
       Dcl-S pXml               Pointer;
       Dcl-S a                  VarChar(50);
       Dcl-S msg                VarChar(256);
        // First parse the XML stream
          pXml = xml_ParseFile('/json_xml/xml/escape.xml');
          If xml_Error(pXml) ;
             msg = xml_Message(pXml);
             xml_delete(pXml);
             Return;
          EndIf;

          // Get the manifest id: that is a attribue on the root hench the @
          a = xml_getValue(pXml : '/a');

          xml_delete(pXml);
          *inlr = *on;
