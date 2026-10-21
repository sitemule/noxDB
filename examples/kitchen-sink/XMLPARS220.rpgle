
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
        pXml = nox_ParseFile ('/www/systest/IceCap13.xml' :'syntax=LOOSE');
        if nox_Error(pXml) ;
           msg = nox_Message(pXml);
           nox_Close(pXml);
           return;
        endif;

        nox_dump(pXml);

        // Now we retrive an element pointer to the "root"
        tag = 'panel';
        value = 'gylla';

        pElem = nox_locate(pXml:'/icecap/panels');
        if pElem <> *NULL;
          pPanel = nox_elementAdd(pElem:nox_LAST_CHILD:tag:value);
        endif;

        nox_writeStmf(pXml : '/www/systest/IceCap13out.xml': 1208);
        nox_Close(pXml);
        *inlr = *on;
