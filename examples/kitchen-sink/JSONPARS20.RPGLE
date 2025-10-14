
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
        Dcl-S msg          Varchar(50);
        Dcl-S tag          Varchar(50);
        Dcl-S value        Varchar(50);
        Dcl-S n            Packed(15:2);
        Dcl-S isnull       Ind;

        //------------------------------------------------------------- *
        
        pJson = nox_ParseString ('{isnull:null}');

        if nox_Error(pJson) ;
           msg = nox_Message(pJson);
           nox_dump(pJson);
           nox_Close(pJson);
           return;
        endif;

        value = nox_getStr ( pJson : 'isnull');
        isnull = nox_isnull(pJson : 'isnull');
        nox_Close(pJSON);
        *inlr = *on;
