
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pRows        Pointer;
        Dcl-S sql          Varchar(512);
        Dcl-S start        Int(10);
        Dcl-S limit        Int(10);

        //------------------------------------------------------------- *

        // return a object with all rows
        sql   = 'Select * from qgpl/blobs';
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
