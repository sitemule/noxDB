
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE');
        
        //------------------------------------------------------------- *

        /include xmlparser
        Dcl-S pXml         Pointer;
        Dcl-S a            Varchar(50);
        Dcl-S msg          Varchar(256);
        
        //------------------------------------------------------------- *

        // First parse the XML stream
        pXml = nox_ParseFile('/jsonxml/xml/escape.xml');
        
        if nox_Error(pXml) ;
           msg = nox_Message(pXml);
           nox_Close(pXml);
           return;
        endif;

        // Get the manifest id: that is a attribue on the root hench the @
        a = nox_getValue(pXml : '/a');

        nox_Close(pXml);
        *inlr = *on;
