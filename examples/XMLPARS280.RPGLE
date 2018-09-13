        
        //------------------------------------------------------------- *

        //The XML file we want to parse in this sample look like:

        //<?xml version="1.0" encoding="ISO-8859-1"?>
        //<root>
        //<first>
        //<subnode2>Sub stuff</subnode2>
        //<first>
        //<last>Some stuff<last>
        //</root>
        
        //------------------------------------------------------------- *
        
        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *
        
        /include 'headers/XMLPARSER.rpgle'
        Dcl-S pXml         Pointer;
        Dcl-S pElem        Pointer;
        Dcl-S pPanel       Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S tag          Varchar(50);
        Dcl-S value        Varchar(50);

        //------------------------------------------------------------- *
      
        // first we run the paser on a minimal string to build the XML tree with the root name "root"
        pXml = xml_ParseFile ('/www/development/folke/import/WEB_VARER.XML'
             : '');
        if Xml_Error(pXml) ;
           msg = xml_Message(pXml);
           xml_Close(pXml);
           return;
        endif;

        xml_dump(pXml);
        xml_Close(pXml);
        *inlr = *on;
