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
       Dcl-S v                     Char(65000) based(pv);
       Dcl-S pv                 Pointer;
        // First parse the XML stream
          pXml = xml_ParseFile('/json_xml/xml/largeSoapFile.xml');
          If xml_Error(pXml) ;
             msg = xml_Message(pXml);
             xml_delete(pXml);
             Return;
          EndIf;

          // Get payload tag
          p = '/envelope/body/gnreRespostaMsg/TResultLote_GNRE' +
           '/resultado';
          pv  = xml_getValuePtr(xml_locate(pXml:p));

          xml_delete(pXml);
          *inlr = *on;
