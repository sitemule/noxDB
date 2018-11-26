**FREE
        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pJson        Pointer;
        Dcl-S pNode        Pointer;
        Dcl-S price        Packed(15:2);

        //------------------------------------------------------------- *

        Dcl-Pi JSON1;
          pResult Char(50);
        End-Pi;

        dcl-s name varchar(256);

        *inlr = *on;
        pJson = Json_ParseFile ('./test/documents/simple.json');

        If Json_Error(pJson) ;
           pResult = Json_Message(pJson);
           Json_dump(pJson);
           Json_delete(pJson);
           return;
        Endif;


        // By locate and the get string value
        pNode = Json_Locate(pJson: 'text');
        name = Json_GetStr(pNode);

        // Same as above - but in one go
        name  = Json_GetStr(pJson : 'text');

        // Same as above - but also with a default value if not found
        name  = Json_GetStr(pJson : 'text' : 'N/A');

        // Now - numeric
        // By locate and the get value
        pNode = Json_Locate(pJson: 'price');
        price = Json_GetNum(pNode);

        // Same as above - but in one go
        price = Json_GetNum(pJson : 'price');

        // Same as above - but also with a default value if not found
        price = Json_GetNum(pJson : 'price' : -1);

        pResult = %Char(price);

        Json_delete(pJson);

        Return;