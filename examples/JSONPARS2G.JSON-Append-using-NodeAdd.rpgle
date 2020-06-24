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

       // Parse json string and play with it

       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S pData              Pointer;
       Dcl-S a                  Pointer;
       Dcl-S c                  Pointer;

          pData = json_ParseString (
               '{                      '+
               '  a:123                '+
               '}'
          );
          // Find the "a" node in the data object:
          a = json_locate(pData : 'a');

          // add "d" after "a"
          json_NodeAdd(a:json_AFTER_SIBLING :'d':'value for d':json_VALUE);

          // now add c between a and d ( LITERALS and VALUES are supported)
          // note: we return the pointer to to node:
          c = json_NodeAdd(a:json_AFTER_SIBLING:'c': '1237' : json_LITERAL);

          // now add b before c
          json_NodeAdd(c:json_BEFORE_SIBLING:'b':'true': json_LITERAL);

          // write a,b,c,d in this order:
          json_WriteJsonStmf(pData:
            '/noxdb/json/nodeadd-1.json':1208:*OFF
          );
          json_delete (pData );
          *inlr = *on;
          Return;

