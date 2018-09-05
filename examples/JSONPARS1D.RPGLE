
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE');

        //------------------------------------------------------------- *
        
        /include 'headers/JSONPARSER.rpgle'
        
        Dcl-S pJson        Pointer;
        Dcl-S msg          Varchar(256);
        Dcl-S n            Varchar(50);

        //------------------------------------------------------------- *

        *inlr = *on;
        pJson = Json_ParseFile ('./test/documents/sample01.json');

        if Json_Error(pJson) ;
           msg = Json_Message(pJson);
           Json_dump(pJson);
           Json_Close(pJson);
           return;
        endif;

        // save as new file
        json_WriteJsonStmf(pJson : './sample01out.json' : 1208 : *ON );

        Json_Close(pJson);

