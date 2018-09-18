
        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

        /include 'headers/XMLPARSER.rpgle'

        Dcl-S pXml         Pointer;
        Dcl-S pOut         Pointer;
        Dcl-S count        Int(10);
        Dcl-S i            Int(10);

        Dcl-S Result Varchar(50);

        Dcl-C OB Const(x'9E');
        Dcl-C CB Const(x'9F');
        Dcl-C AT Const(x'80');
      
        //------------------------------------------------------------- *

        Dcl-Pi XML5;
          pResult Char(50);
        End-Pi;

        Result = '';

        pXml  = xml_ParseFile('./test/documents/XmlSample2.xml':'syntax=LOOSE');
        if Xml_Error(pXml ) ;
           pResult = xml_Message(pXml);
           xml_Close(pXml );
           return;
        endif;

        // Count elements
        count= %int(xml_GetValue(pXml: '/myroot/myElement' +
                                       OB + 'UBOUND' + CB:'0'));

        for i = 0 to count -1;
          pOut = xml_Locate(pXml: '/myroot/myElement' + OB + %char(i) + CB);
          Result += xml_GetValue(pOut : AT + 'Myattribute1' : 'x');
        endFor;

        pResult = Result;

        xml_Close(pXml);
        *inlr = *on;
