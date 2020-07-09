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

       // Parse Strings

       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S pJson              Pointer;
       Dcl-S msg                VarChar(50);
       Dcl-S s                  VarChar(50);
       Dcl-S i                      Int(10:0);

          pJson = json_ParseString ('{a:[1,2,3]}');
          If json_Error(pJson) ;
             msg = json_Message(pJson);
             json_dump(pJson);
             json_delete(pJson);
             Return;
          EndIf;
          // Get number of entries in arrays
          i     = json_getNum  (pJson : '/a[UBOUND]': -1 );
          i     = json_getNum  (pJson : 'a[UBOUND]' : -1 );
          s     = json_getStr  (pJson : '/a[0]'     : 'N/A' );

          // 0 in the root is the "a" object. Bothe works
          s     = json_getStr  (pJson : '[0]/[1]'   : 'N/A' );
          s     = json_getStr  (pJson : '[0][1]'   : 'N/A' );

          json_WriteJsonStmf  (pJson   : '/prj/noxDB_out.json' : 1208 : *OFF);
          json_dump(pJson);
          json_delete(pJson);
          *inlr = *on;
