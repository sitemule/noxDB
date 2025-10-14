        
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

        p1 = ILOB_OpenPersistant('QTEMP':'P1': 4096:0);
        p2 = ILOB_OpenPersistant('QTEMP':'P2': 4096:0);

        pList  = nox_locate(pxml : '/a/b[0]');
        dow pList <> *null;
           name = nox_GetValue(plist : '@name');
           nox_GetIlobValue(p1:pList : '@atr' );
           // Decode the BASE64 and save the binary contents
           ilob_Base64Decode(p2:p1);
           ilob_SaveToBinaryStream(p2:name );
           pList = nox_getnext(pList);
        enddo;

        nox_Close(pxml);
        *inlr = *on;
