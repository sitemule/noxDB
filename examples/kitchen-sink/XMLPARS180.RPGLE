
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/XMLPARSER.rpgle'
        Dcl-S pXml         Pointer;
        Dcl-S pSrcElm      Pointer;
        Dcl-S pDstElm      Pointer;
        Dcl-S pDelete      Pointer;
        Dcl-S pOut         Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S count        Int(10);
        Dcl-S i            Int(10);
        Dcl-S c            Char(10);

        //------------------------------------------------------------- *

        pXml  = nox_ParseFile('/udv/expert/XmlSample2.xml':'syntax=LOOSE');
        if nox_Error(pXml ) ;
           msg = nox_Message(pXml );
           nox_Close(pXml );
           return;
        endif;

        // Count elements
        count= %int(nox_GetValue(pXml: '/myroot/myElement[UBOUND]':'0'));

        for i = 0 to count -1;
          pOut = nox_Locate(pXml: '/myroot/myElement[' + %char(i) + ']    ');
          nox_writeStmf(pOut : '/udv/expert/split' + %char(i) + '.xml' : 1208);
        endFor;

        nox_Close(pXml);
        *inlr = *on;
