        //------------------------------------------------------------- *
        //This sample shows the use of the buildin JSONparser in
        //IceBreak

        //Using SQL cursors

        //trace: CHGCPATRC JOBNUMBER(*CURRENT) SEV(*INFO)
        //DSPCPATRC

        //http://www-03.ibm.com/systems/power/software/i/db2/support/tips/clifaq.
        //------------------------------------------------------------- *
        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );
        Dcl-S err          Ind;
        Dcl-S priceJsStr   Varchar(256);
        Dcl-S priceObj     Pointer;
        Dcl-S row          Pointer;

      /include 'headers/JSONPARSER.rpgle'

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

        // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
        json_sqlDisconnect();

        // That's it..
        *inlr = *on;
