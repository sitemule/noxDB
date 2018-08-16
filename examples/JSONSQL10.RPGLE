        //------------------------------------------------------------- *
        //This sample shows the use of the buildin JSONparser in
        //IceBreak

        //Using SQL cursors

        //------------------------------------------------------------- *
        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );
        Dcl-S err          Ind;
        Dcl-S priceJsStr   Varchar(256);
        Dcl-S priceObj     Pointer;

      /include 'headers/JSONPARSER.rpgle'

        // Simple update
        err = json_sqlExec(
           'update product set price = price * 1.01'
        );

        // update using json string
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

        // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
        json_Close(priceObj);
        json_sqlDisconnect();

        // That's it..
        *inlr = *on;
