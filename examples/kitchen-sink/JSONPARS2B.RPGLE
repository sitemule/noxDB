
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pJson        Pointer;
        Dcl-S pNode        Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S tag          Varchar(50);
        Dcl-S value        Varchar(50);
        Dcl-S price        Packed(15:2);

        //------------------------------------------------------------- *

        pJson = NOX_ParseString (
           '{"/rrn/product/icebreak":1,' +
           '"PRODID":"\u00b5 DIGITAL 600 ax",' +
           '"MANUID":"CASIO",' +
           '"PRICE":123.45,' +
           '"STOCKCNT":6,'+
           '"janej":"0"}'
             : '');

        if NOX_Error(pJson) ;
           msg = NOX_Message(pJson);
           NOX_dump(pJson);
           NOX_Close(pJson);
           return;
        endif;
        
        pNode = NOX_locate(pJson: '/PRICE');
        price = NOX_getNum(pNode);

        // Or in one line
        price = nox_getNum(pJson: '/price' : 0);

        // Online showin with / without  default will return 0 or blank
        price = nox_getNum       (pJson: '/priceJohn': -1);
        value = nox_getStr       (pJson: '/priceJohn': 'N/A');
        price = nox_getNum       (pJson: '/priceJohn');
        value = nox_getStr       (pJson: '/priceJohn');


        NOX_dump(pJson);
        NOX_Close(pJSON);
        *inlr = *on;
