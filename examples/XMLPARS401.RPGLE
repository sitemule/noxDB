
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE');
        
        //------------------------------------------------------------- *

        /include xmlparser
        Dcl-S pXml         Pointer;
        Dcl-S a            Varchar(50);
        Dcl-S msg          Varchar(256);
        Dcl-S p            Varchar(256);
        Dcl-S v            Char(65000) based(pv);
        Dcl-S pv           Pointer;
        
        //------------------------------------------------------------- *

        // First parse the XML stream
        pXml = xml_ParseFile('/jsonxml/xml/largeSoapFile.xml');
        
        if Xml_Error(pXml) ;
           msg = xml_Message(pXml);
           xml_Close(pXml);
           return;
        endif;

        // Get payload tag
        p = '/envelope/body/gnreRespostaMsg/TResultLote_GNRE' +
         '/resultado';
        pv  = xml_getValuePtr(xml_locate(pXml:p));

        xml_Close(pXml);
        *inlr = *on;
