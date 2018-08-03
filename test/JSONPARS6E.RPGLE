      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin JSONparser in
      * IceBreak
      *
      * Look at the header source file "qAspHdr" in the IceBreak   library
      * for a complete description of the functionality
      *
      * The aim is to produce a JSON-document from scratch
      *
      * ------------------------------------------------------------- *
     H BndDir('XMLPARSER') dftactgrp(*NO) ACTGRP('QILE' )
     D pJson           s               *
     D pArr            s               *
     D pTemp           s               *
     D pNewObj         s               *
     D msg             s             50    varying
      /include qAspHdr,JsonParser
      /free
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

        // Now: Build a new object and copy it into the temp array
        // After pNewObj still have all elements
        pTemp = json_NewObject();
        json_SetValue ( pTemp : 'a' : 'A value ');
        json_SetValue ( pTemp : 'b' : 'B value ');
        json_SetValue ( pTemp : 'c' : 'C value ');
        json_SetValue ( pArr  : '[]' : pTemp  );

        // If we need to move the elemets ( which is much faster)
        // After pTemp   will be empty but still an object though
        json_SetValue ( pJson : 'anObject': pTemp : JSON_OBJMOVE);

        // Is is empty ?
        json_SetValue ( pJson : 'emptyObject': pTemp);

        json_WriteStmf  (pJson   : '/www/systest/jsonout.json' : 1208 : *OFF);
        json_dump(pJson);
        json_Close(pJson);    // All objects created must be closed
        json_Close(pNewObj);  // All objects created must be closed
        json_Close(pTemp  );  // All objects created must be closed
        *inlr = *on;
