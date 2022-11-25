
        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE' );

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pJson        Pointer;
        
        Dcl-C OB Const(x'9E');
        Dcl-C CB Const(x'9F');

        Dcl-C OS Const(x'9C');
        Dcl-C CS Const(x'47');
        
        //------------------------------------------------------------- *

        Dcl-Pi JSON12;
          pResult Char(50);
        End-Pi;

        pJson = JSON_ParseString (
           OS+
           '  u:"string", '+
           '   "s":null, '+
           '   a:' + OB + '1,2,3' + CB +
           CS
             : '');

        if JSON_Error(pJson) ;
           pResult = JSON_Message(pJson);
           JSON_dump(pJson);
           JSON_delete(pJson);
           return;
        endif;

        pResult = json_AsText(pJson);
        JSON_delete(pJSON);
        *inlr = *on;
