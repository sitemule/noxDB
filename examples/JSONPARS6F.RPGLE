
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
      
        Dcl-S pJson1       Pointer;
        Dcl-S pJson2       Pointer;
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

        *inlr = *on;
        pJson1 = Nox_ParseString ('{a:[1,2]}');
        pJson2 = Nox_ParseString ('{b:[8,9]}');

        Nox_WriteStmf (pJson1: './jsonout1.json' : 1208 : *OFF);
        Nox_WriteStmf (pJson2: './jsonout2.json' : 1208 : *OFF);

        Nox_merge (pJson1 : pJson2 : Nox_DONTREPLACE);
        Nox_WriteStmf (pJson1:'./jsonout-merge.json':1208:*OFF);
        Nox_Close(pJson1);
        Nox_Close(pJson2);
