
        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pJson        Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S n            Varchar(50);
        Dcl-S v            Varchar(50);

        Dcl-S Result Varchar(50);

        Dcl-DS list  likeds(json_iterator);

        Dcl-C OS Const(x'9C');
        Dcl-C CS Const(x'47');

        //------------------------------------------------------------- *

        dcl-pi *N;
          pResult Char(50);
        End-Pi;

        Result = '';
        pJson = JSON_ParseString (
           OS+
           '  a:123,               '+
           '  b:"text",            '+
           '  c:"More text"        '+
           CS
             : '');

        if JSON_Error(pJson) ;
           pResult = JSON_Message(pJson);
           JSON_dump(pJson);
           JSON_delete(pJson);
           return;
        endif;

        list = json_setIterator(pJson);
        dow json_ForEach(list);
           n = json_GetName(list.this);
           v = json_GetValue(list.this);
           Result += n + ':' + v + '-';
        enddo;

        pResult = Result;

        JSON_delete(pJSON);
        *inlr = *on;
