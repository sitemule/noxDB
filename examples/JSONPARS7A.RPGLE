
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S s            Varchar(50);
        Dcl-S i            Int(10);

        //------------------------------------------------------------- *

        pJson = json_ParseString ('[1,2,3]');

        // Get number of entries in arrays
        i     = json_getNum       (pJson : '/[UBOUND]': -1 );
        s     = json_getStr       (pJson : '/[0]'     : 'N/A' );
        s     = json_getStr       (pJson : '[1]'      : 'N/A' );

        json_WriteStmf  (pJson   : '/www/systest/jsonout.json' : 1208 : *OFF);
        json_dump(pJson);
        json_Close(pJson);
        *inlr = *on;
