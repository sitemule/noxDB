
        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE' );

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
        pXml = nox_ParseFile('./test/documents/XmlSample1.xml');

        if nox_Error(pXml) ;
           pResult = nox_Message(pXml);

        else;
           pElem = nox_locate(pXml:'/MyRoot/MyElement');
           dow (pElem <> *NULL);
              MyElem   = nox_GetElemValue (pElem : 'N/A');
              MyString = nox_GetAttr      (pElem : 'MyAttribute1' : 'N/A');

              Result += MyElem + MyString;

              pElem = nox_GetElemNext(pElem);
           enddo;
        endif;

        nox_delete(pXml);

        pResult = Result;

        *inlr = *on;