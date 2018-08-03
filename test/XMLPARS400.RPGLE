      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin XML parser in
      * IceBreak
      *
      * ------------------------------------------------------------- *
     H BndDir('XMLPARSER') dftactgrp(*NO) ACTGRP('QILE')
      /include xmlparser
     d pXml            s               *
     d a               s             50    varying
     d msg             s            256    varying
      /free
        // First parse the XML stream
        pXml = xml_ParseFile('/jsonxml/xml/escape.xml');
        if Xml_Error(pXml) ;
           msg = xml_Message(pXml);
           xml_Close(pXml);
           return;
        endif;

        // Get the manifest id: that is a attribue on the root hench the @
        a = xml_getValue(pXml : '/a');

        xml_Close(pXml);
        *inlr = *on;
