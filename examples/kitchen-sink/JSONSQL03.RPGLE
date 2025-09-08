
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pRow         Pointer;
        Dcl-S rows         Pointer;
        Dcl-S sqlHnd       Pointer;
        Dcl-S sql          Varchar(512);

        //------------------------------------------------------------- *

        // The destination object for our SQL result row
        // and the array to contain the rows
        rows    = nox_newArray ();

        // Open our SQL cursor. Use a simple select
        sql = 'Select * from product';
        sqlhnd  = nox_sqlOpen(sql);

        // Now iterate on each row in the resultset
        pRow = nox_sqlFetchNext(sqlhnd) ;
        dow (pRow <> *NULL );
           // Append the row to the end of the result array. Note ArrayPush will
           // by default move the object ( not copy) to the bottom of the array.
           nox_ArrayPush(rows : pRow);
           pRow = nox_sqlFetchNext(sqlhnd) ;
        enddo;

        // Produce a JSON stream file in the root of the IFS
        nox_writeJsonStmf(rows : '/jsonxml/json/demo.json' : 1208 : *ON);

        // Cleanup: Close the SQL cursor, dispose the row and the array
        nox_close(rows);
        nox_sqlClose(sqlhnd);
        nox_sqlDisconnect();

        // That's it..
        *inlr = *on;
