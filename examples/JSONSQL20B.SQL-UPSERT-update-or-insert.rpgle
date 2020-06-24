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
       // Using SQL cursors. Resultsets

       //  CALL QSYS/QP0WUSRT parm('-l 2' '-c 0' 'xxxxxx')

       //  or

       //  trace: CHGCPATRC JOBNUMBER(*CURRENT) SEV(*INFO)
       //         DSPCPATRC

       //  http://www-03.ibm.com/systems/power/software/i/db2/support/tips/clifaq.html
       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb

       Dcl-S err                    Ind;
       Dcl-S priceJsStr         VarChar(256);
       Dcl-S priceObj           Pointer;
       Dcl-S row                Pointer;
       Dcl-S id                     Int(10:0);


        // upsert is a combination of "update" and if not found then "insert"
          row = json_newObject();
          json_setInt(row : 'prodkey' : 12345);
          json_setStr(row : 'desc'    : 'Demo');

          // update or insert using object as the row
          err = json_sqlUpsert (
             'product'                // table name
             :row                     // row in object form {a:1,b:2} etc..
             :'prodkey = 12345    '   // need always a key, which can be different from the row
          );

          // get ret unique ID generated
          id = json_sqlGetInsertId();

          json_setInt(row : 'prodkey' : 23456);
          json_setStr(row : 'desc'    : 'Next Demo');

          // update or insert using object as the row
          err = json_sqlUpsert (
             'product'                // table name
             :row                     // row in object form {a:1,b:2} etc..
             :'prodkey = $prodkey'   // can also use data from the row for the where statment
             :row                    // values for the key template
          );

          json_delete(row);

          // Cleanup: Drop the database connection
          json_sqlDisconnect();

          // That's it..
          *inlr = *on;
