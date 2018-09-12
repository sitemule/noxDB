
        //------------------------------------------------------------- *

        //The XML file we want to parse in this sample look like:

        //<?xml version="1.0" encoding="ISO-8859-1"?>
        //<Myroot>
        //<Myelement Myattribute1="My Company name" Myattribute2="1">abc</Mye
        //<Myelement Myattribute1="Another name"    Myattribute2="0">def</Mye
        //</Myroot>

        //which will produce:

        //<?xml version="1.0" encoding="UTF-8"?>
        //<Myelement Myattribute1="Another name" Myattribute2="0">def</Myelement

        //------------------------------------------------------------- *

        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE');

        //------------------------------------------------------------- *

        /include 'headers/XMLPARSER.rpgle'
        Dcl-S pXml         Pointer;
        Dcl-S pElem        Pointer;
        Dcl-S msg          Varchar(50);

        //------------------------------------------------------------- *

        pXml = xml_ParseFile('/udv/expert/xmlsample2.xml':'syntax=LOOSE');
        if Xml_Error(pXml) ;
           msg = xml_Message(pXml);
        else;
           pElem = xml_locate(pXml:'/MyRoot/MyElement[9]');
           xml_writeStmf(pElem : '/udv/expert/xmlsampleout.xml' : 1208 : *ON);
        endif;
        xml_Close(pXml);
        *inlr = *on;
