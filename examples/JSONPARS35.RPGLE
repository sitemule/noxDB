
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S pNode        Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S tag          Varchar(50);
        Dcl-S value        Varchar(50);
        Dcl-S price        Packed(15:2);

        //------------------------------------------------------------- *

        *inlr = *on;
        pJson = json_ParseFile ('/udv/ccsid/win-1252.json');
        if json_Error(pJson) ;
           msg = json_Message(pJson);
        endif;
        json_Dump(pJson);
        json_Close(pJson);

        pJson = json_ParseFile ('/udv/ccsid/doesnotexists.json');
        if json_Error(pJson) ;
           msg = json_Message(pJson);
        endif;
        json_Close(pJson);


        pJson = json_ParseFile ('/udv/ccsid/partsplexer.lib');
        if json_Error(pJson) ;
           msg = json_Message(pJson);
        endif;
        json_Close(pJson);

        pJson = json_ParseFile ('/udv/ccsid/webshop.lib');
        if json_Error(pJson) ;
           msg = json_Message(pJson);
        endif;
        json_Close(pJson);

