       //  -------------------------------------------------------------
       //  noxDB - Not only XML. JSON, SQL and XML made easy for RPG
       //
       //  Company . . . : System & Method A/S - Sitemule
       //  Design  . . . : Niels Liisberg
       //
       //  Unless required by applicable law or agreed to in writing, software
       //  distributed under the License is distributed on an "AS IS" BASIS,
       //  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
       //
       //  Look at the header source file "QRPGLEREF" member "NOXDB"
       //  for a complete description of the functionality
       // -------------------------------------------------------------
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );
       Dcl-S pXml               Pointer;
       Dcl-S pJson              Pointer;
      /include qrpgleRef,noxdb


          // the json and xml namespace is the same, just syntactical suggar
          // and the parser will determine by filetype
          pXml  = xml_ParseFile('/noxdb/xml/xmlsample1.xml');
          pJson = json_ParseFile('/noxdb/xml/xmlsample1.xml');
          xml_delete(pXml);
          json_delete(pJson);
          *inlr = *on;
