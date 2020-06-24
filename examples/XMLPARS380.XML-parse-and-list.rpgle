       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );
       Dcl-S pxml               Pointer;
       Dcl-S pList              Pointer;
       Dcl-S msg                VarChar(50);
       Dcl-S n                  VarChar(50);
       Dcl-S v                  VarChar(50);
      /include xmlparser

          pxml  = xml_ParseString (
               '<a>                    '+
               '  <b atr="x"/>         '+
               '  <b atr="y"/>         '+
               '  <b atr="x"/>"        '+
               '</a>'
            );

          If xml_Error(pxml) ;
             msg = xml_Message(pxml);
             xml_dump(pxml);
             xml_delete(pxml);
             Return;
          EndIf;

          pList  = xml_locate(pxml : '/a/b[0]');
          DoW pList <> *null;
             n = xml_GetName (plist);
             v = xml_GetValue(pList : '@atr');
             pList = xml_getnext(pList);
          EndDo;

          xml_delete(pxml);
          *inlr = *on;
