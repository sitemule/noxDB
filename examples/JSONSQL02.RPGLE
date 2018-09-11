
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );

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
        sqlhnd  = json_sqlOpen(
           'Select * from product'
        );

        // Was there a problem ?
        if json_Error(sqlhnd);
           msg = json_Message(sqlhnd);
           // return;  You can return, however the rest of the routines a roubust enough to just continue
        endif;

        // Need some statisics ?
        rows = json_sqlRows(sqlhnd);    // Note this will produce a "select count(*)" and can be a little pricy
        cols = json_sqlColumns(sqlhnd); // This is costs nothing

        // Now iterate on each row in the resultset
        // NOTE!! Start from row 10 and read ahead
        pRow  = json_sqlFetchRelative(sqlhnd: 10);
        dow (pRow <> *NULL) ;
           ints    = json_getNum (pRow : 'PRODKEY');
           text    = json_getStr (pRow : 'PRODID');
           text    = json_getStr (pRow : 'DESC');
           text    = json_getStr (pRow : 'MANUID');
           numbers = json_getNum (pRow : 'PRICE');
           ints    = json_getNum (pRow : 'STOCKCNT');
           dates   = %date(json_getStr (pRow : 'STOCKDATE'));

           // When done with the row then always dispose it. Otherwise you will have a memory leak
           // Remember that "Fetch" will produce a new row object
           json_NodeDelete(pRow);

           // .. Now we are ready for that nex row
           pRow  = json_sqlFetchNext(sqlhnd);
        enddo;


        // Finaly close the SQL cursor and dispose the json row object
        json_sqlClose(sqlhnd);
        json_sqlDisconnect();

        // That's it..
        *inlr = *on;


