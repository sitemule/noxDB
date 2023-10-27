
        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

        /include 'headers/XMLPARSER.rpgle'

        Dcl-S pXml         Pointer;

        Dcl-S result       Varchar(50);


        //------------------------------------------------------------- *

        dcl-pi *N;
        End-Pi;

        pXml  = xml_ParseFile('/prj/noxdb/testdata/XmlSample3.xml');
        if Xml_Error(pXml ) ;
           result  = xml_Message(pXml);
           xml_delete(pXml );
           return;
        endif;

        result = xml_GetStr (
          pXml:
          '/configuration/routing/map[1]@pattern'
        );

        xml_delete(pXml);
        *inlr = *on;
