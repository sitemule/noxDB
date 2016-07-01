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
      * Parse your JSONfile by caling the "Json_Parse" function. It returns
      * logical a pointer to an JSON object tree.
      * Examine if the parser ran ok with Json_Error() which return *ON if an
      * error did occur. In that case you can examine the reason with
      * the function "Json_GetMsg()" to retrive the error and/or
      * use the function "Json_Dump()"   to display the xml-tree contents
      *
      * Step 4)
      * Locate each element node by the function "Json_Locate".
      * the location can be relative or from the root by prefixinig the location
      * with an "/". Each level is separated by a "/" e.g.
      * "/MyRoot/MyElement"  is "myelement" found within "myroot"
      * You can use either / or . as expresion delimiter
      *
      * Step 5)
      * When a element node is sucessfully fetched, you can write
      * a new JSON document with this element as a root element.
      * Use the Json_writeStmf(pElm: FileName : Ccsid)  to produce that task
      * the ccsid can be other than the source JSON document. it will
      * convert it to the selected ccsid. Note: Comments not reproduced.
      *
      * Step 6)
      * Last - remember to close the JSON tree with "Json_Close"
      *
      *
      * ------------------------------------------------------------- *
     H BndDir('XMLPARSER') dftactgrp(*NO) ACTGRP('QILE')
      /include QASPHDR,JSONparser
     d pJson           s               *
     d pNode           s               *
     d msg             s             50    varying
     d tag             s             50    varying
     d value           s             50    varying
     d price           s             15  2
     d id              s              5  0
     d desc            s             50    varying
     d text            s             50    varying
     d country1        s             50    varying
     d country2        s             50    varying
      * ------------------------------------------------------------- *
      /free
        *inlr = *on;
        pJson = Json_ParseFile ('/samples/json/simple.json');

        if Json_Error(pJson) ;
           msg = Json_Message(pJson);
           Json_dump(pJson);
           Json_Close(pJson);
           return;
        endif;

        // Locate and return the value:
        pNode = Json_Locate(pJson: '/price');
        price = Json_GetNum(pNode);

        // Or in one go:
        price = Json_GetNum(pJson: '/price');
        text  = Json_GetStr(pJson: '/text');

        // Or in one go - with deafults if not found
        id    = Json_GetNum(pJson: '/id'  : -1 );
        text  = Json_GetStr(pJson: '/desc': 'N/A');

        // Use ither / or . as you like. It is the same..
        country1   = Json_GetStr(pJson: '/anObject/country': 'N/A');
        country2   = Json_GetStr(pJson: '.anObject.country': 'N/A');

        Json_Close(pJson);

        // If needed you can detect leaks here:
         //if Json_MemLeak();
           Json_MemStat();
         //endif;
