        //------------------------------------------------------------- *
        //This sample shows the use of the buildin JSONparser in
        //IceBreak

        //Using SQL cursors

        //------------------------------------------------------------- *
        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );
        Dcl-S pRows        Pointer;
        Dcl-S sql          Varchar(512);

      /include 'headers/JSONPARSER.rpgle'

        // return an simple array with all rows
        sql   = 'Select * from product';
        pRows = json_sqlResultSet(sql);

        // Produce a JSON stream file in the root of the IFS
        json_writeJsonStmf(pRows  :
           '/jsonxml/json/resultset-array.json' : 1208 : *ON
        );

        // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
        json_close(pRows);
        json_sqlDisconnect();

        // That's it..
        *inlr = *on;
