
        //------------------------------------------------------------- *
        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE');

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
        pJson = Nox_ParseFile ('./test/documents/simple.json');

        if Nox_Error(pJson) ;
           msg = Nox_Message(pJson);
           Nox_dump(pJson);
           Nox_Close(pJson);
           return;
        endif;

        // Locate and return the value:
        pNode = Nox_Locate(pJson: '/price');
        price = Nox_GetNum(pNode);

        // Or in one go:
        price = Nox_GetNum(pJson: '/price');
        text  = Nox_GetStr(pJson: '/text');

        // Or in one go - with deafults if not found
        id    = Nox_GetNum(pJson: '/id'  : -1 );
        text  = Nox_GetStr(pJson: '/desc': 'N/A');

        // Use ither / or . as you like. It is the same..
        country1   = Nox_GetStr(pJson: '/anObject/country': 'N/A');
        country2   = Nox_GetStr(pJson: '.anObject.country': 'N/A');

        Nox_Close(pJson);

        // If needed you can detect leaks here:
         //if Nox_MemLeak();
           Nox_MemStat();
         //endif;

        Return;