      * ------------------------------------------------------------- *
     H BndDir('XMLPARSER' : 'ICEBREAK') dftactgrp(*NO) ACTGRP('QILE' )
     D pxml            s               *
     D pList           s               *
     D p1              s               *
     D p2              s               *
     D msg             s             50    varying
     D name            s             50    varying
      /include xmlparser
      /include qasphdr,ilob
      /free

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
