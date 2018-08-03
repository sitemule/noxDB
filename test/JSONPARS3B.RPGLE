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
     H BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' )
     D pJson           s               *
     D pNode           s               *
     D pArr            s               *
     D e               s               *
     D msg             s             50    varying
     D tag             s             50    varying
     D s               s             50    varying
     D n               s             50    varying
     D v               s             50    varying
     D i               s             10i 0
      /include 'headers/JSONPARSER.rpgle'
      /free
        pJson = JSON_ParseFile ('/www/systest/demo2.json':'');

        if JSON_Error(pJson) ;
           msg = JSON_Message(pJson);
           dsply msg;
           JSON_dump(pJson);
           JSON_Close(pJson);
           return;
        endif;


        // Loop on the array
        pArr  = JSON_locate(pJson: '/[0]'); // First array element
        dow (pArr <> *NULL) ;
          // Loop all elements in that array element
          e  = json_GetChild (pArr);
          dow (e  <> *NULL) ;
            n =  json_getName  (e);
            v =  json_getValue (e);
            e  = json_GetNext  (e);
          endDo;
          pArr  = JSON_getNext(pArr);
        endDo;

        JSON_dump(pJson);
        JSON_Close(pJSON);
        *inlr = *on;
