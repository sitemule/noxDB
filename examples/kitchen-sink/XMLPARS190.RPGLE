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
        Dcl-S pXml1        Pointer;
        Dcl-S pRoot        Pointer;
        Dcl-S pt           Pointer;
        Dcl-S msg          Varchar(50);

        //------------------------------------------------------------- *

        // first we run the paser on a minimal string to build the XML tree with the root name "root"
        pXml1 = nox_ParseString('<root/>':'syntax=LOOSE');
        if nox_Error(pXml1) ;
           msg = nox_Message(pXml1);
           nox_Close(pXml1);
           return;
        endif;

        // Now we retrive an element pointer to the "root"
        pRoot   = nox_locate(pXml1:'/Root');

        // elements are now added sucessivly using the reference location and element pointer
        // note the order..
        pt = nox_elementAdd(pRoot : nox_LAST_CHILD  : 'last' : 'Some value');
        pt = nox_elementAdd(pRoot : nox_FIRST_CHILD : 'first' : 'More value');
        pt = nox_elementAdd(pt    : nox_LAST_CHILD  : 'subnode2' : 'Sub-stuff');
        nox_SetAttrValue(pt    : 'MyAttribute' : 'First value');
        nox_SetAttrValue(pt    : 'MyAttribute' : 'New Value');
        nox_SetAttrValue(pt    : 'a2'          : 'a2 1');
        nox_SetAttrValue(pt    : 'a2'          : 'a2 2');

        // Finally we can produce the XML file
        nox_writeStmf(pRoot : '/udv/expert/xmlsampleout6.xml' : 1208);
        nox_Close(pXml1);
        *inlr = *on;
