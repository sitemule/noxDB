
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

        *inlr = *on;
        pJson = nox_ParseFile ('/udv/ccsid/win-1252.json');
        if nox_Error(pJson) ;
           msg = nox_Message(pJson);
        endif;
        nox_Dump(pJson);
        nox_Close(pJson);

        pJson = nox_ParseFile ('/udv/ccsid/doesnotexists.json');
        if nox_Error(pJson) ;
           msg = nox_Message(pJson);
        endif;
        nox_Close(pJson);


        pJson = nox_ParseFile ('/udv/ccsid/partsplexer.lib');
        if nox_Error(pJson) ;
           msg = nox_Message(pJson);
        endif;
        nox_Close(pJson);

        pJson = nox_ParseFile ('/udv/ccsid/webshop.lib');
        if nox_Error(pJson) ;
           msg = nox_Message(pJson);
        endif;
        nox_Close(pJson);

