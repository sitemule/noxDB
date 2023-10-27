        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pJson        Pointer;
        Dcl-S pNode        Pointer;
        Dcl-S price        Packed(15:2);

        //------------------------------------------------------------- *

        dcl-pi *N;
          pResult Char(50);
        End-Pi;

        *inlr = *on;
        pJson = Json_ParseFile ('/prj/noxdb/testdata/simple.json');

        If Json_Error(pJson) ;
           pResult = Json_Message(pJson);
           Json_dump(pJson);
           Json_delete(pJson);
           return;
        Endif;

        pNode = Json_Locate(pJson: '/price');
        price = Json_GetNum(pNode);

        pResult = %Char(price);

        Json_delete(pJson);

        Return;