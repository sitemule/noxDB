
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S pJsonTemp    Pointer;
        Dcl-S msg          Varchar(50);

        //------------------------------------------------------------- *

        *inlr = *on;
        pJson  = json_NewObject();

        pJsonTemp = Json_ParseString (
          '{"__cid__":1,"backgroundcolor":"#4400FF","design":"rl"}');
        Json_merge (pJson  : pJsonTemp : Json_DONTREPLACE);
        Json_Close(pJsonTemp);

        pJsonTemp = Json_ParseString (
          '{"__cid__":13,"name":"Den første stakside"}');
        Json_merge (pJson  : pJsonTemp : Json_DONTREPLACE);
        Json_Close(pJsonTemp);


        Json_WriteStmf (pJson:'./jsonout-merge2.json':1208:*OFF);
        Json_Close(pJson);
