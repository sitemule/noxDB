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

        p1 = ILOB_OpenPersistant('QTEMP':'P1': 4096:0);
        p2 = ILOB_OpenPersistant('QTEMP':'P2': 4096:0);

        pList  = xml_locate(pxml : '/a/b[0]');
        dow pList <> *null;
           name = xml_GetValue(plist : '@name');
           xml_GetIlobValue(p1:pList : '@atr' );
           // Decode the BASE64 and save the binary contents
           ilob_Base64Decode(p2:p1);
           ilob_SaveToBinaryStream(p2:name );
           pList = xml_getnext(pList);
        enddo;

        xml_Close(pxml);
        *inlr = *on;
