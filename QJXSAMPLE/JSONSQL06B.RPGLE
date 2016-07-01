      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin JSONparser in
      * IceBreak
      *
      * Using SQL cursors
      *
      * ------------------------------------------------------------- *
     H BndDir('JSONPARSER') dftactgrp(*NO) ACTGRP('QILE' )
     D pRows           s               *
     D sql             s            512    varying
     D start           s             10i 0
     D limit           s             10i 0

      /include jsonParser
      /free

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
