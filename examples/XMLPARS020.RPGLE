        //------------------------------------------------------------- *
        //This sample shows the use of the buildin XML parser in
        //IceBreak

        //------------------------------------------------------------- *
        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );
        Dcl-S pXml         Pointer;
        Dcl-S pElem        Pointer;
        Dcl-S MyString     Varchar(50);
        Dcl-S MyElem       Varchar(50);
        Dcl-S msg          Varchar(50);
      /include 'headers/JSONPARSER.rpgle'
      /include xmlparser
        pXml = xml_ParseFile('/udv/expert/xmlsample1.xml');
        xml_Close(pXml);
        *inlr = *on;
