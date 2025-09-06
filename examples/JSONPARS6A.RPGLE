        
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //Sample:
        //Build a json object with primitive types and write
        //is as astream file to the IFS in UTF-8 format

        //------------------------------------------------------------- *

        /include 'headers/NOXDBUTF8JSON.rpgle'
        Dcl-S pJson        Pointer;

        //------------------------------------------------------------- *

        // Creat a empty root object
        pJson = nox_NewObject();

        // add new elements to the object
        nox_SetInt    (pJson : 'a'  : 1 );
        nox_SetNum    (pJson : 'b'  : 12.34);
        nox_SetNum    (pJson : 'c'  : 123);
        nox_SetNum    (pJson : 'pi' : 22/7); // 3.1428.... infinit
        nox_SetBool   (pJson : 'ok' : 2>1);  // true
        nox_SetStr    (pJson : 's'  : 'Hello world');  // String
        nox_setNull   (pJson : 'n');

        // Write it out:
        nox_writeJsonStmf (pJson  :
           './Simple-1.json':1208:*OFF
        );

        nox_Close(pJSON);
        *inlr = *on;
