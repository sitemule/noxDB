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

          pTree = json_NewObject();

          pNode = json_setPtr(
             pTree :
             'level1.level2':
             *NULL
          );

          // Create a "customer" object
          pCustomer = json_ParseString ('                         -
             {                                                    -
                "name"  : "John"                                  -
             }                                                    -
          ');

          // Merge a copy of the "customer" into the tree
          json_mergeObjects (
             pNode :
             pCustomer:
             json_DONTREPLACE
          );

          json_WriteJsonStmf(pTree :'/noxdb/json/json_merge-6L.json':1208:*OFF);
          json_Delete(pTree);
          json_Delete(pCustomer);
