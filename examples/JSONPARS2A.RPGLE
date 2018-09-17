
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pJson        Pointer;
        Dcl-S pNode        Pointer;
        Dcl-S pArr         Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S tag          Varchar(50);
        Dcl-S value        Varchar(50);
        Dcl-S n            Packed(15:2);

        //------------------------------------------------------------- *
        
        pJson = JSON_ParseString (
           '{                                             '+
           '   "e"  :"Quote\"line1\nline2\rtab\ttabed",   '+
           '   "123":"Key can be numeric"             ,   '+
           '   "ÆØÅ":"And with national chars"            '+
           '}'
        );

        if JSON_Error(pJson) ;
           msg = JSON_Message(pJson);
           JSON_dump(pJson);
           JSON_Close(pJson);
           return;
        endif;

        json_WriteStmf( pJson: './dump-payload.json': 1208 : *OFF);
        pNode = JSON_locate(pJson: '/e');
        value = json_getStr  (pNode);

        // Get value for at numeric key
        value = json_getStr  (pJson: %char(123));

        // Get value for at national chars
        value = json_getStr  (pJson: 'ÆØÅ');

        JSON_Close(pJSON);
        *inlr = *on;
