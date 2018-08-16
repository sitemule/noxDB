        //------------------------------------------------------------- *
        //This sample shows the use of the buildin XML parser in
        //IceBreak


        //------------------------------------------------------------- *
        Ctl-Opt BndDir('XMLPARSER':'ICEUTILITY');
        Ctl-Opt dftactgrp(*NO) ACTGRP('QILE');
        Dcl-S pXml         Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S dc           Varchar(50);
        Dcl-S n            Int(10);
        Dcl-S i            Int(10);
      /include 'headers/XMLPARSER.rpgle'
      /include qAspHdr,iceUtility
        pXml = xml_ParseFile (
             '/bwr/368_20140616080348.XML'
        );

        if Xml_Error(pXml) ;
           sndDiag(xml_Message(pXml));
           xml_dump(pXml);
           xml_Close(pXml);
           return;
        endif;

       //
       //  n    = xml_getNum(pXml : 'invoices/invoice[UBOUND]');
       //  for i=0  to n -1;
       //      dc = xml_getValue(pXml :
       //         'invoices/invoice[' + %char(i)  +']/Header/DistChannel'
       //      );
       //      sndDiag('DistChannel : ' + dc);
       //  endFor;

        xml_dump(pXml);
        xml_Close(pXml);
        *inlr = *on;
