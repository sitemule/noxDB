
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S pNode        Pointer;
        Dcl-S pArr         Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S tag          Varchar(50);
        Dcl-S s            Varchar(50);
        Dcl-S n            Packed(15:2);
        Dcl-S i            Int(10);

        //------------------------------------------------------------- *

        pJson = NOX_ParseFile ('./test/documents/demo2.json':'');

        if NOX_Error(pJson) ;
           msg = NOX_Message(pJson);
           dsply msg;
           NOX_dump(pJson);
           NOX_Close(pJson);
           return;
        endif;


        // Get number of entries in arrays
        i     = nox_getNum       (pJson : '/[UBOUND]': -1 );
        s     = nox_getStr       (pJson : '/[0]/s1'  : 'N/A' );
        s     = nox_getStr       (pJson : '/[1]/s2'  : 'N/A' );

        NOX_dump(pJson);
        NOX_Close(pJSON);
        *inlr = *on;
