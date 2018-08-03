      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin JsonParser in
      * IceBreak
      *
      * Look at the header source file "qAspHdr" in the IceBreak   library
      * for a complete description of the functionality
      *
      * The aim is to produce a JsonDocument from scratch
      *
      * Step 1)
      * When using the JsonParser - always bind your program to the XMLPARSER
      * bind directory - either by the CRTPGM command or add the "H" spec below:
      *
      * Step 2)
      * Include the prototypes for the Jsonparser found in member "XMLPARSER"
      * in the source file "qAspHdr" in the IceBreak   library
      *
      * Step 3)
      * Parse your Jsonfile by caling the "Json_Parse" function. It returns
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
      *
      * Step 5)
      * When a element node is sucessfully fetched, you can write
      * a new Json document with this element as a root element.
      * Use the Json_writeStmf(pElm: FileName : Ccsid)  to produce that task
      * the ccsid can be other than the source Json document. it will
      * convert it to the selected ccsid. Note: Comments not reproduced.
      *
      * Step 6)
      * Last - remember to close the JSON tree with "Json_Close"
      *
      *
      * ------------------------------------------------------------- *
     H BndDir('XMLPARSER') dftactgrp(*NO) ACTGRP('QILE' )
     D pJson           s               *
     D pNode           s               *
     D pArr            s               *
     D msg             s             50    varying
     D tag             s             50    varying
     D value           s             50    varying
     D n               s             15  2
      /include qAspHdr,JsonParser
      /free
        *inlr = *on;
        pJson = Json_ParseFile ('/samples/json/demo.json');

        if Json_Error(pJson) ;
           msg = Json_Message(pJson);
           dsply msg;
           Json_dump(pJson);
           Json_Close(pJson);
           return;
        endif;

        pNode = Json_locate(pJson: '/o/n');
        n     = Json_getNum(pNode);

        pNode = Json_locate(pJson: '/a[1]');
        n     = Json_GetNum (pNode);

        pNode = Json_locate(pJson: '/s');
        value = Json_getStr(pNode);

        pNode = Json_locate(pJson: '/u');
        value = Json_getStr(pNode);

        pNode = Json_locate(pJson: '/o/a[2]');
        n     = Json_GetNum(pNode);

        // Loop on the array
        pArr  = Json_locate(pJson: '/o/a[0]'); // First array element
        dow (pArr <> *NULL) ;
          n     = Json_GetNum (pArr);
          pArr  = Json_GetNext(pArr);
        endDo;

        // Loop the root: Note the  "/" will position to the first chile of the root
        pNode  = Json_locate(pJson: '/'); // First array element
        dow (pNode <> *NULL) ;
          value  = Json_GetStr (pNode);
          pNode  = Json_GetNext(pNode);
        endDo;

        // Get Value directly
        value = Json_GetStr    (pJson : '/u');

        // Get Value directly relative
        pNode = Json_locate(pJson: '/o');
        value = Json_GetStr (pNode : 'n');   // This is "n" in "o"

        // Get number of entries in arrays
        n  = Json_GetNum(pJson : '/o/a[UBOUND]': -1 );

        Json_dump(pJson);
        Json_Close(pJson);
