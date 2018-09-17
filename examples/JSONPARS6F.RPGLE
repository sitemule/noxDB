
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

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
        pJson1 = Json_ParseString ('{a:[1,2]}');
        pJson2 = Json_ParseString ('{b:[8,9]}');

        Json_WriteStmf (pJson1: './jsonout1.json' : 1208 : *OFF);
        Json_WriteStmf (pJson2: './jsonout2.json' : 1208 : *OFF);

        Json_merge (pJson1 : pJson2 : Json_DONTREPLACE);
        Json_WriteStmf (pJson1:'./jsonout-merge.json':1208:*OFF);
        Json_Close(pJson1);
        Json_Close(pJson2);
