      * ------------------------------------------------------------- *
     H BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' )
     D pxml            s               *
     D pList           s               *
     D msg             s             50    varying
     D n               s             50    varying
     D v               s             50    varying
      /include xmlparser
      /free

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
