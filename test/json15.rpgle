
        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pJson        Pointer;
        Dcl-S n            Varchar(50);
        Dcl-S v            Varchar(50);
        Dcl-DS list  likeds(json_iterator);
        End-DS;

        Dcl-S Result Varchar(50);

        //------------------------------------------------------------- *

        Result = '';
        pJson = JSON_ParseString (
           '{                      '+
           '  a:123,               '+
           '  b:"text",            '+
           '  c:"More text",       '+
           '  d:{                  '+
           '    d1:"D1 text",      '+
           '    d2:"D2 text",      '+
           '  }                    '+
           '}');

        if JSON_Error(pJson) ;
           pResult = JSON_Message(pJson);
           JSON_dump(pJson);
           JSON_Close(pJson);
           return;
        endif;

        list = json_setRecursiveIterator(pJson:'d');
        dow json_ForEach(list);
           n = json_GetName(list.this);
           v = json_GetValue(list.this);
           Result += n + ':' + v + '-';
        enddo;

        pResult = Result;

        JSON_Close(pJSON);
        *inlr = *on;
