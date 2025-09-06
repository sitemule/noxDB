
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S s            Varchar(50);
        Dcl-S i            Int(10);

        //------------------------------------------------------------- *

        pJson = nox_ParseString ('[1,2,3]');

        // Get number of entries in arrays
        i     = nox_getNum       (pJson : '/[UBOUND]': -1 );
        s     = nox_getStr       (pJson : '/[0]'     : 'N/A' );
        s     = nox_getStr       (pJson : '[1]'      : 'N/A' );

        nox_WriteStmf  (pJson   : '/www/systest/jsonout.json' : 1208 : *OFF);
        nox_dump(pJson);
        nox_Close(pJson);
        *inlr = *on;
