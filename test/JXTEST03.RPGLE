      * ------------------------------------------------------------- *
      * This sample shows the use of the IceBreak JSON/XML parser
      *
      * Using SQL cursors
      *
      * ------------------------------------------------------------- *
     H BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' )
     D pRow            s               *
     D sqlHnd          s               *
     D sql             s            512    varying
     D text            s            512    varying
     D ints            s             10i 0
     D numbers         s             11  2
     D dates           s               d
     D msg             s            512    varying
      /include 'headers/JSONPARSER.rpgle'
      /free

        // Open our SQL cursor. Use a simple select
        sqlhnd  = json_sqlOpen(
           'Select * from product'
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


