
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pConnect     Pointer;
        Dcl-S pResult      Pointer;

        //------------------------------------------------------------- *

        // If you nnes a seperate connection, where the default connection
        // is no sufficient - then expilict do you own sqlConnect
        // Normally this is not required, an implicit default connect to local database
        // is done automatcally with first sql statement
        pConnect = nox_sqlConnect();

        // Need the resultset names in upper case:
        // Note: it can be a JSON string or a JSON object made by nox_ParseString
        nox_sqlSetOptions('{'+ // use dfault connection
           'uppercasecolname: true,  '+ // set option for uppcase
           'sqlnaming       : false  '+ // use the SQL naming for database.table
        '}');

        pResult = nox_sqlResultSet(
           'Select * from product':    // The sql stmt
           1:                          // from row number
           NOX_ALLROWS:               // Max number of rows to fetch
           NOX_META                   // return a obect and not an array
        );

        // Produce a JSON stream file in the root of the IFS
        nox_writeJsonStmf(
           pResult:
           '/jsonxml/json/using-options.json' : 1208 : *ON
        );

        // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
        nox_close(pResult);
        nox_sqlDisconnect();

        // That's it..
        *inlr = *on;
