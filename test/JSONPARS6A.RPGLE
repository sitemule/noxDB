      * ------------------------------------------------------------- *
      * Sample:
      * Build a json object with primitive types and write
      * is as astream file to the IFS in UTF-8 format
      *
      * ------------------------------------------------------------- *
     H BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' )
      /include 'headers/JSONPARSER.rpgle'
     D pJson           s               *
      /free

        // Creat a empty root object
        pJson = json_NewObject();

        // add new elements to the object
        json_SetInt    (pJson : 'a'  : 1 );
        json_SetDec    (pJson : 'b'  : 12.34);
        json_SetDec    (pJson : 'c'  : 123);
        json_SetDec    (pJson : 'pi' : 22/7); // 3.147.... infinit
        json_SetBool   (pJson : 'ok' : 2>1);  // true
        json_SetStr    (pJson : 's'  : 'Hello world');  // String



        // Write it out:
        Json_WriteStmf (pJson  :
           '/jsonxml/json/Simple-1.json':1208:*OFF
        );
        json_Close(pJSON);
        *inlr = *on;
