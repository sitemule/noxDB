      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin XML parser in
      * IceBreak
      *
      *
      * ------------------------------------------------------------- *
     H BndDir('XMLPARSER':'ICEUTILITY')
     H dftactgrp(*NO) ACTGRP('QILE')
     D pXml1           s               *
     D pXml2           s               *
     D a               s               *
     D k               s               *
     D msg             s             50    varying
     D n               s             10I 0
     D i               s             10I 0
      /include xmlParser
      /include qAspHdr,iceUtility
      /free
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
