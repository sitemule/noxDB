
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );
        
        //------------------------------------------------------------- *
        
        /include 'headers/XMLPARSER.rpgle'
        Dcl-S pXml         Pointer;
        Dcl-S pElem        Pointer;
        Dcl-S pPanel       Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S tag          Varchar(50);
        Dcl-S value        Varchar(50);
      
        //------------------------------------------------------------- *

        pXml = xml_ParseFile (
             '/www/systest/philipsdb/x2.xml'
             : '');
             
        if Xml_Error(pXml) ;
           msg = xml_Message(pXml);
           xml_dump(pXml);
           xml_Close(pXml);
           return;
        endif;


        xml_dump(pXml);
        xml_Close(pXml);
        *inlr = *on;
