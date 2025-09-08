        
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

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
        
        pJson = nox_NewObject();
        nox_SetValue ( pJson : 'items[]': '10'); // add to the tail of items
        nox_SetValue ( pJson : 'items[]': '20'); // add to the tail of items
        nox_SetValue ( pJson : 'items[]': '30'); // add to the tail of items

        // Now add relative
        pArr = nox_locate(pJson : 'items');
        nox_SetValue ( pArr  : '[]': '40'); // add to the tail of items
        nox_SetValue ( pArr  : '[]': '50'); // add to the tail of items

        // Evaluate a json string into a new array element:
        nox_SetValue ( pArr  : '[]' :  // Empty array causes a new element to be added in the end
           '{a:123,b:"Some text"}' :    // A JSON object string
           NOX_EVAL                    // add to the tail of items
        );

        // Add an object into the to a new array element:
        pNewObj = nox_ParseString('{x:456,y:"More text"}');
        nox_SetValue ( pArr  : '[]' : pNewObj);

        // Add a object with a numeric value. This can lead to confusion since each SetValue makes a new array elem
        nox_SetValue     ( pJson  : 'otherArray[].name': 'John');
        nox_SetValue     ( pJson  : 'otherArray[].name': 'Albert');

        nox_WriteStmf  (pJson   : '/www/systest/jsonout.json' : 1208 : *OFF);
        nox_dump(pJson);
        nox_Close(pJson);    // All objects created must be closed
        nox_Close(pNewObj);  // All objects created must be closed
        *inlr = *on;
