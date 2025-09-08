
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
        
        pXml = nox_ParseFile (
           '/blueseries/Samples/multitag.xml'
        );

        if nox_Error(pXml) ;
           msg = nox_Message(pXml);
           nox_dump(pXml);
           nox_Close(pXml);
           return;
        endif;

        n  = nox_getNum(pXml : 'invoices/invoice[UBOUND]');
        for i=0  to n -1;
            dc = nox_getStr(pXml :
               'invoices/invoice[' + %char(i)  +']/Header/DistChannel'
            );
            sndDiag('DistChannel : ' + dc);
        endFor;

        nox_Close(pXml);
        *inlr = *on;
