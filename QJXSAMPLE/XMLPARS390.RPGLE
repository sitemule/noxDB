      * ------------------------------------------------------------- *
     H BndDir('XMLPARSER' : 'ICEBREAK') dftactgrp(*NO) ACTGRP('QILE' )
     d pXml            s               *
     d pElem           s               *
     d p1              s               *
     d len             s             10u 0
     d msg             s             50    varying
     d s               s          32766    varying
      /include xmlparser
      /include qasphdr,ilob
      /free

        pxml  = xml_ParseFile('/samples/xml/XmlSample2.xml');

        if xml_Error(pxml) ;
           msg = xml_Message(pxml);
           xml_dump(pxml);
           xml_Close(pxml);
           return;
        endif;

        // Handle the sixth element
        pElem  = xml_locate(pxml : '/Myroot/Myelement[5]');

        // Strings
        s = xml_AsXmlText (pElem);

        // as memory - here ILOB, but any memory will do
        p1 = ILOB_OpenPersistant('QTEMP':'P1': 4096:0);
        len = xml_AsXmlTextMem ( pElem : p1);
        ilob_setLength(p1 : len);

        ilob_SaveToBinaryStream(p1:'/samples/xml/sixthElement.xml');

        xml_Close(pxml);
        *inlr = *on;
