      * ------------------------------------------------------------- *
      * This sample shows the use of the IceBreak JSON/XML parser
      *
      * Using SQL cursors
      *
      * ------------------------------------------------------------- *
     H BndDir('JSONPARSER') dftactgrp(*NO) ACTGRP('QILE' )
     D pRow            s               *
     D sqlHnd          s               *
     D text            s            512    varying
     D ints            s             10i 0
     D numbers         s             11  2
     D dates           s               d
     D msg             s            512    varying
     D cols            s             10i 0
     D rows            s             10i 0
      /include JsonParser
      /free

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


