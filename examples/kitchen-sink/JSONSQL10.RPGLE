        
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S err          Ind;
        Dcl-S priceJsStr   Varchar(256);
        Dcl-S priceObj     Pointer;

        //------------------------------------------------------------- *


        // Simple update
        err = nox_sqlExec(
           'update product set price = price * 1.01'
        );

        // update using json string
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

        // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
        nox_Close(priceObj);
        nox_sqlDisconnect();

        // That's it..
        *inlr = *on;
