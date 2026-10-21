
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

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
        
        pJson = NOX_ParseString (
           '{                                             '+
           '   "e"  :"Quote\"line1\nline2\rtab\ttabed",   '+
           '   "123":"Key can be numeric"             ,   '+
           '   "ÆØÅ":"And with national chars"            '+
           '}'
        );

        if NOX_Error(pJson) ;
           msg = NOX_Message(pJson);
           NOX_dump(pJson);
           NOX_Close(pJson);
           return;
        endif;

        nox_WriteStmf( pJson: './dump-payload.json': 1208 : *OFF);
        pNode = NOX_locate(pJson: '/e');
        value = nox_getStr  (pNode);

        // Get value for at numeric key
        value = nox_getStr  (pJson: %char(123));

        // Get value for at national chars
        value = nox_getStr  (pJson: 'ÆØÅ');

        NOX_Close(pJSON);
        *inlr = *on;
