        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE' );
    
        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pJson        Pointer;
        Dcl-S pArr         Pointer;
        Dcl-S n            Packed(15:2);
        
        Dcl-C OB Const(x'9E');
        Dcl-C CB Const(x'9F');
        
        //------------------------------------------------------------- *

        Dcl-Pi JSON6;
          pResult Char(50);
        End-Pi;
        
        *inlr = *on;
        pJson = Json_ParseFile ('./test/documents/demo.json');

        if Json_Error(pJson) ;
           pResult = Json_Message(pJson);
           Json_dump(pJson);
           Json_delete(pJson);
           return;
        endif;
        
        // Get number of entries in arrays
        n  = Json_GetNum(pJson : '/o/a' + OB + 'UBOUND' + CB: -1 );

        pResult = %Char(n);

        Json_delete(pJson);

        Return;