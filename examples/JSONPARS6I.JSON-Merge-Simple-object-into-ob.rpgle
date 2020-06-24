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
       Dcl-S pJson1             Pointer;
       Dcl-S pJson2             Pointer;
       Dcl-S msg                VarChar(50);
          *inlr = *on;

          pJson1 = json_ParseString ('                            -
             {                                                    -
                x : {                                             -
                  a : 1                                           -
                }                                                 -
             }                                                    -
          ');

          pJson2 = json_ParseString ('                            -
             {                                                    -
                x : {                                             -
                  b : 2                                           -
                }                                                 -
             }                                                    -
          ');

          json_merge (pJson1 : pJson2  : json_DONTREPLACE);

          json_WriteJsonStmf(pJson1:'/noxdb/json/json_merge6i.json':1208:*OFF);
          json_delete(pJson1);
          json_delete(pJson2);
