
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
        nox_SetValue ( pJson : '/o/a[0]':
          '{x:123,y:456}': NOX_EVAL );
        nox_SetValue ( pJson : '/o/a[1]':
          '{x:444,y:555}': NOX_EVAL );
        nox_SetValue ( pJson : '/o/e':
          '{s:"a",t:"b"}': NOX_EVAL );

             nox_SetValue ( pJson : '/o/arr':
               '[1,2,3,4,5,6]': NOX_EVAL );

        nox_WriteStmf  (pJson   : './jsonout.json' : 1208 : *OFF);

        nox_Close(pJSON);
        *inlr = *on;
