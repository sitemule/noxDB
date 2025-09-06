
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S s            Varchar(50);
        Dcl-S i            Int(10);

        //------------------------------------------------------------- *

        pJson = nox_ParseString ('{a:[1,2,3]}');
        if NOX_Error(pJson) ;
           msg = NOX_Message(pJson);
           NOX_dump(pJson);
           NOX_Close(pJson);
           return;
        endif;
        // Get number of entries in arrays
        i     = nox_getNum  (pJson : '/a[UBOUND]': -1 );
        i     = nox_getNum  (pJson : 'a[UBOUND]' : -1 );
        s     = nox_getStr  (pJson : '/a[0]'     : 'N/A' );

        // 0 in the root is the "a" object. Bothe works
        s     = nox_getStr  (pJson : '[0]/[1]'   : 'N/A' );
        s     = nox_getStr  (pJson : '[0][1]'   : 'N/A' );

        nox_WriteStmf  (pJson   : '/www/systest/jsonout.json' : 1208 : *OFF);
        nox_dump(pJson);
        nox_Close(pJson);
        *inlr = *on;
