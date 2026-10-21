
        //------------------------------------------------------------- *

        //The XML file we want to parse in this sample look like:

        //<?xml version="1.0" encoding="ISO-8859-1"?>
        //<Myroot>
        //<Myelement Myattribute1="My Company name" Myattribute2="1">abc</Mye
        //<Myelement Myattribute1="Another name"    Myattribute2="0">def</Mye
        //</Myroot>

        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/XMLPARSER.rpgle'
        Dcl-S pXml         Pointer;
        Dcl-S pElem        Pointer;
        Dcl-S MyString     Varchar(50);
        Dcl-S MyElem       Varchar(50);
        Dcl-S msg          Varchar(50);

        //------------------------------------------------------------- *

        pXml = nox_ParseFile('/udv/expert/xmlsample1.xml');
        if nox_Error(pXml) ;
           msg = nox_Message(pXml);
        else;
           pElem = nox_locate(pXml:'/MyRoot/MyElement');
           dow (pElem <> *NULL);
              MyElem   = nox_GetElemValue (pElem : 'N/A');
              MyString = nox_GetAttr      (pElem : 'MyAttribute1' : 'N/A');
              pElem = nox_GetElemNext(pElem);
           enddo;
        endif;
        
        nox_Close(pXml);
        *inlr = *on;
