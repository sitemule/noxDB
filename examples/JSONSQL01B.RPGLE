
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pRow         Pointer;
        Dcl-S sqlHnd       Pointer;
        Dcl-S sql          Varchar(512);
        Dcl-S text         Varchar(512);
        Dcl-S ints         Int(10);
        Dcl-S numbers      Zoned(11:2);
        Dcl-S dates        Date;
        Dcl-S msg          Varchar(512);

        //------------------------------------------------------------- *

        // Open our SQL cursor. Use a simple select
        sqlhnd  = json_sqlOpen(
           'Select x from blob'
        );

        // Was there a problem ?
        if json_Error(sqlhnd);
           msg = json_Message(sqlhnd);
           json_sqlDisconnect();
           return;  // You can return, however the rest of the routines a roubust enough to just continue
        endif;

        // Now iterate on each row in the resultset
        pRow = json_sqlFetchNext(sqlhnd);
        dow (pRow <> *NULL );
           text    = json_getStr (pRow : 'x' );
           json_NodeDelete(pRow); // Always dispose it before get the next
           pRow = json_sqlFetchNext(sqlhnd);
        enddo;


        // Finaly and always !! close the SQL cursor and dispose the json row object
        json_sqlClose(sqlhnd);
        json_sqlDisconnect();

        // That's it..
        *inlr = *on;


