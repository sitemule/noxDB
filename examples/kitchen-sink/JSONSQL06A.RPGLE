
        //------------------------------------------------------------- *
        
        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pRows        Pointer;
        Dcl-S sql          Varchar(512);

        //------------------------------------------------------------- *

        // return an simple array with all rows
        sql   = 'Select * from product';
        pRows = nox_sqlResultSet(sql);

        // Produce a JSON stream file in the root of the IFS
        nox_writeJsonStmf(pRows  :
           '/jsonxml/json/resultset-array.json' : 1208 : *ON
        );

        // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
        nox_close(pRows);
        nox_sqlDisconnect();

        // That's it..
        *inlr = *on;
