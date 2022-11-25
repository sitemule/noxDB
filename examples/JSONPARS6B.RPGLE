
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE' );

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

        //------------------------------------------------------------- *
        
        pJson = json_ParseString ('{}');

        if json_Error(pJson) ;
           msg = json_Message(pJson);
           json_dump(pJson);
           json_Close(pJson);
           return;
        endif;

        json_SetValue ( pJson : '/o/a[0]': '10');
        json_SetValue ( pJson : '/o/a[1]': '20');

        po = json_Locate   ( pJson : '/o/a') ;  // The array it self
        value = json_getStr ( po : '[UBOUND]');
        json_SetValue ( po    : '[3]': '30');
        value = json_getStr ( po : '[UBOUND]');
        json_SetValue ( po    : '[UBOUND]': '40'); // This will not work !!!
        value = json_getStr ( po : '[UBOUND]'); // So UBOUND is still 3

        json_WriteStmf  (pJson   : './jsonout.json' : 1208 : *OFF);

        json_dump(pJson);
        json_Close(pJSON);
        *inlr = *on;
