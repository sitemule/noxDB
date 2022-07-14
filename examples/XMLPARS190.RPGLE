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

        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/XMLPARSER.rpgle'
        Dcl-S pXml1        Pointer;
        Dcl-S pRoot        Pointer;
        Dcl-S pt           Pointer;
        Dcl-S msg          Varchar(50);

        //------------------------------------------------------------- *

        // first we run the paser on a minimal string to build the XML tree with the root name "root"
        pXml1 = xml_ParseString('<root/>':'syntax=LOOSE');
        if Xml_Error(pXml1) ;
           msg = xml_Message(pXml1);
           xml_Close(pXml1);
           return;
        endif;

        // Now we retrive an element pointer to the "root"
        pRoot   = xml_locate(pXml1:'/Root');

        // elements are now added sucessivly using the reference location and element pointer
        // note the order..
        pt = xml_elementAdd(pRoot : XML_LAST_CHILD  : 'last' : 'Some value');
        pt = xml_elementAdd(pRoot : XML_FIRST_CHILD : 'first' : 'More value');
        pt = xml_elementAdd(pt    : XML_LAST_CHILD  : 'subnode2' : 'Sub-stuff');
        xml_SetAttrValue(pt    : 'MyAttribute' : 'First value');
        xml_SetAttrValue(pt    : 'MyAttribute' : 'New Value');
        xml_SetAttrValue(pt    : 'a2'          : 'a2 1');
        xml_SetAttrValue(pt    : 'a2'          : 'a2 2');

        // Finally we can produce the XML file
        xml_writeStmf(pRoot : '/udv/expert/xmlsampleout6.xml' : 1208);
        xml_Close(pXml1);
        *inlr = *on;
