
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pConnect     Pointer;
        Dcl-S pResult      Pointer;

        //------------------------------------------------------------- *

        // If you nnes a seperate connection, where the default connection
        // is no sufficient - then expilict do you own sqlConnect
        // Normally this is not required, an implicit default connect to local database
        // is done automatcally with first sql statement
        pConnect = json_sqlConnect();

        // Need the resultset names in upper case:
        // Note: it can be a JSON string or a JSON object made by json_ParseString
        json_sqlSetOptions('{'+ // use dfault connection
           'uppercasecolname: true,  '+ // set option for uppcase
           'sqlnaming       : false  '+ // use the SQL naming for database.table
        '}');

        pResult = json_sqlResultSet(
           'Select * from product':    // The sql stmt
           1:                          // from row number
           JSON_ALLROWS:               // Max number of rows to fetch
           JSON_META                   // return a obect and not an array
        );

        // Produce a JSON stream file in the root of the IFS
        json_writeJsonStmf(
           pResult:
           '/jsonxml/json/using-options.json' : 1208 : *ON
        );

        // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
        json_close(pResult);
        json_sqlDisconnect();

        // That's it..
        *inlr = *on;
