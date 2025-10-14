
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE');

        //------------------------------------------------------------- *
        
        /include 'headers/JSONPARSER.rpgle'
        
        Dcl-S pJson        Pointer;
        Dcl-S msg          Varchar(256);
        Dcl-S n            Varchar(50);

        //------------------------------------------------------------- *

        *inlr = *on;
        pJson = Nox_ParseFile ('./test/documents/sample01.json');

        if Nox_Error(pJson) ;
           msg = Nox_Message(pJson);
           Nox_dump(pJson);
           Nox_Close(pJson);
           return;
        endif;

        // save as new file
        nox_WriteJsonStmf(pJson : './sample01out.json' : 1208 : *ON );

        Nox_Close(pJson);

