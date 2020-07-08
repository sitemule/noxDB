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

         // 

         // ------------------------------------------------------------- *

         //  CALL QSYS/QP0WUSRT parm('-l 2' '-c 0' 'xxxxxx')

         //  or

         //  trace: CHGCPATRC JOBNUMBER(*CURRENT) SEV(*INFO)
         //         DSPCPATRC

         //  http://www-03.ibm.com/systems/power/software/i/db2/support/tips/clifaq.html
         // ------------------------------------------------------------- *
         Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
         /include qrpgleRef,noxdb
         Dcl-S err                Ind;
         Dcl-S msg                VarChar(256);
         Dcl-S priceJsStr         VarChar(256);
         Dcl-S priceObj           Pointer;
         Dcl-S row                VarChar(32000);
         Dcl-S rc                 Int(5:0);

         *inlr = *on;

         // Run a "normal SQL " to create the test case 
         err = json_sqlExec('-
            create or replace table noxdb.example (      -         
               id int generated always as identity,      -
               xSmallint  smallint,                      -
               xInt       int,                           -
               xDec       dec(11 , 2),                   - 
               xNumeric   numeric (11, 2),               -     
               xReal      real,                          - 
               xChar      char(30),                      - 
               xVarchar   varchar(30),                   -
               xDate      date,                          -    
               xTime      time,                          -    
               xTimestamp timestamp,                     -
               xBlob      blob,                          -
               xClob      clob                           -
            )'        
         );

         // Show the error in the joblog
         if err;
            json_joblog(json_message(*NULL));
            json_sqlDisconnect();
            return;
         endif;

         // Both insert and update allows you to give an JSON atring or and object
         // Here we create a row using object by a string it will pass:
         row = '{-
            "xSmallint": -32766.00 , -
            "xInt": -2147483646.00,   -
            "xDec": -123456789.12, -
            "xNumeric": -123456789.12, -
            "xReal": -123456789.12, -
            "xChar": "abc", - 
            "xVarchar": "abc", -
            "xDate": "2020-01-01", -
            "xTime": "12.34.56", -
            "xTimestamp": "2020-01-01-12.34.56.123456", -
            "xBlob": "abc", -
            "xClob": "abc" -
         }';

         err = json_sqlInsert (
            'example'                // table name
            :row                     // row in object form {a:1,b:2} etc..
         );

         // Show the error in the joblog if anny
         if err;
            json_joblog(json_message(*NULL));
            json_sqlDisconnect();
            return;
         endif;

         // Only use columns you need:
         row = '{-
            "xVarchar": "Only the varchar column" -
         }';

         err = json_sqlInsert (
            'example'                // table name
            :row                     // row in object form {a:1,b:2} etc..
         );


         // Now we can update with a "normal sql" or use an object:

         // 1) Use simple update ( normal sql commands)
         err = json_sqlExec(
            'update example  -
             set xDec = xDec * 1.01 - 
             where id = (select min(id) from example)'
         );
         // When you test for errors: 
         // You can now use either the 'err' indicator returned 
         if err;
            json_joblog(json_message(*NULL));
            json_sqlDisconnect();
            return;
         endif;

         // Or test the sqlcode
         rc= json_SqlCode();

         // 2) Update using object as the row
         row = '{-
            "xSmallint": 32766.00 , -
            "xInt": 2147483646.00,   -
            "xDec": 123456789.12, -
            "xNumeric": 123456789.12, -
            "xReal": 123456789.12, -
            "xChar": "xyz", - 
            "xVarchar": "xyz", -
            "xDate": "2021-01-01", -
            "xTime": "23.59.59", -
            "xTimestamp": "' + %char(%timestamp()) +'", -
            "xBlob": "xyz", -
            "xClob": "xyz" -
         }';
         err = json_sqlUpdate (
            'example'         // table name
            :row              // row in object form {a:1,b:2} etc..
            :'id = 1'         // This is your where clause
         );

         rc= json_SqlCode();

         // Note the where claus can be a SQL statement
         err = json_sqlUpdate (
            'example'         // table name
            :row              // row in object form {a:1,b:2} etc..
            :'id = (select min(id) from example)' // This is your where clause
         );

         // Test for errors
         if err;
            json_joblog(json_message(*NULL));
            json_sqlDisconnect();
            return;
         endif;

         // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
         json_sqlDisconnect();
