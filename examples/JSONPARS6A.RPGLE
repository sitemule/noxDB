        
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE' );

        //Sample:
        //Build a json object with primitive types and write
        //is as astream file to the IFS in UTF-8 format

        //------------------------------------------------------------- *

        /include 'headers/noxDb2JSON.rpgle'
        Dcl-S pJson        Pointer;

        //------------------------------------------------------------- *

        // Creat a empty root object
        pJson = json_NewObject();

        // add new elements to the object
        json_SetInt    (pJson : 'a'  : 1 );
        json_SetNum    (pJson : 'b'  : 12.34);
        json_SetNum    (pJson : 'c'  : 123);
        json_SetNum    (pJson : 'pi' : 22/7); // 3.1428.... infinit
        json_SetBool   (pJson : 'ok' : 2>1);  // true
        json_SetStr    (pJson : 's'  : 'Hello world');  // String
        json_setNull   (pJson : 'n');

        // Write it out:
        json_writeJsonStmf (pJson  :
           './Simple-1.json':1208:*OFF
        );

        json_Close(pJSON);
        *inlr = *on;
