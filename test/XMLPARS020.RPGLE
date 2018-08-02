      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin XML parser in
      * IceBreak
      *
      * ------------------------------------------------------------- *
     H BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' )
     D pXml            s               *
     D pElem           s               *
     D MyString        s             50    varying
     D MyElem          s             50    varying
     D msg             s             50    varying
      /include jsonparser
      /include xmlparser
      /free
        pXml = xml_ParseFile('/udv/expert/xmlsample1.xml');
        xml_Close(pXml);
        *inlr = *on;
