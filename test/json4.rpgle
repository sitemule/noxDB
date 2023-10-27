        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pJson        Pointer;
        Dcl-S pNode        Pointer;
        Dcl-S Result       Varchar(50);
        Dcl-S value        Varchar(50);
        Dcl-S n            Packed(15:2);


        Dcl-S lNode  Varchar(10);

        //------------------------------------------------------------- *

        dcl-pi *N;
          pResult Char(50);
        End-Pi;

        Result = '';
        *inlr = *on;
        pJson = Json_ParseFile ('/prj/noxdb/testdata/demo.json');

        if Json_Error(pJson) ;
           pResult = Json_Message(pJson);
           Json_dump(pJson);
           Json_delete(pJson);
           return;
        endif;

        pNode   = Json_locate(pJson: '/o/n');
        n       = Json_getNum(pNode);
        Result += %Char(n);

        lNode = '/a[1]' ;
        pNode   = Json_locate(pJson: lNode);
        n       = Json_GetNum (pNode);
        Result += %Char(n);

        pNode   = Json_locate(pJson: '/s');
        value   = Json_getStr(pNode);
        Result += value;

        lNode   = '/o/a[2]' ;
        pNode   = Json_locate(pJson: lNode);
        n       = Json_GetNum(pNode);
        Result += %Char(n);

        pResult = Result;

        Json_delete(pJson);

        Return;