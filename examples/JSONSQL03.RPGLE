
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pRow         Pointer;
        Dcl-S rows         Pointer;
        Dcl-S sqlHnd       Pointer;
        Dcl-S sql          Varchar(512);

        //------------------------------------------------------------- *

        // The destination object for our SQL result row
        // and the array to contain the rows
        rows    = json_newArray ();

        // Open our SQL cursor. Use a simple select
        sql = 'Select * from product';
        sqlhnd  = json_sqlOpen(sql);

        // Now iterate on each row in the resultset
        pRow = json_sqlFetchNext(sqlhnd) ;
        dow (pRow <> *NULL );
           // Append the row to the end of the result array. Note ArrayPush will
           // by default move the object ( not copy) to the bottom of the array.
           json_ArrayPush(rows : pRow);
           pRow = json_sqlFetchNext(sqlhnd) ;
        enddo;

        // Produce a JSON stream file in the root of the IFS
        json_writeJsonStmf(rows : '/jsonxml/json/demo.json' : 1208 : *ON);

        // Cleanup: Close the SQL cursor, dispose the row and the array
        json_close(rows);
        json_sqlClose(sqlhnd);
        json_sqlDisconnect();

        // That's it..
        *inlr = *on;
