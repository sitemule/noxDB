
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
        pXml = nox_ParseFile (
             '/www/systest/philipsdb/x1.xml'
             : '');
             
        if nox_Error(pXml) ;
           msg = nox_Message(pXml);
           nox_dump(pXml);
           nox_Close(pXml);
           return;
        endif;


        nox_dump(pXml);
        nox_Close(pXml);
        *inlr = *on;
