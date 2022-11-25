
        //------------------------------------------------------------- *
        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE');

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pJson        Pointer;
        Dcl-S pNode        Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S tag          Varchar(50);
        Dcl-S value        Varchar(50);
        Dcl-S price        Packed(15:2);
        Dcl-S id           Packed(5:0);
        Dcl-S desc         Varchar(50);
        Dcl-S text         Varchar(50);
        Dcl-S country1     Varchar(50);
        Dcl-S country2     Varchar(50);

        //------------------------------------------------------------- *

        *inlr = *on;
        pJson = Json_ParseFile ('./test/documents/simple.json');

        if Json_Error(pJson) ;
           msg = Json_Message(pJson);
           Json_dump(pJson);
           Json_Close(pJson);
           return;
        endif;

        // Locate and return the value:
        pNode = Json_Locate(pJson: '/price');
        price = Json_GetNum(pNode);

        // Or in one go:
        price = Json_GetNum(pJson: '/price');
        text  = Json_GetStr(pJson: '/text');

        // Or in one go - with deafults if not found
        id    = Json_GetNum(pJson: '/id'  : -1 );
        text  = Json_GetStr(pJson: '/desc': 'N/A');

        // Use ither / or . as you like. It is the same..
        country1   = Json_GetStr(pJson: '/anObject/country': 'N/A');
        country2   = Json_GetStr(pJson: '.anObject.country': 'N/A');

        Json_Close(pJson);

        // If needed you can detect leaks here:
         //if Json_MemLeak();
           Json_MemStat();
         //endif;

        Return;