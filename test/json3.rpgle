        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pJson        Pointer;
        Dcl-S country1     Varchar(20);
        Dcl-S country2     Varchar(20);
        Dcl-S country3     Varchar(20);

        //------------------------------------------------------------- *

        dcl-pi *N;
          pResult Char(50);
        End-Pi;

        *inlr = *on;
        pJson = Json_ParseFile ('/prj/noxdb/testdata/simple.json');

        if Json_Error(pJson) ;
           pResult = Json_Message(pJson);
           Json_dump(pJson);
           Json_delete(pJson);
           return;
        endif;

        // Use ither / or . as you like. It is the same..
        country1   = Json_GetStr(pJson: '/anObject/country': 'N/A');
        country2   = Json_GetStr(pJson: '.anObject.country': 'N/A');
        country3  = Json_GetStr(pJson: '."anObject"."country"': 'N/A');

        pResult = Country1 + Country2 + Country3;

        Json_delete(pJson);

        Return;