        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );
    
        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pJson        Pointer;
        Dcl-S pNode        Pointer;
        Dcl-S Result       Varchar(50);
        Dcl-S value        Varchar(50);
        Dcl-S n            Packed(15:2);
        
        //------------------------------------------------------------- *

        Dcl-Pi JSON4;
          pResult Char(50);
        End-Pi;
        
        Result = '';
        *inlr = *on;
        pJson = Json_ParseFile ('./json/demo.json');

        if Json_Error(pJson) ;
           pResult = Json_Message(pJson);
           Json_dump(pJson);
           Json_Close(pJson);
           return;
        endif;

        pNode   = Json_locate(pJson: '/o/n');
        n       = Json_getNum(pNode);
        Result += %Char(n);

        pNode   = Json_locate(pJson: '/a[1]');
        n       = Json_GetNum (pNode);
        Result += %Char(n);

        pNode   = Json_locate(pJson: '/s');
        value   = Json_getStr(pNode);
        Result += value;

        pNode   = Json_locate(pJson: '/o/a[2]');
        n       = Json_GetNum(pNode);
        Result += %Char(n);

        pResult = Result;

        Json_Close(pJson);

        Return;
