        //------------------------------------------------------------- *
        //This sample shows the use of the buildin JSONparser in
        //IceBreak

        //Using SQL cursors

        //on a table like this:
        //create table QGPL/NOTE2 (
        //id     int generated always as Identity,
        //title  varchar(256)     not null with default,
        //text1  clob             not null with default,
        //text2  clob             not null with default
        //)

        //trace: CHGCPATRC JOBNUMBER(*CURRENT) SEV(*INFO)
        //DSPCPATRC

        //http://www-03.ibm.com/systems/power/software/i/db2/support/tips/clifaq.
        //------------------------------------------------------------- *
        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        Dcl-S err          Ind;
        Dcl-S pNote1       Pointer;
        Dcl-S pNote2       Pointer;
        Dcl-S pRow         Pointer;
        Dcl-S id           Uns(10);
        Dcl-S text1        Char(32766) dim(10);
        Dcl-S text2        Char(32766) dim(10);
        //text1           s          32766
        //text2           s          32766

      /include 'headers/JSONPARSER.rpgle'

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
        pRow  = nox_newObject();

        nox_setStr(pRow:  'title'    : 'My first note');
        nox_setPtr(pRow:  'text1'    : pNote1);
        nox_setPtr(pRow:  'text2'    : pNote2);

        err = nox_sqlInsert  (
           'qgpl/note2'
           :pRow
        );

        //  id = nox_sqlGetId();

        // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
        nox_close(pRow);
        nox_sqlDisconnect();

        // That's it..
        *inlr = *on;
