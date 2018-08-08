        //------------------------------------------------------------- *
        //Json - XML and more.

        //Join an array and return is as string

        //------------------------------------------------------------- *
        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );
      /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S msg          Varchar(50);

        *inlr = *on;

        pJson = json_ParseString ('                                -
          {                                                        -
             arr1: [                                               -
                "The ",                                            -
                "little ",                                         -
                "brown fox"                                        -
             ]                                                     -
          }                                                        -
        ');

        // Glue all array elements together as one string
        msg = json_getStrJoin(pJson : 'arr1' );
        dsply msg;

        json_close(pJson);
