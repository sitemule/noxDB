
        //------------------------------------------------------------- *

        Ctl-Opt dftactgrp(*NO) ACTGRP('QILE' );
        Ctl-Opt BndDir('NOXDB2');
        Ctl-Opt BndDir('ICEBREAK');

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        /include qasphdr,icebreak

        Dcl-S pRow         Pointer;
        Dcl-S rows         Pointer;
        Dcl-S sqlHnd       Pointer;
        Dcl-S sql          Varchar(512);
        Dcl-S i            Uns(10);

        //------------------------------------------------------------- *

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
