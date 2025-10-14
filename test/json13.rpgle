        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE' );
        
        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pJson        Pointer;

        //------------------------------------------------------------- *

        Dcl-Pi JSON13;
          pResult Char(50);
        End-Pi;

        // Creat a empty root object
        pJson = json_NewObject();

        // add new elements to the object
        json_SetInt    (pJson : 'a'  : 1 );
        json_SetDec    (pJson : 'b'  : 12.34);
        json_SetDec    (pJson : 'c'  : 123);
        json_SetBool   (pJson : 'ok' : 2>1);  // true
        json_SetStr    (pJson : 's'  : 'hi');  // String

        // Write it out:
        pResult = json_AsText(pJson);

        json_delete(pJSON);
        *inlr = *on;