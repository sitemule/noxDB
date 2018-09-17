
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S n            Varchar(50);
        Dcl-S e            Varchar(50);
        Dcl-S outstr       Varchar(1024);

        //------------------------------------------------------------- *

        pJson = json_ParseString ('{ e: "" , n: null }');

        if json_Error(pJson) ;
           msg = json_Message(pJson);
           json_dump(pJson);
           json_Close(pJson);
           return;
        endif;

        e = json_getValue(pJson : 'e');
        n = json_getValue(pJson : 'n' );

        outstr = json_asJsonText(pJson);
        
        json_Close(pJSON);
        *inlr = *on;
