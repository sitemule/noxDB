
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson1       Pointer;
        Dcl-S pJson2       Pointer;
        Dcl-S msg          Varchar(50);

        //------------------------------------------------------------- *

        *inlr = *on;

        pJson1 = Nox_ParseString ('                            -
           {                                                    -
              x : {                                             -
                a : 1                                           -
              }                                                 -
           }                                                    -
        ');

        pJson2 = Nox_ParseString ('                            -
           {                                                    -
              x : {                                             -
                b : 2                                           -
              }                                                 -
           }                                                    -
        ');

        Nox_merge (pJson1 : pJson2  : Nox_DONTREPLACE);

        Nox_WriteStmf (pJson1:'./jsonout-merge-6i.json':1208:*OFF);
        Nox_Close(pJson1);
        Nox_Close(pJson2);
