
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pRow         Pointer;
        Dcl-S sqlHnd       Pointer;
        Dcl-S text         Varchar(512);
        Dcl-S ints         Int(10);
        Dcl-S numbers      Zoned(11:2);
        Dcl-S dates        Date;
        Dcl-S msg          Varchar(512);
        Dcl-S cols         Int(10);
        Dcl-S rows         Int(10);

        //------------------------------------------------------------- *

        // Open our SQL cursor. Use a simple select
        sqlhnd  = nox_sqlOpen(
           'Select * from product'
        );

        // Was there a problem ?
        if nox_Error(sqlhnd);
           msg = nox_Message(sqlhnd);
           // return;  You can return, however the rest of the routines a roubust enough to just continue
        endif;

        // Need some statisics ?
        rows = nox_sqlRows(sqlhnd);    // Note this will produce a "select count(*)" and can be a little pricy
        cols = nox_sqlColumns(sqlhnd); // This is costs nothing

        // Now iterate on each row in the resultset
        // NOTE!! Start from row 10 and read ahead
        pRow  = nox_sqlFetchRelative(sqlhnd: 10);
        dow (pRow <> *NULL) ;
           ints    = nox_getNum (pRow : 'PRODKEY');
           text    = nox_getStr (pRow : 'PRODID');
           text    = nox_getStr (pRow : 'DESC');
           text    = nox_getStr (pRow : 'MANUID');
           numbers = nox_getNum (pRow : 'PRICE');
           ints    = nox_getNum (pRow : 'STOCKCNT');
           dates   = %date(nox_getStr (pRow : 'STOCKDATE'));

           // When done with the row then always dispose it. Otherwise you will have a memory leak
           // Remember that "Fetch" will produce a new row object
           nox_Delete(pRow);

           // .. Now we are ready for that nex row
           pRow  = nox_sqlFetchNext(sqlhnd);
        enddo;


        // Finaly close the SQL cursor and dispose the json row object
        nox_sqlClose(sqlhnd);
        nox_sqlDisconnect();

        // That's it..
        *inlr = *on;


