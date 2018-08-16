        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE');

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pJson        Pointer;
        Dcl-S country1     Varchar(20);
        Dcl-S country2     Varchar(20);
        
        //------------------------------------------------------------- *

        Dcl-Pi JSON3;
          pResult Char(50);
        End-Pi;

        *inlr = *on;
        pJson = Json_ParseFile ('./test/documents/simple.json');

        if Json_Error(pJson) ;
           pResult = Json_Message(pJson);
           Json_dump(pJson);
           Json_Close(pJson);
           return;
        endif;

        // Use ither / or . as you like. It is the same..
        country1   = Json_GetStr(pJson: '/anObject/country': 'N/A');
        country2   = Json_GetStr(pJson: '.anObject.country': 'N/A');

        pResult = Country1 + Country2;

        Json_Close(pJson);

        Return;