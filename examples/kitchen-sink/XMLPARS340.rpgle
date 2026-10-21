
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

        pXml = nox_ParseFile (
             '/www/systest/philipsdb/x2.xml'
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
