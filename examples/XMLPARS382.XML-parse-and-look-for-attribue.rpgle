       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB' : 'ICEBREAK') dftactgrp(*NO) ACTGRP('QILE';
       Dcl-S pxml               Pointer;
       Dcl-S pList              Pointer;
       Dcl-S p1                 Pointer;
       Dcl-S p2                 Pointer;
       Dcl-S msg                VarChar(50);
       Dcl-S name               VarChar(50);
      /include xmlparser
      /include QRPGLEREF,ilob

          pxml  = xml_ParseString (
               '<a>                    '+
               '  <b atr="AaAa" name="a.jpg"/>    '+
               '  <b atr="BbBb" name="b.jpg"/>    '+
               '  <b atr="CcCc" name="c.jpg"/>    '+
               '</a>'
            );

          If xml_Error(pxml) ;
             msg = xml_Message(pxml);
             xml_dump(pxml);
             xml_delete(pxml);
             Return;
          EndIf;

          name = xml_GetStr(pxml : '/a/b[@atr=BbBb]');

          xml_delete(pxml);
          *inlr = *on;
