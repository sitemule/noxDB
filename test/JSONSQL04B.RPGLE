      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin JSONparser in
      * IceBreak
      *
      * Using SQL cursors
      *
      * ------------------------------------------------------------- *
     H BndDir('JSONPARSER') dftactgrp(*NO) ACTGRP('QILE' )
     D manuRow         s               *
     D prodArray       s               *
     D prodRow         s               *
     D resultArray     s               *
     D resultObj       s               *
     D manuHnd         s               *
     D prodHnd         s               *
     D sql             s            512    varying

      /include 'headers/JSONPARSER.rpgle'
      /free

        Json_MemStat();

        // The destination object for our SQL result row
        // and the array to contain the rows
        resultArray  = json_newArray ();

        prodRow    = json_newObject ();
        json_setValue(prodRow :'n' : 'abc'  );

        Json_MemStat();
        json_setValue(resultArray: '[]' : prodRow: JSON_OBJMOVE);
        Json_MemStat();
        json_close(resultArray);

        Json_MemStat();

        // That's it..
        *inlr = *on;
