
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S name         Varchar(10);
        Dcl-S value        Varchar(40);
        Dcl-DS list  likeds(json_iterator);
        End-DS;

        //------------------------------------------------------------- *

        pJson = json_ParseString('{ a: 1, b : { c: 2 ,d : 3}}');

        if json_Error(pJson) ;
           msg = json_Message(pJson);
           json_dump(pJson);
           json_Close(pJson);
           return;
        endif;

        list = json_setRecursiveIterator(pJson);
        dow json_ForEach(list);
           name  = json_GetNameAsPath(list.this:'.');
           value = json_GetValue (list.this);
           dsply (name + value);
        enddo;

        json_Close(pJSON);
        *inlr = *on;
