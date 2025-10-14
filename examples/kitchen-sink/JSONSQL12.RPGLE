
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pConnect     Pointer;
        Dcl-S pResult      Pointer;

        //------------------------------------------------------------- *

        // Need the resultset names in upper case:
        // Note: it can be a JSON string or a JSON object made by nox_ParseString
        nox_sqlSetOptions('{'+ // use dfault connection
           'uppercasecolname: true,  '+ // set option for uppcase
           'autoParseContent: true,  '+ // auto parse columns predicted to have JSON or XML contents
           'sqlnaming       : true   '+ // use the SQL naming for database.table
        '}');

        pResult = nox_sqlResultSet(
           'Select * from qgpl.items':    // The sql stmt
           1:                          // from row number
           NOX_ALLROWS:               // Max number of rows to fetch
           NOX_META                   // return a obect and not an array
        );

        // Produce a JSON stream file in the root of the IFS
        nox_writeJsonStmf(pResult:
           '/jsonxml/json/using-options-1.json' : 1208 : *ON
        );

        // Cleanup: Close the SQL cursor, dispose the row and the array
        nox_close(pResult);

        // Onw once again  - but with IBMI naming and the sql as it is
        // Note: it can be a JSON string or a JSON object made by nox_ParseString
        nox_sqlSetOptions('{'+ // use dfault connection
           'uppercasecolname: false, '+ // set option for uppcase
           'autoParseContent: false, '+ // auto parse columns predicted to have JSON or XML contents
           'sqlnaming       : false  '+ // use the IBMI naming for tables
        '}');

        pResult = nox_sqlResultSet(
           'Select * from qgpl/items':    // The sql stmt
           1:                             // from row number
           NOX_ALLROWS:                  // Max number of rows to fetch
           NOX_META                      // return a obect and not an array
        );

        // Produce a JSON stream file in the root of the IFS
        nox_writeJsonStmf(pResult:
           '/jsonxml/json/using-options-2.json' : 1208 : *ON
        );

        // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
        nox_close(pResult);
        nox_sqlDisconnect();

        // That's it..
        *inlr = *on;
