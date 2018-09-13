
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

        pXml1= xml_ParseString('<a><b atr="john"/></a>');

        if Xml_Error(pXml1) ;
           sndDiag(xml_Message(pXml1));
           xml_Close(pXml1);
           return;
        endif;

        pXml2 = xml_ParseString('<k/>');

        if Xml_Error(pXml2) ;
           sndDiag(xml_Message(pXml2));
           xml_Close(pXml2);
           return;
        endif;

        a = xml_Locate(pxml1 : 'a');
        k = xml_Locate(pxml2 : 'k');
        xml_ElementCopy(k : a   : XML_FIRST_CHILD);

        xml_writeStmf(pXml2  : '/udv/expert/newout.xml'  : 1208);

        xml_Close(pXml1);
        xml_Close(pXml2);
        *inlr = *on;
