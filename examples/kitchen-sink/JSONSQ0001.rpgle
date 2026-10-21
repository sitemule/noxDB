        
        //------------------------------------------------------------- *

        //Using SQL cursors

        //trace: CHGCPATRC JOBNUMBER(*CURRENT) SEV(*INFO)
        //DSPCPATRC

        //http://www-03.ibm.com/systems/power/software/i/db2/support/tips/clifaq.

        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S err          Ind;
        Dcl-S row          Varchar(32766);
        Dcl-S prow         Pointer;
        Dcl-S id           Int(10);

        //------------------------------------------------------------- *

         row = ('{ -
            title: "tesing",                             -
            text1: {da:"Dansk Tekst" , en:"English"}     -
         }');

         err = nox_sqlInsert  (
            'qgpl/note2'
            :row
         );

         // get ret unique ID generated
         id = nox_sqlGetInsertId();

         // now get that row: here we use the a stringed obje
         pRow = nox_sqlResultRow (('  -
               select * from qgpl/note2  -
               where id = $id           -
            ')
            :'{id:' + %char(id) +'}'
        );

        // manipulate data:
        nox_setStr(pRow : 'text1.fr' : 'aussi en français');
        err = nox_sqlUpdate(
           'qgpl/note2'
           :pRow                // the text object is updated with a extra tag
           :'where  id = $id'   // the where uses atemplate to the id, and the i
           :pRow
        );

        // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnec
        nox_close(pRow);
        nox_sqlDisconnect();

        // That's it..
        *inlr = *on;
