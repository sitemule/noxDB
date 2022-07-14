
        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE');

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pJson        Pointer;
        Dcl-S price        Packed(15:2);
        Dcl-S text         Varchar(50);
        
        //------------------------------------------------------------- *

        Dcl-Pi JSON2;
          pResult Char(50);
        End-Pi;

        *inlr = *on;
        pJson = Json_ParseFile ('./test/documents/simple.json');

        if Json_Error(pJson) ;
           pResult = Json_Message(pJson);
           Json_dump(pJson);
           Json_delete(pJson);
           return;
        endif;

        price = Json_GetNum(pJson: '/price');
        text  = Json_GetStr(pJson: '/text');

        pResult = %Char(price) + text;

        Json_delete(pJson);

        Return;