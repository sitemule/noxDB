      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin JSONparser in
      * IceBreak
      *
      * Using SQL cursors
      *
      * ------------------------------------------------------------- *
     H dftactgrp(*NO) ACTGRP('QILE' )
     H BndDir('JSONPARSER')
     H BndDir('ICEBREAK')
     D pRow            s               *
     D rows            s               *
     D sqlHnd          s               *
     D sql             s            512    varying
     D i               s             10u 0

      /include jsonParser
      /include qasphdr,icebreak
      /free

        // Open our SQL cursor. Use a simple select
        sql = ('-
            SELECT      -
            ILGILGTKN,  -
            ILGITMTKN,  -
            ILGLNGCOD,  -
            ILGSEOURL,  -
            replace ( ILGPROP , '':.0'' , '':0.0'') as prop -
            from sqlbson/WSHILGET00  -
        ');
        sqlhnd  = json_sqlOpen(sql);

        // Now iterate on each row in the resultset
        pRow = json_sqlFetchNext(sqlhnd) ;
        dow (pRow <> *NULL and i < 10000000);
           putStreamString (
               '/www/products.js'   :
               'ab'                 :
               json_asJsonText(pRow) + x'0d25':
               *ON
           );

           json_delete(pRow);
           pRow = json_sqlFetchNext(sqlhnd) ;
           i += 1;
        enddo;


        // Cleanup: Close the SQL cursor, dispose the row and the array
        json_sqlClose(sqlhnd);
        json_close(rows);

        // That's it..
        *inlr = *on;
