
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pRows        Pointer;
        Dcl-S sql          Varchar(512);
        Dcl-S start        Int(10);
        Dcl-S limit        Int(10);

        //------------------------------------------------------------- *

        // return a object with all rows
        sql   = ('-
              Select (select prodkey  from product where 1=2) , product.* -
              from product -
        ');

        start = 1;
        limit = JSON_ALLROWS;
        pRows = json_sqlResultSet(sql:start:limit:JSON_META+JSON_FIELDS);

        // Produce a JSON stream file in the root of the IFS
        json_writeJsonStmf(pRows  :
           '/jsonxml/json/resultset-object-1.json' : 1208 : *ON
        );

        // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
        json_close(pRows);
        json_sqlDisconnect();

        // That's it..
        *inlr = *on;
