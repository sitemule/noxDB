
        //------------------------------------------------------------- *

        //The XML file we want to parse in this sample look like:

        //<?xml version="1.0" encoding="ISO-8859-1"?>
        //<root>
        //<first
        //a="123"
        //b="abc"
        ///>
        //</root>

        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

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
        pXml = xml_ParseFile ('/IceBreak  /simple.xml' :'syntax=LOOSE');
        if Xml_Error(pXml) ;
           msg = xml_Message(pXml);
           xml_Close(pXml);
           return;
        endif;

        xml_writeStmf(pXml : '/IceBreak  /simple.xml': 1208);
        xml_Close(pXml);
        *inlr = *on;
