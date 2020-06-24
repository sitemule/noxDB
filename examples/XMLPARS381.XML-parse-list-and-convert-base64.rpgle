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

          p1 = ILOB_OpenPersistant('QTEMP':'P1': 4096:0);
          p2 = ILOB_OpenPersistant('QTEMP':'P2': 4096:0);

          pList  = xml_locate(pxml : '/a/b[0]');
          DoW pList <> *null;
             name = xml_GetValue(plist : '@name');
             xml_GetIlobValue(p1:pList : '@atr' );
             // Decode the BASE64 and save the binary contents
             ilob_Base64Decode(p2:p1);
             ilob_SaveToBinaryStream(p2:name );
             pList = xml_getnext(pList);
          EndDo;

          xml_delete(pxml);
          *inlr = *on;
