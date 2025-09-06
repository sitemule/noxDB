
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S pNode        Pointer;
        Dcl-S pO           Pointer;
        Dcl-S pR           Pointer;
        Dcl-S pRcv         Pointer;
        Dcl-S pArr         Pointer;
        Dcl-S pKey         Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S tag          Varchar(50);
        Dcl-S value        Varchar(50);
        Dcl-S n            Packed(15:2);

        //------------------------------------------------------------- *
        pJson = NOX_ParseString (
           '{                      '+
           '  a:123,               '+
           '  b:"text",            '+
           '  c:"More text"        '+
           '}'
             : '');
        if NOX_Error(pJson) ;
           msg = NOX_Message(pJson);
           NOX_dump(pJson);
           NOX_Close(pJson);
           return;
        endif;
        pRcv  = NOX_ParseString ('{}');

        pO = nox_SetValue(pRcv : '/row' : pJson: NOX_OBJREPLACE);

        pKey  = NOX_ParseString ('{ key: "123" }');
        pO = nox_SetValue(pRcv : '/key' : pKey : NOX_OBJREPLACE);

        NOX_dump(pRcv );
        nox_WriteStmf  (pRcv : '/www/systest/jsonout.json' : 1208 : *OFF);
        NOX_Close(pJSON);
        NOX_Close(pKey );
        NOX_Close(pRcv );
        *inlr = *on;
