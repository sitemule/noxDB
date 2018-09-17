
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

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
        pJson = JSON_ParseString (
           '{                      '+
           '  a:123,               '+
           '  b:"text",            '+
           '  c:"More text"        '+
           '}'
             : '');
        if JSON_Error(pJson) ;
           msg = JSON_Message(pJson);
           JSON_dump(pJson);
           JSON_Close(pJson);
           return;
        endif;
        pRcv  = JSON_ParseString ('{}');

        pO = json_SetValue(pRcv : '/row' : pJson: JSON_OBJREPLACE);

        pKey  = JSON_ParseString ('{ key: "123" }');
        pO = json_SetValue(pRcv : '/key' : pKey : JSON_OBJREPLACE);

        JSON_dump(pRcv );
        json_WriteStmf  (pRcv : '/www/systest/jsonout.json' : 1208 : *OFF);
        JSON_Close(pJSON);
        JSON_Close(pKey );
        JSON_Close(pRcv );
        *inlr = *on;
