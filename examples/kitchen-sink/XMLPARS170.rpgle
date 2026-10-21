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

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/XMLPARSER.rpgle'
        Dcl-S pXml1        Pointer;
        Dcl-S pXml2        Pointer;
        Dcl-S pSrcElm      Pointer;
        Dcl-S pDstElm      Pointer;
        Dcl-S pDelete      Pointer;
        Dcl-S pOut         Pointer;
        Dcl-S msg          Varchar(50);

        //------------------------------------------------------------- *

        pXml1 = nox_ParseFile('/udv/expert/simple1.xml':'syntax=LOOSE');
        if nox_Error(pXml1) ;
           msg = nox_Message(pXml1);
           nox_Close(pXml1);
           return;
        endif;
        pOut    = nox_locate(pXml1:'/A');
        nox_writeStmf(pXml1 : '/udv/expert/simpleout1.xml' : 1208);

        pXml2 = nox_ParseFile('/udv/expert/simple2.xml':'syntax=LOOSE');
        if nox_Error(pXml2) ;
           msg = nox_Message(pXml2);
           nox_Close(pXml2);
           return;
        endif;

        nox_writeStmf(pXml2 : '/udv/expert/simpleout2.xml' : 1208);

        // initial locatores in the XML tree
        pOut    = nox_locate(pXml1:'/A');
        pOut    = nox_locate(pXml2:'/X');
        nox_Close(pXml1);
        nox_Close(pXml2);
        *inlr = *on;
