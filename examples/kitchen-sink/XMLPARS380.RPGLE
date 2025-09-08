        
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *
        
        /include xmlparser
        Dcl-S pxml         Pointer;
        Dcl-S pList        Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S n            Varchar(50);
        Dcl-S v            Varchar(50);
      
        //------------------------------------------------------------- *

        pxml  = nox_ParseString (
           '<a>                    '+
           '  <b atr="x"/>         '+
           '  <b atr="y"/>         '+
           '  <b atr="x"/>"        '+
           '</a>'
        );

        if nox_Error(pxml) ;
           msg = nox_Message(pxml);
           nox_dump(pxml);
           nox_Close(pxml);
           return;
        endif;

        pList  = nox_locate(pxml : '/a/b[0]');
        dow pList <> *null;
           n = nox_GetName (plist);
           v = nox_GetValue(pList : '@atr');
           pList = nox_getnext(pList);
        enddo;

        nox_Close(pxml);
        *inlr = *on;
