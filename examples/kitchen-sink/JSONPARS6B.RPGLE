
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

        //------------------------------------------------------------- *
        
        pJson = nox_ParseString ('{}');

        if nox_Error(pJson) ;
           msg = nox_Message(pJson);
           nox_dump(pJson);
           nox_Close(pJson);
           return;
        endif;

        nox_SetValue ( pJson : '/o/a[0]': '10');
        nox_SetValue ( pJson : '/o/a[1]': '20');

        po = nox_Locate   ( pJson : '/o/a') ;  // The array it self
        value = nox_getStr ( po : '[UBOUND]');
        nox_SetValue ( po    : '[3]': '30');
        value = nox_getStr ( po : '[UBOUND]');
        nox_SetValue ( po    : '[UBOUND]': '40'); // This will not work !!!
        value = nox_getStr ( po : '[UBOUND]'); // So UBOUND is still 3

        nox_WriteStmf  (pJson   : './jsonout.json' : 1208 : *OFF);

        nox_dump(pJson);
        nox_Close(pJSON);
        *inlr = *on;
