
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );

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

        pJson = JSON_ParseFile ('./test/documents/demo2.json':'');

        if JSON_Error(pJson) ;
           msg = JSON_Message(pJson);
           dsply msg;
           JSON_dump(pJson);
           JSON_Close(pJson);
           return;
        endif;


        // Get number of entries in arrays
        i     = json_getNum       (pJson : '/[UBOUND]': -1 );
        s     = json_getStr       (pJson : '/[0]/s1'  : 'N/A' );
        s     = json_getStr       (pJson : '/[1]/s2'  : 'N/A' );

        JSON_dump(pJson);
        JSON_Close(pJSON);
        *inlr = *on;
