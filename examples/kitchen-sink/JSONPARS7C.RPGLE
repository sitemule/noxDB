
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *
        
        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S msg          Varchar(50);

        //------------------------------------------------------------- *

        *inlr = *on;

        pJson = nox_ParseString ('                                -
          {                                                        -
             arr1: [                                               -
                "The ",                                            -
                "little ",                                         -
                "brown fox"                                        -
             ]                                                     -
          }                                                        -
        ');

        // Glue all array elements together as one string
        msg = nox_getStrJoin(pJson : 'arr1' );
        dsply msg;

        nox_close(pJson);
