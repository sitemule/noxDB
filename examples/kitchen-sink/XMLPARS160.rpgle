
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE');

        //------------------------------------------------------------- *

        /include 'headers/XMLPARSER.rpgle'
        Dcl-S pXml1        Pointer;
        Dcl-S pXml2        Pointer;
        Dcl-S pSrcElm      Pointer;
        Dcl-S pDstElm      Pointer;
        Dcl-S pDelete      Pointer;
        Dcl-S pOut         Pointer;
        Dcl-S msg          Varchar(50);

        //------------------------------------------------------------- *

        pXml1 = nox_ParseFile('/udv/expert/xmlsample1.xml');
        if nox_Error(pXml1) ;
           msg = nox_Message(pXml1);
           nox_Close(pXml1);
           return;
        endif;

        pXml2 = nox_ParseFile('/udv/expert/xmlsample2.xml' );
        if nox_Error(pXml2) ;
           msg = nox_Message(pXml2);
           nox_Close(pXml1);
           nox_Close(pXml2);
           return;
        endif;

        // initial locatores in the XML tree
        pSrcElm = nox_locate(pXml2:'/MyRoot/MyElement[3]');
        pOut    = nox_locate(pXml1:'/MyRoot');

        // ex1 : Add a child at the top
        pDstElm = nox_locate(pXml1:'/MyRoot');
        nox_ElementCopy(pDstElm : pSrcElm : nox_FIRST_CHILD);

        nox_writeStmf(pOut : '/udv/expert/xmlsampleout1.xml' : 1208);
        pDelete = nox_locate(pXml1:'/MyRoot/SubElement');
        nox_ElementDelete (pDelete);

        // ex2 : Add a child at the bottom
        pDstElm = nox_locate(pXml1:'/MyRoot');
        nox_ElementCopy(pDstElm : pSrcElm : nox_LAST_CHILD);
        nox_writeStmf(pOut : '/udv/expert/xmlsampleout2.xml' : 1208);
        pDelete = nox_locate(pXml1:'/MyRoot/SubElement');
        nox_ElementDelete (pDelete);

        // ex3 : Add a sibling after a reference location
        pDstElm = nox_locate(pXml1:'/MyRoot/MyElement[0]');
        nox_ElementCopy(pDstElm : pSrcElm : nox_AFTER_SIBLING);
        nox_writeStmf(pOut : '/udv/expert/xmlsampleout3.xml' : 1208);
        pDelete = nox_locate(pXml1:'/MyRoot/SubElement');
        nox_ElementDelete (pDelete);

        // ex4 : Add a sibling before a reference location
        pDstElm = nox_locate(pXml1:'/MyRoot/MyElement[1]');
        nox_ElementCopy(pDstElm : pSrcElm : nox_BEFORE_SIBLING);
        nox_writeStmf(pOut : '/udv/expert/xmlsampleout4.xml' : 1208);
        pDelete = nox_locate(pXml1:'/MyRoot/SubElement');
        nox_ElementDelete (pDelete);

        nox_Close(pXml1);
        nox_Close(pXml2);
        *inlr = *on;
