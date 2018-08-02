      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin JSONparser in
      * IceBreak
      *
      * Look at the header source file "QASPHDR" in the IceBreak   library
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
      * in the source file "QASPHDR" in the IceBreak   library
      *
      * Step 3)
      * Parse your JSONfile by caling the "json_Parse" function. It returns
      * logical a pointer to an JSON object tree.
      * Examine if the parser ran ok with json_Error() which return *ON if an
      * error did occur. In that case you can examine the reason with
      * the function "json_GetMsg()" to retrive the error and/or
      * use the function "json_Dump()"   to display the xml-tree contents
      *
      * Step 4)
      * Locate each element node by the function "json_Locate".
      * the location can be relative or from the root by prefixinig the location
      * with an "/". Each level is separated by a "/" e.g.
      * "/MyRoot/MyElement"  is "myelement" found within "myroot"
      *
      * Step 5)
      * When a element node is sucessfully fetched, you can write
      * a new JSON document with this element as a root element.
      * Use the json_writeStmf(pElm: FileName : Ccsid)  to produce that task
      * the ccsid can be other than the source JSON document. it will
      * convert it to the selected ccsid. Note: Comments not reproduced.
      *
      * Step 6)
      * Last - remember to close the JSON tree with "json_Close"
      *
      *
      * ------------------------------------------------------------- *
     H BndDir('XMLPARSER') dftactgrp(*NO) ACTGRP('QILE' )
     D pJson           s               *
     D pNode           s               *
     D msg             s             50    varying
     D tag             s             50    varying
     D value           s             50    varying
     D price           s             15  2
      /include QASPHDR,JSONparser
      /free
        *inlr = *on;
        pJson = json_ParseFile ('/udv/ccsid/win-1252.json');
        if json_Error(pJson) ;
           msg = json_Message(pJson);
        endif;
        json_Dump(pJson);
        json_Close(pJson);

        pJson = json_ParseFile ('/udv/ccsid/doesnotexists.json');
        if json_Error(pJson) ;
           msg = json_Message(pJson);
        endif;
        json_Close(pJson);


        pJson = json_ParseFile ('/udv/ccsid/partsplexer.lib');
        if json_Error(pJson) ;
           msg = json_Message(pJson);
        endif;
        json_Close(pJson);

        pJson = json_ParseFile ('/udv/ccsid/webshop.lib');
        if json_Error(pJson) ;
           msg = json_Message(pJson);
        endif;
        json_Close(pJson);

