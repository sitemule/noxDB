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
       Dcl-S pSrcElm            Pointer;
       Dcl-S pDstElm            Pointer;
       Dcl-S pDelete            Pointer;
       Dcl-S pOut               Pointer;
       Dcl-S msg                VarChar(50);
      /include qrpgleRef,noxdb
          pXml1 = xml_ParseFile('/noxdb/xml/xmlsample1.xml');
          If xml_Error(pXml1) ;
             msg = xml_Message(pXml1);
             xml_delete(pXml1);
             Return;
          EndIf;

          pXml2 = xml_ParseFile('/noxdb/xml/xmlsample2.xml' );
          If xml_Error(pXml2) ;
             msg = xml_Message(pXml2);
             xml_delete(pXml1);
             xml_delete(pXml2);
             Return;
          EndIf;

          // initial locatores in the XML tree
          pSrcElm = xml_locate(pXml2:'/MyRoot/MyElement[3]');
          pOut    = xml_locate(pXml1:'/MyRoot');

          // ex1 : Add a child at the top
          pDstElm = xml_locate(pXml1:'/MyRoot');
          xml_ElementCopy(pDstElm : pSrcElm : xml_FIRST_CHILD);

          xml_writeStmf(pOut : '/noxdb/xml/xmlsampleout1.xml' : 1208);
          pDelete = xml_locate(pXml1:'/MyRoot/SubElement');
          xml_ElementDelete (pDelete);

          // ex2 : Add a child at the bottom
          pDstElm = xml_locate(pXml1:'/MyRoot');
          xml_ElementCopy(pDstElm : pSrcElm : xml_LAST_CHILD);
          xml_writeStmf(pOut : '/noxdb/xml/xmlsampleout2.xml' : 1208);
          pDelete = xml_locate(pXml1:'/MyRoot/SubElement');
          xml_ElementDelete (pDelete);

          // ex3 : Add a sibling after a reference location
          pDstElm = xml_locate(pXml1:'/MyRoot/MyElement[0]');
          xml_ElementCopy(pDstElm : pSrcElm : xml_AFTER_SIBLING);
          xml_writeStmf(pOut : '/noxdb/xml/xmlsampleout3.xml' : 1208);
          pDelete = xml_locate(pXml1:'/MyRoot/SubElement');
          xml_ElementDelete (pDelete);

          // ex4 : Add a sibling before a reference location
          pDstElm = xml_locate(pXml1:'/MyRoot/MyElement[1]');
          xml_ElementCopy(pDstElm : pSrcElm : xml_BEFORE_SIBLING);
          xml_writeStmf(pOut : '/noxdb/xml/xmlsampleout4.xml' : 1208);
          pDelete = xml_locate(pXml1:'/MyRoot/SubElement');
          xml_ElementDelete (pDelete);

          xml_delete(pXml1);
          xml_delete(pXml2);
          *inlr = *on;
