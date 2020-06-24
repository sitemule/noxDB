       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB' : 'ICEBREAK') dftactgrp(*NO) ACTGRP('QILE';
       Dcl-S pXml               Pointer;
       Dcl-S pElem              Pointer;
       Dcl-S p1                 Pointer;
       Dcl-S len                int(10);
       Dcl-S msg                VarChar(50);
       Dcl-S s                  VarChar(32766);
      /include xmlparser
      /include QRPGLEREF,ilob

          pxml  = xml_ParseFile('/noxdb/xml/XmlSample2.xml');

          If xml_Error(pxml) ;
             msg = xml_Message(pxml);
             xml_dump(pxml);
             xml_delete(pxml);
             Return;
          EndIf;

          // Handle the sixth element
          pElem  = xml_locate(pxml : '/Myroot/Myelement[5]');

          // Strings
          s = xml_AsXmlText (pElem);

          // as memory - here ILOB, but any memory will do
          p1 = ILOB_OpenPersistant('QTEMP':'P1': 4096:0);
          len = xml_AsXmlTextMem ( pElem : p1);
          ilob_setLength(p1 : len);

          ilob_SaveToBinaryStream(p1:'/noxdb/xml/sixthElement.xml');

          xml_delete(pxml);
          *inlr = *on;
