
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

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

        Nox_MemStat();

        // The destination object for our SQL result row
        // and the array to contain the rows
        resultArray  = nox_newArray ();

        prodRow    = nox_newObject ();
        nox_setValue(prodRow :'n' : 'abc'  );

        Nox_MemStat();
        nox_setValue(resultArray: '[]' : prodRow: NOX_OBJMOVE);
        Nox_MemStat();
        nox_close(resultArray);

        Nox_MemStat();

        // That's it..
        *inlr = *on;
