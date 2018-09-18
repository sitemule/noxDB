
        //------------------------------------------------------------- *

        //The XML file we want to parse in this sample look like:

        //<?xml version="1.0" encoding="ISO-8859-1"?>
        //<Myroot>
        //<Myelement Myattribute1="My Company name" Myattribute2="1">abc</Mye
        //<Myelement Myattribute1="Another name"    Myattribute2="0">def</Mye
        //</Myroot>

        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/XMLPARSER.rpgle'
        Dcl-S pXml         Pointer;
        Dcl-S pElem        Pointer;
        Dcl-S MyString     Varchar(50);
        Dcl-S MyElem       Varchar(50);
        Dcl-S msg          Varchar(50);

        //------------------------------------------------------------- *

        pXml = xml_ParseFile('/udv/expert/xmlsample1.xml');
        if Xml_Error(pXml) ;
           msg = xml_Message(pXml);
        else;
           pElem = xml_locate(pXml:'/MyRoot/MyElement');
           dow (pElem <> *NULL);
              MyElem   = xml_GetElemValue (pElem : 'N/A');
              MyString = xml_GetAttr      (pElem : 'MyAttribute1' : 'N/A');
              pElem = xml_GetElemNext(pElem);
           enddo;
        endif;
        
        xml_Close(pXml);
        *inlr = *on;
