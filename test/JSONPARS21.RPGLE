      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin JSONparser in
      * IceBreak
      *
      * Look at the header source file "qAspHdr" in the IceBreak   library
      * for a complete description of the functionality
      *
      * The aim is to produce a JSONdocument from scratch
      *
      * Step 1)
      * When using the JSONparser - always bind your program to the XMLPARSER
      * bind directory - either by the CRTPGM command or add the "H" spec below:
      *
      * Step 2)
      * Include the prototypes for the JSONparser found in member "XMLPARSER"
      * in the source file "qAspHdr" in the IceBreak   library
      *
      * Step 3)
      * Parse your JSONfile by caling the "JSON_Parse" function. It returns
      * logical a pointer to an JSON object tree.
      * Examine if the parser ran ok with JSON_Error() which return *ON if an
      * error did occur. In that case you can examine the reason with
      * the function "JSON_GetMsg()" to retrive the error and/or
      * use the function "JSON_Dump()"   to display the xml-tree contents
      *
      * Step 4)
      * Locate each element node by the function "JSON_Locate".
      * the location can be relative or from the root by prefixinig the location
      * with an "/". Each level is separated by a "/" e.g.
      * "/MyRoot/MyElement"  is "myelement" found within "myroot"
      *
      * Step 5)
      * When a element node is sucessfully fetched, you can write
      * a new JSON document with this element as a root element.
      * Use the JSON_writeStmf(pElm: FileName : Ccsid)  to produce that task
      * the ccsid can be other than the source JSON document. it will
      * convert it to the selected ccsid. Note: Comments not reproduced.
      *
      * Step 6)
      * Last - remember to close the JSON tree with "JSON_Close"
      *
      *
      * ------------------------------------------------------------- *
     H BndDir('XMLPARSER') dftactgrp(*NO) ACTGRP('QILE' )
     D pJson           s               *
     D pNode           s               *
     D pO              s               *
     D pR              s               *
     D pRcv            s               *
     D pArr            s               *
     D pKey            s               *
     D msg             s             50    varying
     D tag             s             50    varying
     D value           s             50    varying
     D n               s             15  2
      /include qAspHdr,JSONparser
      /free
        pJson = JSON_ParseString (
           '{                      '+
           '  a:123,               '+
           '  b:"text",            '+
           '  c:"More text"        '+
           '}'
             : '');
        if JSON_Error(pJson) ;
           msg = JSON_Message(pJson);
           JSON_dump(pJson);
           JSON_Close(pJson);
           return;
        endif;
        pRcv  = JSON_ParseString ('{}');

        pO = json_SetValue(pRcv : '/row' : pJson: JSON_OBJREPLACE);

        pKey  = JSON_ParseString ('{ key: "123" }');
        pO = json_SetValue(pRcv : '/key' : pKey : JSON_OBJREPLACE);

        JSON_dump(pRcv );
        json_WriteStmf  (pRcv : '/www/systest/jsonout.json' : 1208 : *OFF);
        JSON_Close(pJSON);
        JSON_Close(pKey );
        JSON_Close(pRcv );
        *inlr = *on;
