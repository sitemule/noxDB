      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin JSONparser in
      * IceBreak
      *
      * Using SQL cursors
      *
      * ------------------------------------------------------------- *
     H BndDir('JSONPARSER') dftactgrp(*NO) ACTGRP('QILE' )
     D pRow            s               *
     D rows            s               *
     D sqlHnd          s               *
     D sql             s            512    varying

      /include 'headers/JSONPARSER.rpgle'
      /free

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
