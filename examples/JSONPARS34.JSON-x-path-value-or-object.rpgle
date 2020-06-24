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

       // Parse json string and save it in different formats

       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S pJson              Pointer;
       Dcl-S p                  Pointer;
       Dcl-S msg                VarChar(50);
       Dcl-S s                  VarChar(50);
       Dcl-S n                  VarChar(50);
       Dcl-S i                      Int(10:0);

          *inlr = *on;

          // First demo: find attribues which contains objects where attibutes has a value
          pJson = json_ParseString ('{-
             "__cid__":12,"title":{"da":"Kontakter","en":""},"image":"" -
          }');

          If json_Error(pJson) ;
             msg = json_Message(pJson);
             json_dump(pJson);
             json_delete(pJson);
             Return;
          EndIf;

          // Get the object in the array where the "x" attribute has the value of 2
          s = json_getStr      (pJson : '/title/da' );
          s = json_getStr      (pJson : '/title/[0]' );
          s = json_getStr      (pJson : '/title'     );

          json_delete(pJson);
          // Next  demo: find attribues which contains objects where attibutes has a value
          pJson = json_ParseString ('{-
             "__cid__":12,"title": "Kontakter","image":"" -
          }');

          If json_Error(pJson) ;
             msg = json_Message(pJson);
             json_dump(pJson);
             json_delete(pJson);
             Return;
          EndIf;

          // Get the object in the array where the "x" attribute has the value of 2
          s = json_getStr      (pJson : '/title/da' );
          s = json_getStr      (pJson : '/title/[0]' );
          s = json_getStr      (pJson : '/title'     );

          json_delete(pJson);

          *inlr = *on;
