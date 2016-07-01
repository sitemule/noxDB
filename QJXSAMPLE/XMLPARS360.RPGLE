      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin XML parser in
      * IceBreak
      *
      *
      * ------------------------------------------------------------- *
     H BndDir('XMLPARSER':'ICEUTILITY')
     H dftactgrp(*NO) ACTGRP('QILE')
     D pXml            s               *
     D msg             s             50    varying
     D dc              s             50    varying
     D n               s             10I 0
     D i               s             10I 0
      /include qAspHdr,xmlParser
      /include qAspHdr,iceUtility
      /free
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
