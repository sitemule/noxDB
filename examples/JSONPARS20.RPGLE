
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
        Dcl-S msg          Varchar(50);
        Dcl-S tag          Varchar(50);
        Dcl-S value        Varchar(50);
        Dcl-S n            Packed(15:2);
        Dcl-S isnull       Ind;

        //------------------------------------------------------------- *
        
        pJson = json_ParseString ('{isnull:null}');

        if json_Error(pJson) ;
           msg = json_Message(pJson);
           json_dump(pJson);
           json_Close(pJson);
           return;
        endif;

        value = json_getStr ( pJson : 'isnull');
        isnull = json_isnull(pJson : 'isnull');
        json_Close(pJSON);
        *inlr = *on;
