        
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('XMLPARSER' : 'ICEBREAK') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include xmlparser
        /include qasphdr,ilob
        Dcl-S pXml         Pointer;
        Dcl-S pElem        Pointer;
        Dcl-S p1           Pointer;
        Dcl-S len          Uns(10);
        Dcl-S msg          Varchar(50);
        Dcl-S s            Varchar(32766);

        //------------------------------------------------------------- *

        pxml  = nox_ParseFile('/samples/xml/XmlSample2.xml');

        if nox_Error(pxml) ;
           msg = nox_Message(pxml);
           nox_dump(pxml);
           nox_Close(pxml);
           return;
        endif;

        // Handle the sixth element
        pElem  = nox_locate(pxml : '/Myroot/Myelement[5]');

        // Strings
        s = nox_AsXmlText (pElem);

        // as memory - here ILOB, but any memory will do
        p1 = ILOB_OpenPersistant('QTEMP':'P1': 4096:0);
        len = nox_AsXmlTextMem ( pElem : p1);
        ilob_setLength(p1 : len);

        ilob_SaveToBinaryStream(p1:'/samples/xml/sixthElement.xml');

        nox_Close(pxml);
        *inlr = *on;
