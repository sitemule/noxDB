        
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

        //Look at the header source file "qAspHdr" in the IceBreak   library
        //for a complete description of the functionality

        //The aim is to produce a JSON-document from scratch

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S pArr         Pointer;
        Dcl-S pNewObj      Pointer;
        Dcl-S msg          Varchar(50);

        //------------------------------------------------------------- *
        
        pJson = json_NewObject();
        json_SetValue ( pJson : 'items[]': '10'); // add to the tail of items
        json_SetValue ( pJson : 'items[]': '20'); // add to the tail of items
        json_SetValue ( pJson : 'items[]': '30'); // add to the tail of items

        // Now add relative
        pArr = json_locate(pJson : 'items');
        json_SetValue ( pArr  : '[]': '40'); // add to the tail of items
        json_SetValue ( pArr  : '[]': '50'); // add to the tail of items

        // Evaluate a json string into a new array element:
        json_SetValue ( pArr  : '[]' :  // Empty array causes a new element to be added in the end
           '{a:123,b:"Some text"}' :    // A JSON object string
           JSON_EVAL                    // add to the tail of items
        );

        // Add an object into the to a new array element:
        pNewObj = json_ParseString('{x:456,y:"More text"}');
        json_SetValue ( pArr  : '[]' : pNewObj);

        // Add a object with a numeric value. This can lead to confusion since each SetValue makes a new array elem
        json_SetValue     ( pJson  : 'otherArray[].name': 'John');
        json_SetValue     ( pJson  : 'otherArray[].name': 'Albert');

        json_WriteStmf  (pJson   : '/www/systest/jsonout.json' : 1208 : *OFF);
        json_dump(pJson);
        json_Close(pJson);    // All objects created must be closed
        json_Close(pNewObj);  // All objects created must be closed
        *inlr = *on;
