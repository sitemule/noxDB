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

       // Copy values or arrays or objects

       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S pFrom              Pointer;
       Dcl-S pTo                Pointer;

          pFrom = json_parseString ('{ -
               "s" : "Life is a gift",   -
               "a" : [1,2,3,4],          -
               "o" : {                   -
                  "x"  : 100,            -
                  "y"  : 200             -
               }                         -
            }');

          // "to" is just an empty object at begining
          pTo = json_newObject();

          // copy all elements: This is deep copy
          json_copyValue ( pTo  : '' : pFrom : '');

          // copy string:
          json_copyValue ( pTo  : 'myString' : pFrom : 's');

          // copy within my own structure can address all elements both source and destination
          json_copyValue ( pTo  : 'a[4]' : pTo   : 'o.x');

          // Note: *OFF prettify the JSON
          json_WriteJsonStmf  (pTo: '/prj/noxdb/testdata/copy1.json':1208:*OFF);
          json_delete(pTo);
          json_delete(pFrom);
          *inlr = *on;
