
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pConnect     Pointer;
        Dcl-S pResult      Pointer;

        //------------------------------------------------------------- *

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
           JSON_ALLROWS:               // Max number of rows to fetch
           JSON_META                   // return a obect and not an array
        );

        // Produce a JSON stream file in the root of the IFS
        json_writeJsonStmf(pResult:
           '/jsonxml/json/using-options-1.json' : 1208 : *ON
        );

        // Cleanup: Close the SQL cursor, dispose the row and the array
        json_close(pResult);

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
           JSON_ALLROWS:                  // Max number of rows to fetch
           JSON_META                      // return a obect and not an array
        );

        // Produce a JSON stream file in the root of the IFS
        json_writeJsonStmf(pResult:
           '/jsonxml/json/using-options-2.json' : 1208 : *ON
        );

        // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
        json_close(pResult);
        json_sqlDisconnect();

        // That's it..
        *inlr = *on;
