        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pJson        Pointer;
        Dcl-S pArr         Pointer;
        Dcl-S n            Packed(15:2);

        //------------------------------------------------------------- *

        dcl-pi *N;
          pResult Char(50);
        End-Pi;

        *inlr = *on;
        pJson = Json_ParseFile ('/prj/noxdb/testdata/demo.json');

        if Json_Error(pJson) ;
           pResult = Json_Message(pJson);
           Json_dump(pJson);
           Json_delete(pJson);
           return;
        endif;

        // Get number of entries in arrays
        n  = Json_GetNum(pJson : '[UBOUND]' : -1 );

        // Get number of entries in object
        n  = Json_GetNum(pJson : '[0].[UBOUND]' : -1 );

        pResult = %Char(n);

        Json_delete(pJson);

        Return;