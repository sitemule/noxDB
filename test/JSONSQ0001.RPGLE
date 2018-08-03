      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin JSONparser in
      * IceBreak
      *
      * Using SQL cursors
      *
      *  trace: CHGCPATRC JOBNUMBER(*CURRENT) SEV(*INFO)
      *         DSPCPATRC
      *
      *  http://www-03.ibm.com/systems/power/software/i/db2/support/tips/clifaq.html
      * ------------------------------------------------------------- *
     H BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' )
     D err             s               n
     D row             s          32766    varying
     D prow            s               *
     D id              s             10i 0

      /include 'headers/JSONPARSER.rpgle'
      /free

         row = ('{ -
            title: "tesing",                             -
            text1: {da:"Dansk Tekst" , en:"English"}     -
         }');

         err = json_sqlInsert  (
            'qgpl/note2'
            :row
         );

         // get ret unique ID generated
         id = json_sqlGetInsertId();

         // now get that row: here we use the a stringed obje
         pRow = json_sqlResultRow (('  -
               select * from qgpl/note2  -
               where id = $id           -
            ')
            :'{id:' + %char(id) +'}'
        );

        // manipulate data:
        json_setStr(pRow : 'text1.fr' : 'aussi en français');
        err = json_sqlUpdate(
           'qgpl/note2'
           :pRow                // the text object is updated with a extra tag
           :'where  id = $id'   // the where uses atemplate to the id, and the i
           :pRow
        );

        // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnec
        json_close(pRow);
        json_sqlDisconnect();

        // That's it..
        *inlr = *on;
