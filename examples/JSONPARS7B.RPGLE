
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S s            Varchar(50);
        Dcl-S i            Int(10);

        //------------------------------------------------------------- *

        pJson = json_ParseString ('{a:[1,2,3]}');
        if JSON_Error(pJson) ;
           msg = JSON_Message(pJson);
           JSON_dump(pJson);
           JSON_Close(pJson);
           return;
        endif;
        // Get number of entries in arrays
        i     = json_getNum  (pJson : '/a[UBOUND]': -1 );
        i     = json_getNum  (pJson : 'a[UBOUND]' : -1 );
        s     = json_getStr  (pJson : '/a[0]'     : 'N/A' );

        // 0 in the root is the "a" object. Bothe works
        s     = json_getStr  (pJson : '[0]/[1]'   : 'N/A' );
        s     = json_getStr  (pJson : '[0][1]'   : 'N/A' );

        json_WriteStmf  (pJson   : '/www/systest/jsonout.json' : 1208 : *OFF);
        json_dump(pJson);
        json_Close(pJson);
        *inlr = *on;
