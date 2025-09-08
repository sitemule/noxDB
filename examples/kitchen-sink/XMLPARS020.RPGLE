
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pXml         Pointer;
        Dcl-S pElem        Pointer;
        Dcl-S MyString     Varchar(50);
        Dcl-S MyElem       Varchar(50);
        Dcl-S msg          Varchar(50);

        //------------------------------------------------------------- *
      /include xmlparser
        pXml = nox_ParseFile('/udv/expert/xmlsample1.xml');
        nox_Close(pXml);
        *inlr = *on;
