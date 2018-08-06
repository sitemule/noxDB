        //------------------------------------------------------------- *
        //This sample shows the use of the buildin JSONparser in
        //IceBreak


        //------------------------------------------------------------- *
        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );
        Dcl-S pJson        Pointer;
        Dcl-S pA           Pointer;
        Dcl-S pB           Pointer;
        Dcl-S aCount       Int(10);
        Dcl-S bCount       Int(10);
      /include 'headers/JSONPARSER.rpgle'
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
