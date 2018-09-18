
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

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
        pXml  = Xml_ParseFile(p:'syntax=LOOSE');
        if Xml_Error(pXml) ;
           p = XML_Message(pXml);
        else;
           XML_Dump(pXml);
        endif;
        Xml_Close(pXml);
        *inlr = *on;
       /end-free
