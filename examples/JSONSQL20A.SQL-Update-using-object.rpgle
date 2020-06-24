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
       Dcl-S msg                VarChar(256);
       Dcl-S priceJsStr         VarChar(256);
       Dcl-S priceObj           Pointer;
       Dcl-S row                Pointer;


        // Simple update
          err = json_sqlExec(
               'update product set price = price * 1.01'
            );

          // update using json string template
          priceJsStr  = '{ newprice : 1.03 }';
          err = json_sqlExec(
             'update product set price = price * $newprice'
             :priceJsStr
          );

          // update using json object
          priceObj    = json_parseString ('{ newprice : 1.04 }');
          err = json_sqlExec(
             'update product set price = price * $newprice'
             :priceObj
          );
          json_delete(priceObj);

          // Advanced: - update using json object as a row
          // This also works for BLOBS and CLOB columns
          row  = json_parseString ('{  -
             manuid: "SAMSUNG",        -
             price: 1234,              -
             stockCnt: 22              -
          }');

          // update using object as the row
          err = json_sqlUpdate (
             'product'                // table name
             :row                     // row in object form {a:1,b:2} etc..
             :'where prodkey = 120'   // Where clause ( you can omit the "where" )
          );

          // update using object as the row: You can omit the "where"
          err = json_sqlUpdate (
             'product'                // table name
             :row                     // row in object form {a:1,b:2} etc..
             :'prodkey = 120'         // Where clause
          );

          // update using object as the row: The where can be a template / object it self
          err = json_sqlUpdate (
             'product'                // table name
             :row                     // row in object form {a:1,b:2} etc..
             :'prodkey = $ID'         // Where clause
             : '{"ID":130}'           // Templte or object
          );
          json_delete(row);

          // Simple delete
          err = json_sqlExec(
             'delete from  product where prodkey = 99999'
          );

          // Advanced: - insert
          // This also works for BLOBS and CLOB columns
          row  = json_parseString ('{  -
             prodKey:  99999  ,        -
             desc   :  "Test" ,        -
             manuid: "SAMSUNG",        -
             price: 456.78  ,          -
             stockCnt: 12              -
          }');

          err = json_sqlInsert (
             'product'
             :row
          );
          json_delete(row);
          msg = json_message(*NULL);

          // Advanced: - insert
          // nestedet objects is serialized CLOBS / BLOB
          row  = json_parseString ('{  -
             x : {                     -
                 abc:123,              -
                 sometext : "It auto serialize it .. wow !!" -
             },                                            -
             canBeNull : null                             -
          }');
          err = json_sqlInsert (
             'blob'
             :row
          );
          json_delete(row);

          // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
          json_sqlDisconnect();

          // That's it..
          *inlr = *on;
