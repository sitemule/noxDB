        //------------------------------------------------------------- *
        //This sample shows the use of the buildin JSONparser in
        //IceBreak

        //Using SQL cursors

        //trace: CHGCPATRC JOBNUMBER(*CURRENT) SEV(*INFO)
        //DSPCPATRC

        //http://www-03.ibm.com/systems/power/software/i/db2/support/tips/clifaq.
        //------------------------------------------------------------- *
        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );
        Dcl-S err          Ind;
        Dcl-S priceJsStr   Varchar(256);
        Dcl-S priceObj     Pointer;
        Dcl-S row          Pointer;

      /include 'headers/JSONPARSER.rpgle'

        // Simple update
        err = nox_sqlExec(
           'update product set price = price * 1.01'
        );

        // update using json string template
        priceJsStr  = '{ newprice : 1.03 }';
        err = nox_sqlExec(
           'update product set price = price * $newprice'
           :priceJsStr
        );

        // update using json object
        priceObj    = nox_parseString ('{ newprice : 1.04 }');
        err = nox_sqlExec(
           'update product set price = price * $newprice'
           :priceObj
        );
        nox_Close(priceObj);

        // Advanced: - update using json object as a row
        // This also works for BLOBS and CLOB columns
        row  = nox_parseString ('{  -
           manuid: "SAMSUNG",        -
           price: 1234,              -
           stockCnt: 22              -
        }');

        // update using object as the row
        err = nox_sqlUpdate (
           'product'                // table name
           :row                     // row in object form {a:1,b:2} etc..
           :'where prodkey = 120'   // Where clause ( you can omit the "where" )
        );

        // update using object as the row: You can omit the "where"
        err = nox_sqlUpdate (
           'product'                // table name
           :row                     // row in object form {a:1,b:2} etc..
           :'prodkey = 120'         // Where clause
        );

        // update using object as the row: The where can be a template / object it self
        err = nox_sqlUpdate (
           'product'                // table name
           :row                     // row in object form {a:1,b:2} etc..
           :'prodkey = $ID'         // Where clause
           : '{"ID":130}'           // Templte or object
        );
        nox_delete(row);

        // Simple delete
        err = nox_sqlExec(
           'delete from  product where prodkey = 99999'
        );

        // Advanced: - insert
        // This also works for BLOBS and CLOB columns
        row  = nox_parseString ('{  -
           prodKey:  99999  ,        -
           desc   :  "Test" ,        -
           manuid: "SAMSUNG",        -
           price: 456.78  ,          -
           stockCnt: 12              -
        }');

        err = nox_sqlInsert (
           'product'
           :row
        );
        nox_delete(row);

        // Advanced: - insert
        // nestedet objects is serialized CLOBS / BLOB
        row  = nox_parseString ('{  -
           x : {                     -
               abc:123,              -
               sometext : "It auto serialize it .. wow !!" -
           },                                            -
           canBeNull : null                             -
        }');
        err = nox_sqlInsert (
           'blob'
           :row
        );
        nox_delete(row);

        // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
        nox_sqlDisconnect();

        // That's it..
        *inlr = *on;
