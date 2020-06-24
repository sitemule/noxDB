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

       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S pConnect           Pointer;
       Dcl-S pResult            Pointer;


        // Need the resultset names in upper case:
        // Note: it can be a JSON string or a JSON object made by json_ParseString
        json_sqlSetOptions('{'+ // use dfault connection
           'uppercasecolname: true,  '+ // set option for uppcase
           'autoParseContent: true,  '+ // auto parse columns predicted to have JSON or XML contents
           'sqlnaming       : true   '+ // use the SQL naming for database.table
        '}');

          pResult = json_sqlResultSet(
               'Select * from qgpl.items':    // The sql stmt
               1:                          // from row number
               json_ALLROWS:               // Max number of rows to fetch
               json_META                   // return a obect and not an array
            );

          // Produce a JSON stream file in the root of the IFS
          json_writeJsonStmf(pResult:
             '/noxdb/json/using-options-1.json' : 1208 : *ON
          );

          // Cleanup: Close the SQL cursor, dispose the row and the array
          json_delete(pResult);

          // Onw once again  - but with IBMI naming and the sql as it is
          // Note: it can be a JSON string or a JSON object made by json_ParseString
          json_sqlSetOptions('{'+ // use dfault connection
             'uppercasecolname: false, '+ // set option for uppcase
          'autoParseContent: false, '+ // auto parse columns predicted to have JSON or XML contents
             'sqlnaming       : false  '+ // use the IBMI naming for tables
          '}');

          pResult = json_sqlResultSet(
             'Select * from qgpl/items':    // The sql stmt
             1:                             // from row number
             json_ALLROWS:                  // Max number of rows to fetch
             json_META                      // return a obect and not an array
          );

          // Produce a JSON stream file in the root of the IFS
          json_writeJsonStmf(pResult:
             '/noxdb/json/using-options-2.json' : 1208 : *ON
          );

          // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
          json_delete(pResult);
          json_sqlDisconnect();

          // That's it..
          *inlr = *on;
