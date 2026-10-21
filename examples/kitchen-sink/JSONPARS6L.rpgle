
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S n            Varchar(50);
        Dcl-S e            Varchar(50);
        Dcl-S outstr       Varchar(1024);

        //------------------------------------------------------------- *

        pJson = nox_ParseString ('{ e: "" , n: null }');

        if nox_Error(pJson) ;
           msg = nox_Message(pJson);
           nox_dump(pJson);
           nox_Close(pJson);
           return;
        endif;

        e = nox_getValue(pJson : 'e');
        n = nox_getValue(pJson : 'n' );

        outstr = nox_asJsonText(pJson);
        
        nox_Close(pJSON);
        *inlr = *on;
