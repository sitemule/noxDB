        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE');

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pJson        Pointer;
        Dcl-S pNode        Pointer;
        Dcl-S price        Packed(15:2);

        //------------------------------------------------------------- *

        Dcl-Pi JSON1;
          pResult Char(50);
        End-Pi;

        *inlr = *on;
        Result = '';
        pJson = Json_ParseFile ('./json/simple.json');

        If Json_Error(pJson) ;
           pResult = msg = Json_Message(pJson);
           Json_dump(pJson);
           Json_Close(pJson);
           return;
        Endif;

        pNode = Json_Locate(pJson: '/price');
        price = Json_GetNum(pNode);

        pResult = %Char(price);

        Json_Close(pJson);

        Return;