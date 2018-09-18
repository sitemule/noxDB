
        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

        /include 'headers/XMLPARSER.rpgle'

        Dcl-S pXml         Pointer;
        Dcl-S pElem        Pointer;
        Dcl-S MyString     Varchar(50);
        Dcl-S MyElem       Varchar(50);

        Dcl-S Result Varchar(50);

        //------------------------------------------------------------- *

        Dcl-Pi XML1;
          pResult Char(50);
        End-Pi;

        Result = '';
        pXml = xml_ParseFile('./test/documents/XmlSample1.xml');

        if Xml_Error(pXml) ;
           pResult = xml_Message(pXml);

        else;
           pElem = xml_locate(pXml:'/MyRoot/MyElement');
           dow (pElem <> *NULL);
              MyElem   = xml_GetElemValue (pElem : 'N/A');
              MyString = xml_GetAttr      (pElem : 'MyAttribute1' : 'N/A');

              Result += MyElem + MyString;

              pElem = xml_GetElemNext(pElem);
           enddo;
        endif;

        xml_Close(pXml);

        pResult = Result;

        *inlr = *on;