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
       Ctl-Opt BndDir('NOXDB'  )
               dftactgrp(*NO) ACTGRP('QILE');
       Dcl-S pXml               Pointer;
       Dcl-S msg                VarChar(50);
       Dcl-S dc                 VarChar(50);
       Dcl-S n                      Int(10:0);
       Dcl-S i                      Int(10:0);
      /include qrpgleRef,noxdb
          pXml = xml_ParseFile (
                 '/bwr/368_20140616080348.XML'
            );

          If xml_Error(pXml) ;
             dsply  (xml_Message(pXml));
             xml_dump(pXml);
             xml_delete(pXml);
             Return;
          EndIf;


          //  n    = xml_getNum(pXml : 'invoices/invoice[UBOUND]');
          //  for i=0  to n -1;
          //      dc = xml_getValue(pXml :
          //         'invoices/invoice[' + %char(i)  +']/Header/DistChannel'
          //      );
          //      sndDiag('DistChannel : ' + dc);
          //  endFor;

          xml_dump(pXml);
          xml_delete(pXml);
          *inlr = *on;
