
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('XMLPARSER':'ICEUTILITY');
        Ctl-Opt dftactgrp(*NO) ACTGRP('QILE' );
        
        //------------------------------------------------------------- *

        /include 'headers/XMLPARSER.rpgle'
        /include qAspHdr,ICEUTILITY
        Dcl-S pXml         Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S dc           Varchar(50);
        Dcl-S n            Int(10);
        Dcl-S i            Int(10);
        
        //------------------------------------------------------------- *
        
        pXml = xml_ParseFile (
           '/blueseries/Samples/multitag.xml'
        );

        if Xml_Error(pXml) ;
           msg = xml_Message(pXml);
           xml_dump(pXml);
           xml_Close(pXml);
           return;
        endif;

        n  = xml_getNum(pXml : 'invoices/invoice[UBOUND]');
        for i=0  to n -1;
            dc = xml_getStr(pXml :
               'invoices/invoice[' + %char(i)  +']/Header/DistChannel'
            );
            sndDiag('DistChannel : ' + dc);
        endFor;

        xml_Close(pXml);
        *inlr = *on;
