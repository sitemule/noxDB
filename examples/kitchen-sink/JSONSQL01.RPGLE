
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

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
        sqlhnd  = nox_sqlOpen(
           'Select * from product'
        );

        // Was there a problem ?
        if nox_Error(sqlhnd);
           msg = nox_Message(sqlhnd);
           nox_sqlDisconnect();
           return;  // You can return, however the rest of the routines a roubust enough to just continue
        endif;

        // Now iterate on each row in the resultset
        pRow = nox_sqlFetchNext(sqlhnd);
        dow (pRow <> *NULL );
           ints    = nox_getNum (pRow : 'PRODKEY');
           text    = nox_getStr (pRow : 'PRODID');
           text    = nox_getStr (pRow : 'DESC');
           text    = nox_getStr (pRow : 'MANUID');
           numbers = nox_getNum (pRow : 'PRICE');
           ints    = nox_getNum (pRow : 'STOCKCNT');
           dates   = %date(nox_getStr (pRow : 'STOCKDATE'));
           nox_Delete(pRow); // Always dispose it before get the next
           pRow = nox_sqlFetchNext(sqlhnd);
        enddo;


        // Finaly and always !! close the SQL cursor and dispose the json row object
        nox_sqlClose(sqlhnd);
        nox_sqlDisconnect();

        // That's it..
        *inlr = *on;


