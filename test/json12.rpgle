
        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pJson        Pointer;

        //------------------------------------------------------------- *

        Dcl-Pi JSON12;
          pResult Char(50);
        End-Pi;

        pJson = JSON_ParseString (
           '{  u:"string", '+
           '   "s":null, '+
           '   a:[1,2,3]' +
           '}'
             : '');

        if JSON_Error(pJson) ;
           msg = JSON_Message(pJson);
           JSON_dump(pJson);
           JSON_Close(pJson);
           return;
        endif;

        pResult = json_AsText(pJson);
        JSON_Close(pJSON);
        *inlr = *on;
