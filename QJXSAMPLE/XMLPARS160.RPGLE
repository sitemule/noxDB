      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin XML parser in
      * IceBreak
      *
      *
      * ------------------------------------------------------------- *
     H BndDir('XMLPARSER') dftactgrp(*NO) ACTGRP('QILE')
     D pXml1           s               *
     D pXml2           s               *
     D pSrcElm         s               *
     D pDstElm         s               *
     D pDelete         s               *
     D pOut            s               *
     D msg             s             50    varying
      /include qAspHdr,xmlparser
      /free
        pXml1 = xml_ParseFile('/udv/expert/xmlsample1.xml');
        if Xml_Error(pXml1) ;
           msg = xml_Message(pXml1);
           xml_Close(pXml1);
           return;
        endif;

        pXml2 = xml_ParseFile('/udv/expert/xmlsample2.xml' );
        if Xml_Error(pXml2) ;
           msg = xml_Message(pXml2);
           xml_Close(pXml1);
           xml_Close(pXml2);
           return;
        endif;

        // initial locatores in the XML tree
        pSrcElm = xml_locate(pXml2:'/MyRoot/MyElement[3]');
        pOut    = xml_locate(pXml1:'/MyRoot');

        // ex1 : Add a child at the top
        pDstElm = xml_locate(pXml1:'/MyRoot');
        xml_ElementCopy(pDstElm : pSrcElm : XML_FIRST_CHILD);

        xml_writeStmf(pOut : '/udv/expert/xmlsampleout1.xml' : 1208);
        pDelete = xml_locate(pXml1:'/MyRoot/SubElement');
        xml_ElementDelete (pDelete);

        // ex2 : Add a child at the bottom
        pDstElm = xml_locate(pXml1:'/MyRoot');
        xml_ElementCopy(pDstElm : pSrcElm : XML_LAST_CHILD);
        xml_writeStmf(pOut : '/udv/expert/xmlsampleout2.xml' : 1208);
        pDelete = xml_locate(pXml1:'/MyRoot/SubElement');
        xml_ElementDelete (pDelete);

        // ex3 : Add a sibling after a reference location
        pDstElm = xml_locate(pXml1:'/MyRoot/MyElement[0]');
        xml_ElementCopy(pDstElm : pSrcElm : XML_AFTER_SIBLING);
        xml_writeStmf(pOut : '/udv/expert/xmlsampleout3.xml' : 1208);
        pDelete = xml_locate(pXml1:'/MyRoot/SubElement');
        xml_ElementDelete (pDelete);

        // ex4 : Add a sibling before a reference location
        pDstElm = xml_locate(pXml1:'/MyRoot/MyElement[1]');
        xml_ElementCopy(pDstElm : pSrcElm : XML_BEFORE_SIBLING);
        xml_writeStmf(pOut : '/udv/expert/xmlsampleout4.xml' : 1208);
        pDelete = xml_locate(pXml1:'/MyRoot/SubElement');
        xml_ElementDelete (pDelete);

        xml_Close(pXml1);
        xml_Close(pXml2);
        *inlr = *on;
