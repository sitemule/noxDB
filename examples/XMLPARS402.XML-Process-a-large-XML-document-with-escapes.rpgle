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
       Dcl-S p                  VarChar(256);
       Dcl-S v                     Char(256);
        // First parse the XML stream
          // pXml = xml_ParseILOB(iRes:'syntax=LOOSE':0:0);

          pXml = xml_ParseFile('/noxdb/xml/xml4.xml');
          If xml_Error(pXml) ;
             msg = xml_Message(pXml);
             xml_delete(pXml);
             Return;
          EndIf;

          // Get payload tag
          p = '/ClientResponse/SendDocument/SendDocumentResult';
          v  = xml_getValue(pXml: p);

          xml_delete(pXml);
          *inlr = *on;
