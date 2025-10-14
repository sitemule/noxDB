
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S n            Varchar(50);
        Dcl-S v            Varchar(50);
        Dcl-DS list  likeds(nox_iterator);
        End-DS;

        //------------------------------------------------------------- *
        
        pJson = NOX_ParseString (
           '{                      '+
           '  a:123,               '+
           '  b:"text",            '+
           '  c:"More text"        '+
           '}'
             : '');
        if NOX_Error(pJson) ;
           msg = NOX_Message(pJson);
           NOX_dump(pJson);
           NOX_Close(pJson);
           return;
        endif;

        list = nox_setIterator(pJson);
        dow nox_ForEach(list);
           n = nox_GetName (list.this);
           v = nox_GetValue(list.this);
        enddo;

        NOX_Close(pJSON);
        *inlr = *on;
