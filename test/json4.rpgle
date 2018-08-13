        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );
    
        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pJson        Pointer;
        Dcl-S pNode        Pointer;
        Dcl-S Result       Varchar(50);
        Dcl-S value        Varchar(50);
        Dcl-S n            Packed(15:2);
        
        
        Dcl-C OB Const(x'9E');
        Dcl-C CB Const(x'9F');
        Dcl-S lNode  Varchar(10);
        
        //------------------------------------------------------------- *

        Dcl-Pi JSON4;
          pResult Char(50);
        End-Pi;
        
        Result = '';
        *inlr = *on;
        pJson = Json_ParseFile ('./test/documents/demo.json');

        if Json_Error(pJson) ;
           pResult = Json_Message(pJson);
           Json_dump(pJson);
           Json_Close(pJson);
           return;
        endif;

        pNode   = Json_locate(pJson: '/o/n');
        n       = Json_getNum(pNode);
        Result += %Char(n);

        lNode = '/a' + OB + '1' + CB;
        pNode   = Json_locate(pJson: lNode);
        n       = Json_GetNum (pNode);
        Result += %Char(n);

        pNode   = Json_locate(pJson: '/s');
        value   = Json_getStr(pNode);
        Result += value;

        lNode   = '/o/a' + OB + '2' + CB;
        pNode   = Json_locate(pJson: lNode);
        n       = Json_GetNum(pNode);
        Result += %Char(n);

        pResult = Result;

        Json_Close(pJson);

        Return;