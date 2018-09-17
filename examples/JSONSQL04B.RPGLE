
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S manuRow      Pointer;
        Dcl-S prodArray    Pointer;
        Dcl-S prodRow      Pointer;
        Dcl-S resultArray  Pointer;
        Dcl-S resultObj    Pointer;
        Dcl-S manuHnd      Pointer;
        Dcl-S prodHnd      Pointer;
        Dcl-S sql          Varchar(512);

        //------------------------------------------------------------- *

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
