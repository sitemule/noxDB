        
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

        pxml  = xml_ParseString (
           '<a>                    '+
           '  <b atr="AaAa" name="a.jpg"/>    '+
           '  <b atr="BbBb" name="b.jpg"/>    '+
           '  <b atr="CcCc" name="c.jpg"/>    '+
           '</a>'
        );

        if xml_Error(pxml) ;
           msg = xml_Message(pxml);
           xml_dump(pxml);
           xml_Close(pxml);
           return;
        endif;

        name = xml_GetStr(pxml : '/a/b[@atr=BbBb]');

        xml_Close(pxml);
        *inlr = *on;
