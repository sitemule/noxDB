
        //------------------------------------------------------------- *
        //This sample shows the use of the buildin JSONparser in
        //IceBreak

        //Using SQL cursors

        //------------------------------------------------------------- *
        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );
        Dcl-S pRows        Pointer;
        Dcl-S sql          Varchar(512);
        Dcl-S start        Int(10);
        Dcl-S limit        Int(10);

      /include 'headers/JSONPARSER.rpgle'

        // return a object with all rows
        sql   = ('-
              Select (select prodkey  from product where 1=2) , product.* -
              from product -
        ');

        start = 1;
        limit = NOX_ALLROWS;
        pRows = nox_sqlResultSet(sql:start:limit:NOX_META+NOX_FIELDS);

        // Produce a JSON stream file in the root of the IFS
        nox_writeJsonStmf(pRows  :
           '/jsonxml/json/resultset-object-1.json' : 1208 : *ON
        );

        // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
        nox_close(pRows);
        nox_sqlDisconnect();

        // That's it..
        *inlr = *on;
