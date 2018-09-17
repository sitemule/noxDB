        //------------------------------------------------------------- *
        //This sample shows the use of the buildin XML parser in
        //IceBreak

        //------------------------------------------------------------- *
        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include xmlparser
        Dcl-S pXml         Pointer;
        Dcl-S a            Varchar(50);
        Dcl-S msg          Varchar(256);
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
