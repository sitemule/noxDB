
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pJson        Pointer;
        Dcl-S pNode        Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S tag          Varchar(50);
        Dcl-S value        Varchar(50);
        Dcl-S price        Packed(15:2);

        //------------------------------------------------------------- *

        pJson = JSON_ParseString (
           '{"/rrn/product/icebreak":1,' +
           '"PRODID":"\u00b5 DIGITAL 600 ax",' +
           '"MANUID":"CASIO",' +
           '"PRICE":123.45,' +
           '"STOCKCNT":6,'+
           '"janej":"0"}'
             : '');

        if JSON_Error(pJson) ;
           msg = JSON_Message(pJson);
           JSON_dump(pJson);
           JSON_Close(pJson);
           return;
        endif;
        
        pNode = JSON_locate(pJson: '/PRICE');
        price = JSON_getNum(pNode);

        // Or in one line
        price = json_getNum(pJson: '/price' : 0);

        // Online showin with / without  default will return 0 or blank
        price = json_getNum       (pJson: '/priceJohn': -1);
        value = json_getStr       (pJson: '/priceJohn': 'N/A');
        price = json_getNum       (pJson: '/priceJohn');
        value = json_getStr       (pJson: '/priceJohn');


        JSON_dump(pJson);
        JSON_Close(pJSON);
        *inlr = *on;
