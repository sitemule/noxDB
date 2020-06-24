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
       // The aim is to produce a XML document from scratch
       // -------------------------------------------------------------
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );
       /include qrpgleRef,noxdb

       Dcl-S pXml1              Pointer;
       Dcl-S msg                VarChar(50);


       // first we run the paser on an empty string giving us an empty tree
       pXml1 = xml_ParseString('':'syntax=LOOSE,keys=/[@].');
       If xml_Error(pXml1) ;
          msg = xml_Message(pXml1);
          xml_delete(pXml1);
          Return;
       EndIf;

       xml_SetValue(pXml1: '/root/first@atr1' : 'value for atr1');
       xml_SetValue(pXml1: '/root/first@atr2' : 'value for atr2');
       xml_SetValue(pXml1: '/root/next@nextAtr' : 'value for next atr');
       xml_SetValue(pXml1: '/root/next' : 'value for next  element');

       xml_SetValue(pXml1: '/root/row[NEW]' : 'value for next  element');
       xml_SetValue(pXml1: '/root/row[LAST]@nextAtr' : 'value for next atr');
       xml_SetValue(pXml1: '/root/row[LAST]@atr' : 'value for next atr');

       xml_SetValue(pXml1: '/root/row[NEW]' : 'value for next  element');
       xml_SetValue(pXml1: '/root/row[LAST]@nextAtr' : 'value for next atr');
       xml_SetValue(pXml1: '/root/row[LAST]@atr' : 'value for next atr');

       xml_SetValue(pXml1: '/root/row[NEW]' : 'value for next  element');
       xml_SetValue(pXml1: '/root/row[LAST]@nextAtr' : 'value for next atr');
       xml_SetValue(pXml1: '/root/row[LAST]@atr' : 'value for next atr');
       // Finally we can produce the XML file
       xml_writeStmf(pXml1 : '/noxdb/xml/sampleout6a.xml' : 1208);
       xml_delete(pXml1);
       *inlr = *on;
