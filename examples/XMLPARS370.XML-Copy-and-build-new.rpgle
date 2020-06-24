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
       Dcl-S pXml1              Pointer;
       Dcl-S pXml2              Pointer;
       Dcl-S a                  Pointer;
       Dcl-S k                  Pointer;
       Dcl-S msg                VarChar(50);
       Dcl-S n                      Int(10:0);
       Dcl-S i                      Int(10:0);
      /include xmlParser
          pXml1= xml_ParseString('<a><b atr="john"/></a>');

          If xml_Error(pXml1) ;
             xml_joblog  (xml_Message(pXml1));
             xml_delete(pXml1);
             Return;
          EndIf;

          pXml2 = xml_ParseString('<k/>');

          If xml_Error(pXml2) ;
             xml_joblog  (xml_Message(pXml2));
             xml_delete(pXml2);
             Return;
          EndIf;

          a = xml_Locate(pxml1 : 'a');
          k = xml_Locate(pxml2 : 'k');
          xml_ElementCopy(k : a   : xml_FIRST_CHILD);

          xml_writeStmf(pXml2  : '/noxdb/xml/newout.xml'  : 1208);

          xml_delete(pXml1);
          xml_delete(pXml2);
          *inlr = *on;
