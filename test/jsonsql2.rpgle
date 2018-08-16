
        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );
        
        /include 'headers/JSONPARSER.rpgle'
        
        Dcl-S pRow         Pointer;
        Dcl-S sqlHnd       Pointer;
        Dcl-S rows         Pointer;
        
        Dcl-S Result       Varchar(50);

        //------------------------------------------------------------- *
        
        Dcl-Pi JSONSQL2;
          pResult Char(50);
        End-Pi;
        
        Result = '';

        // The destination object for our SQL result row
        // and the array to contain the rows
        rows    = json_newArray ();

        // Open our SQL cursor. Use a simple select
        sqlhnd  = json_sqlOpen(
           'Select prodid, price from product ' +
           'where PRODID like ''Coolpix%'' ' +
           'fetch first 2 rows only'
        );

        // Was there a problem ?
        if json_Error(sqlhnd);
           pResult = json_Message(sqlhnd);
           json_sqlDisconnect();
           return;
        endif;

        // Now iterate on each row in the resultset
        pRow = json_sqlFetchNext(sqlhnd) ;
        dow (pRow <> *NULL );
           // Append the row to the end of the result array. Note ArrayPush will
           // by default move the object ( not copy) to the bottom of the array.
           json_ArrayPush(rows : pRow);
           pRow = json_sqlFetchNext(sqlhnd) ;
        enddo;

        // Produce a JSON stream file in the root of the IFS
        pResult = json_asJsonText(rows);

        // Cleanup: Close the SQL cursor, dispose the row and the array
        json_close(rows);
        json_sqlClose(sqlhnd);
        json_sqlDisconnect();

        // That's it..
        *inlr = *on;


