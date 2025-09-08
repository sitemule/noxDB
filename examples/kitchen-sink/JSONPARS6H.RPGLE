
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S pJsonTemp    Pointer;
        Dcl-S msg          Varchar(50);

        //------------------------------------------------------------- *

        *inlr = *on;
        pJson  = nox_NewObject();

        pJsonTemp = Nox_ParseString (
          '{"__cid__":1,"backgroundcolor":"#4400FF","design":"rl"}');
        Nox_merge (pJson  : pJsonTemp : Nox_DONTREPLACE);
        Nox_Close(pJsonTemp);

        pJsonTemp = Nox_ParseString (
          '{"__cid__":13,"name":"Den første stakside"}');
        Nox_merge (pJson  : pJsonTemp : Nox_DONTREPLACE);
        Nox_Close(pJsonTemp);


        Nox_WriteStmf (pJson:'./jsonout-merge2.json':1208:*OFF);
        Nox_Close(pJson);
