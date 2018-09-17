        //------------------------------------------------------------- *
        //This sample shows the use of the buildin JSONparser in
        //IceBreak

        //Using SQL cursors

        //on a table like this:
        //create table QGPL/NOTES (
        //id     int generated always as Identity,
        //title  varchar(256)     not null with default,
        //text1  blob             not null with default,
        //text2  blob             not null with default
        //)

        //trace: CHGCPATRC JOBNUMBER(*CURRENT) SEV(*INFO)
        //DSPCPATRC

        //http://www-03.ibm.com/systems/power/software/i/db2/support/tips/clifaq.
        //------------------------------------------------------------- *
        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

        Dcl-S err          Ind;
        Dcl-S pNote1       Pointer;
        Dcl-S pNote2       Pointer;
        Dcl-S pRow         Pointer;
        Dcl-S id           Uns(10);
        Dcl-S text1        Char(32766);
        Dcl-S text2        Char(32766);

      /include 'headers/JSONPARSER.rpgle'

        // Advanced: - update using json object as a row
        // This also works for BLOBS and CLOB columns

        text1 = *all'x';
        %subst (text1    : 1 : 15    )  = 'First clob';
        %subst (text1    : 32000: 1  )  = x'00';
        pNote1 = %addr(text1);

        text2 = *all'y';
        %subst (text2    : 1 : 15    )  = 'Next clob';
        %subst (text2    : 32000 : 1 )  = x'00';
        pNote2 = %addr(text2);
        pRow  = json_newObject();

        json_setStr(pRow:  'title'    : 'My first note');
        json_setPtr(pRow:  'text1'    : pNote1);
        json_setPtr(pRow:  'text2'    : pNote2);

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
