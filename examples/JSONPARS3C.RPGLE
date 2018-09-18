
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S pA           Pointer;
        Dcl-S pB           Pointer;
        Dcl-S aCount       Int(10);
        Dcl-S bCount       Int(10);

        //------------------------------------------------------------- *
        
        pJson = json_parseString('                 -
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
        pA = json_locate(pJson : 'a');
        aCount = json_getLength(pA);

        // Direct with expression
        aCount = json_getNum(pJson : 'a[UBOUND]');

        // Relative
        pA = json_locate(pJson : 'a');
        aCount = json_getNum(pA : '[UBOUND]');

        // Direct
        bCount = json_getNum(pJson : 'b[UBOUND]');

        // Relative
        pB = json_locate(pJson : 'b');
        bCount = json_getNum(pB : '[UBOUND]');

        json_Close(pJson);
        *inlr = *on;
