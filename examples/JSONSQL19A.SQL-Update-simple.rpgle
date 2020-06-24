       // ------------------------------------------------------------- *
       // noxDB - Not only XML. JSON, SQL and XML made easy for RPG

       // Company . . . : System & Method A/S - Sitemule
       // Design  . . . : Niels Liisberg

       // Unless required by applicable law or agreed to in writing, software
       // distributed under the License is distributed on an "AS IS" BASIS,
       // WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

       // Look at the header source file "QRPGLESRC" member "NOXDB"
       // for a complete description of the functionality

       // When using noxDB you need two things:
       //  A: Bind you program with "NOXDB" Bind directory
       //  B: Include the noxDB prototypes from QRPGLSERC member NOXDB

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
       Dcl-S row                VarChar(256);
       Dcl-S rc                     Int(5:0);


        // Simple update
          err = json_sqlExec(
               'update product set price = price * 1.01 where prodkey = -123'
            );
          rc= json_SqlCode();

          row = '{ price : 123456789.01}';
          // update using object as the row
          err = json_sqlUpdate (
             'product'                // table name
             :row                     // row in object form {a:1,b:2} etc..
             :'where prodkey = 120'   // Where clause ( you can omit the "where" )
          );

          rc= json_SqlCode();

          row = '{ price : -123456789.01}';
          // update using object as the row
          err = json_sqlUpdate (
             'product'                // table name
             :row                     // row in object form {a:1,b:2} etc..
             :'where prodkey = 120'   // Where clause ( you can omit the "where" )
          );

          rc= json_SqlCode();

          // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
          json_sqlDisconnect();

          // That's it..
          *inlr = *on;
