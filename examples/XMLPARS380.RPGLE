        
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *
        
        /include xmlparser
        Dcl-S pxml         Pointer;
        Dcl-S pList        Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S n            Varchar(50);
        Dcl-S v            Varchar(50);
      
        //------------------------------------------------------------- *

        pxml  = xml_ParseString (
           '<a>                    '+
           '  <b atr="x"/>         '+
           '  <b atr="y"/>         '+
           '  <b atr="x"/>"        '+
           '</a>'
        );

        if xml_Error(pxml) ;
           msg = xml_Message(pxml);
           xml_dump(pxml);
           xml_Close(pxml);
           return;
        endif;

        pList  = xml_locate(pxml : '/a/b[0]');
        dow pList <> *null;
           n = xml_GetName (plist);
           v = xml_GetValue(pList : '@atr');
           pList = xml_getnext(pList);
        enddo;

        xml_Close(pxml);
        *inlr = *on;
