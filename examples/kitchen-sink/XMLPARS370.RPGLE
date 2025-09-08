
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('XMLPARSER':'ICEUTILITY');
        Ctl-Opt dftactgrp(*NO) ACTGRP('QILE');
        
        //------------------------------------------------------------- *

        /include xmlParser
        /include qAspHdr,iceUtility
        Dcl-S pXml1        Pointer;
        Dcl-S pXml2        Pointer;
        Dcl-S a            Pointer;
        Dcl-S k            Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S n            Int(10);
        Dcl-S i            Int(10);
      
        //------------------------------------------------------------- *

        pXml1= nox_ParseString('<a><b atr="john"/></a>');

        if nox_Error(pXml1) ;
           sndDiag(nox_Message(pXml1));
           nox_Close(pXml1);
           return;
        endif;

        pXml2 = nox_ParseString('<k/>');

        if nox_Error(pXml2) ;
           sndDiag(nox_Message(pXml2));
           nox_Close(pXml2);
           return;
        endif;

        a = nox_Locate(pxml1 : 'a');
        k = nox_Locate(pxml2 : 'k');
        nox_ElementCopy(k : a   : nox_FIRST_CHILD);

        nox_writeStmf(pXml2  : '/udv/expert/newout.xml'  : 1208);

        nox_Close(pXml1);
        nox_Close(pXml2);
        *inlr = *on;
