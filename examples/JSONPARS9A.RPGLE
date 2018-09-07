
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S n            Varchar(50);
        Dcl-S v            Varchar(50);
        Dcl-DS list  likeds(json_iterator);
        End-DS;

        //------------------------------------------------------------- *
        
        pJson = JSON_ParseString (
           '{                      '+
           '  a:123,               '+
           '  b:"text",            '+
           '  c:"More text"        '+
           '}'
             : '');
        if JSON_Error(pJson) ;
           msg = JSON_Message(pJson);
           JSON_dump(pJson);
           JSON_Close(pJson);
           return;
        endif;

        list = json_setIterator(pJson);
        dow json_ForEach(list);
           n = json_GetName (list.this);
           v = json_GetValue(list.this);
        enddo;

        JSON_Close(pJSON);
        *inlr = *on;
