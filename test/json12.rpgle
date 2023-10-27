
        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pJson        Pointer;

        Dcl-C OB Const(x'9E');
        Dcl-C CB Const(x'9F');

        Dcl-C OS Const(x'9C');
        Dcl-C CS Const(x'47');

        //------------------------------------------------------------- *

        dcl-pi *N;
          pResult Char(50);
        End-Pi;

        pJson = json_ParseString (
           OS+
           '  u:"string", '+
           '   "s":null, '+
           '   a:' + OB + '1,2,3' + CB +
           CS
             : '');

        if json_Error(pJson) ;
           pResult = json_Message(pJson);
           json_dump(pJson);
           json_delete(pJson);
           return;
        endif;

        pResult = json_asJsonText(pJson);
        json_delete(pJSON);
        *inlr = *on;
