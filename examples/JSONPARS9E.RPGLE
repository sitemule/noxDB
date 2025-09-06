
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE');

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S name         Varchar(10);
        Dcl-S value        Varchar(40);
        Dcl-DS list  likeds(nox_iterator);
        End-DS;

        //------------------------------------------------------------- *

        pJson = nox_ParseString('{ a: 1, b : { c: 2 ,d : 3}}');

        if nox_Error(pJson) ;
           msg = nox_Message(pJson);
           nox_dump(pJson);
           nox_Close(pJson);
           return;
        endif;

        list = nox_setRecursiveIterator(pJson);
        dow nox_ForEach(list);
           name  = nox_GetNameAsPath(list.this:'.');
           value = nox_GetValue (list.this);
           dsply (name + value);
        enddo;

        nox_Close(pJSON);
        *inlr = *on;
