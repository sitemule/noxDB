
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S pA           Pointer;
        Dcl-S pB           Pointer;
        Dcl-S aCount       Int(10);
        Dcl-S bCount       Int(10);

        //------------------------------------------------------------- *
        
        pJson = nox_parseString('                 -
            {                                      -
               a :{                                -
                  x:1,                             -
                  y:2,                             -
                  z:3                              -
               },                                  -
               b: [9,8,7,6,5,4,3,2,1]              -
            }                                      -
        ');

        // Direct with "getLength"
        pA = nox_locate(pJson : 'a');
        aCount = nox_getLength(pA);

        // Direct with expression
        aCount = nox_GetInt(pJson : 'a[UBOUND]');

        // Relative
        pA = nox_locate(pJson : 'a');
        aCount = nox_GetInt(pA : '[UBOUND]');

        // Direct
        bCount = nox_GetInt(pJson : 'b[UBOUND]');

        // Relative
        pB = nox_locate(pJson : 'b');
        bCount = nox_GetInt(pB : '[UBOUND]');

        nox_Close(pJson);
        *inlr = *on;
