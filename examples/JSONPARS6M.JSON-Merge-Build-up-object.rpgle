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
       Dcl-S pTree              Pointer;
       Dcl-S pNode              Pointer;
       Dcl-S pCustomer          Pointer;
       Dcl-S msg                VarChar(50);
          *inlr = *on;

          pNode     = json_ParseString ('                         -
             {                                                    -
                "a": 1,                                           -
                "b": 2,                                           -
                "c": 3                                            -
             }                                                    -
          ');

          json_delete(json_locate(pNode:'c'));
          json_setInt(pNode : 'd' : 4);

          json_WriteJsonStmf (pNode :'/noxdb/json/simple6m.json':1208:*OFF);
          json_Delete(pNode);
