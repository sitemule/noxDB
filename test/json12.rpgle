
        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pJson        Pointer;
        
        Dcl-C OB Const(x'9E');
        Dcl-C CB Const(x'9F');

        //------------------------------------------------------------- *

        Dcl-Pi JSON12;
          pResult Char(50);
        End-Pi;

        pJson = JSON_ParseString (
           '{  u:"string", '+
           '   "s":null, '+
           '   a:' + OB + '1,2,3' + CB +
           '}'
             : '');

        if JSON_Error(pJson) ;
           pResult = JSON_Message(pJson);
           JSON_dump(pJson);
           JSON_Close(pJson);
           return;
        endif;

        pResult = json_AsText(pJson);
        JSON_Close(pJSON);
        *inlr = *on;
