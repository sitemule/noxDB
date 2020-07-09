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
       Dcl-S pA                 Pointer;
       Dcl-S pB                 Pointer;
       Dcl-S aCount                 Int(10:0);
       Dcl-S bCount                 Int(10:0);
          pJson = json_parseString('                 -
                {                                      -
                   a :{                                -
                      x:1,                             -
                      y:2,                             -
                      z:3                              -
                   },                                  -
                   b: [9,8,7,6,5,4,3,2,1]              -
                }                                      -
            ');

          // Direct with "getLength"
          pA = json_locate(pJson : 'a');
          aCount = json_getLength(pA);

          // Direct with expression
          aCount = json_getNum(pJson : 'a[UBOUND]');

          // Relative
          pA = json_locate(pJson : 'a');
          aCount = json_getNum(pA : '[UBOUND]');

          // Direct
          bCount = json_getNum(pJson : 'b[UBOUND]');

          // Relative
          pB = json_locate(pJson : 'b');
          bCount = json_getNum(pB : '[UBOUND]');

          json_WriteJsonStmf(
             pJson: '/prj/noxdb/testdata/buildup1.json': 1208 : *OFF
          );
          json_delete(pJson);
          *inlr = *on;
