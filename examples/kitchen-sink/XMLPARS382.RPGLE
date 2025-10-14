        
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('XMLPARSER' : 'ICEBREAK') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include xmlparser
        /include qasphdr,ilob
        Dcl-S pxml         Pointer;
        Dcl-S pList        Pointer;
        Dcl-S p1           Pointer;
        Dcl-S p2           Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S name         Varchar(50);

        //------------------------------------------------------------- *

        pxml  = nox_ParseString (
           '<a>                    '+
           '  <b atr="AaAa" name="a.jpg"/>    '+
           '  <b atr="BbBb" name="b.jpg"/>    '+
           '  <b atr="CcCc" name="c.jpg"/>    '+
           '</a>'
        );

        if nox_Error(pxml) ;
           msg = nox_Message(pxml);
           nox_dump(pxml);
           nox_Close(pxml);
           return;
        endif;

        name = nox_GetStr(pxml : '/a/b[@atr=BbBb]');

        nox_Close(pxml);
        *inlr = *on;
