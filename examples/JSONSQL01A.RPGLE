        //------------------------------------------------------------- *
        //This sample shows the use of the IceBreak JSON/XML parser

        //Using SQL cursors

        //------------------------------------------------------------- *
        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );
        Dcl-S pRow         Pointer;
        Dcl-S sqlHnd       Pointer;
        Dcl-S sql          Varchar(512);
        Dcl-S text         Varchar(512);
        Dcl-S ints         Int(10);
        Dcl-S numbers      Zoned(11:2);
        Dcl-S dates        Date;
        Dcl-S msg          Varchar(512);
      /include 'headers/JSONPARSER.rpgle'

        // Open our SQL cursor. Use a simple select
        sqlhnd  = json_sqlOpen(
           'Select p from product'
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
           ints    = json_getNum (pRow : 'PRODKEY');
           text    = json_getStr (pRow : 'PRODID');
           text    = json_getStr (pRow : 'DESC');
           text    = json_getStr (pRow : 'MANUID');
           numbers = json_getNum (pRow : 'PRICE');
           ints    = json_getNum (pRow : 'STOCKCNT');
           dates   = %date(json_getStr (pRow : 'STOCKDATE'));
           json_NodeDelete(pRow); // Always dispose it before get the next
           pRow = json_sqlFetchNext(sqlhnd);
        enddo;


        // Finaly and always !! close the SQL cursor and dispose the json row object
        json_sqlClose(sqlhnd);
        json_sqlDisconnect();

        // That's it..
        *inlr = *on;


