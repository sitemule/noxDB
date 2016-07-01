      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin JSONparser in
      * IceBreak
      *
      * Using SQL cursors
      *
      *  on a table like this:
      *    create table QGPL/NOTES (
      *       id     int generated always as Identity,
      *       title  varchar(256)     not null with default,
      *       text1  blob             not null with default,
      *       text2  blob             not null with default
      *    )
      *
      *  trace: CHGCPATRC JOBNUMBER(*CURRENT) SEV(*INFO)
      *         DSPCPATRC
      *
      *  http://www-03.ibm.com/systems/power/software/i/db2/support/tips/clifaq.html
      * ------------------------------------------------------------- *
     H BndDir('JSONPARSER') dftactgrp(*NO) ACTGRP('QILE' )

     D err             s               n
     D pNote1          s               *
     D pNote2          s               *
     D pRow            s               *
     D id              s             10u 0

      /include jsonParser
      /free

        // Advanced: - update using json object as a row
        // This also works for BLOBS and CLOB columns

        pRow  = json_newObject();
        json_setStr(pRow:  'title'    : 'My first note');
        json_setStr(pRow:  'text1'    : '{a:123}');

        err = json_sqlInsert  (
           'qgpl/notes'
           :pRow
        );
        id = json_sqlGetInsertId();

        // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
        json_close(pRow);
        json_sqlDisconnect();

        // That's it..
        *inlr = *on;
