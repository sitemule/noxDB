
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/XMLPARSER.rpgle'
        
        // Globals
        Dcl-S pXml         Pointer;
        Dcl-S p            Varchar(128);

      //' -----------------------------------------------------------
      //' Mainline
      //' -----------------------------------------------------------
        p ='/data/TestNFei/XMLSIGN/'
        +'35081145841137000107550010000332506603325076-nfe.xml';
        pXml  = nox_ParseFile(p:'syntax=LOOSE');
        if nox_Error(pXml) ;
           p = nox_Message(pXml);
        else;
           nox_Dump(pXml);
        endif;
        nox_Close(pXml);
        *inlr = *on;
       /end-free
