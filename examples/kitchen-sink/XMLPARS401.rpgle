
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE');
        
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
        pXml = nox_ParseFile('/jsonxml/xml/largeSoapFile.xml');
        
        if nox_Error(pXml) ;
           msg = nox_Message(pXml);
           nox_Close(pXml);
           return;
        endif;

        // Get payload tag
        p = '/envelope/body/gnreRespostaMsg/TResultLote_GNRE' +
         '/resultado';
        pv  = nox_getValuePtr(nox_locate(pXml:p));

        nox_Close(pXml);
        *inlr = *on;
