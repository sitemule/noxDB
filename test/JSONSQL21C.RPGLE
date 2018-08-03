      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin JSONparser in
      * IceBreak
      *
      * Using SQL cursors
      *
      *  on a table like this:
      *    create table QGPL/NOTE2 (
      *       id     int generated always as Identity,
      *       title  varchar(256)     not null with default,
      *       text1  clob             not null with default,
      *       text2  clob             not null with default
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
     d text1           s          32766    dim(10)
     d text2           s          32766    dim(10)
     d*text1           s          32766
     d*text2           s          32766

      /include 'headers/JSONPARSER.rpgle'
      /free

        // Advanced: - update using json object as a row
        // This also works for BLOBS and CLOB columns

        text1 = *all'x';
        %subst (text1(1) : 1 : 15   )  = 'First clob';
        %subst (text1(10) : 1    : 1 )  = x'00';
        pNote1 = %addr(text1);

        text2 = *all'y';
        %subst (text2(1) : 1 : 15   )  = 'Next clob';
        %subst (text2(10) : 1    :  1 )  = x'00';
        pNote2 = %addr(text2);
        pRow  = json_newObject();

        json_setStr(pRow:  'title'    : 'My first note');
        json_setPtr(pRow:  'text1'    : pNote1);
        json_setPtr(pRow:  'text2'    : pNote2);

        err = json_sqlInsert  (
           'qgpl/note2'
           :pRow
        );

        //  id = json_sqlGetId();

        // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
        json_close(pRow);
        json_sqlDisconnect();

        // That's it..
        *inlr = *on;
