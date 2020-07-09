       // ------------------------------------------------------------- *
       // noxDB - Not only XML. JSON, SQL and XML made easy for RPG

       // Company . . . : System & Method A/S - Sitemule
       // Design  . . . : Niels Liisberg

       // Unless required by applicable law or agreed to in writing, software
       // distributed under the License is distributed on an "AS IS" BASIS,
       // WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

       // Look at the header source file "QRPGLEREF" member "NOXDB"
       // for a complete description of the functionality

       // When using noxDB you need two things:
       //  A: Bind you program with "NOXDB" Bind directory
       //  B: Include the noxDB prototypes from QRPGLEREF member NOXDB

       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S pJson              Pointer;
       Dcl-S pNode              Pointer;
       Dcl-S msg                VarChar(50);
       Dcl-S tag                VarChar(50);
       Dcl-S value              VarChar(50);
       Dcl-S price               Packed(15:2);
          *inlr = *on;
          pJson = json_ParseFile ('/prj/noxDB   v/ccsid/win-1252.json');
          If json_Error(pJson) ;
             msg = json_Message(pJson);
          EndIf;
          json_Dump(pJson);
          json_delete(pJson);

          pJson = json_ParseFile ('/prj/noxdb/testdata/doesnotexists.json');
          If json_Error(pJson) ;
             msg = json_Message(pJson);
          EndIf;
          json_delete(pJson);


          pJson = json_ParseFile ('/prj/noxdb/testdata/partsplexer.lib');
          If json_Error(pJson) ;
             msg = json_Message(pJson);
          EndIf;
          json_delete(pJson);

          pJson = json_ParseFile ('/prj/noxdb/testdata/webshop.lib');
          If json_Error(pJson) ;
             msg = json_Message(pJson);
          EndIf;
          json_delete(pJson);

