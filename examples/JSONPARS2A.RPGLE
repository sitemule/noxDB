        //------------------------------------------------------------- *
        //This sample shows the use of the buildin JSONparser in
        //IceBreak

        //Look at the header source file "qAspHdr" in the IceBreak   library
        //for a complete description of the functionality

        //The aim is to produce a JSONdocument from scratch

        //Step 1)
        //When using the JSONparser - always bind your program to the XMLPARSER
        //bind directory - either by the CRTPGM command or add the "H" spec below:

        //Step 2)
        //Include the prototypes for the JSONparser found in member "XMLPARSER"
        //in the source file "qAspHdr" in the IceBreak   library

        //Step 3)
        //Parse your JSONfile by caling the "JSON_Parse" function. It returns
        //logical a pointer to an JSON object tree.
        //Examine if the parser ran ok with JSON_Error() which return *ON if an
        //error did occur. In that case you can examine the reason with
        //the function "JSON_GetMsg()" to retrive the error and/or
        //use the function "JSON_Dump()"   to display the xml-tree contents

        //Step 4)
        //Locate each element node by the function "JSON_Locate".
        //the location can be relative or from the root by prefixinig the location
        //with an "/". Each level is separated by a "/" e.g.
        //"/MyRoot/MyElement"  is "myelement" found within "myroot"

        //Step 5)
        //When a element node is sucessfully fetched, you can write
        //a new JSON document with this element as a root element.
        //Use the JSON_writeStmf(pElm: FileName : Ccsid)  to produce that task
        //the ccsid can be other than the source JSON document. it will
        //convert it to the selected ccsid. Note: Comments not reproduced.

        //Step 6)
        //Last - remember to close the JSON tree with "JSON_Close"


        //------------------------------------------------------------- *
        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );
        Dcl-S pJson        Pointer;
        Dcl-S pNode        Pointer;
        Dcl-S pArr         Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S tag          Varchar(50);
        Dcl-S value        Varchar(50);
        Dcl-S n            Packed(15:2);
      /include 'headers/JSONPARSER.rpgle'
        pJson = JSON_ParseString (
           '{                                             '+
           '   "e"  :"Quote\"line1\nline2\rtab\ttabed",   '+
           '   "123":"Key can be numeric"             ,   '+
           '   "ÆØÅ":"And with national chars"            '+
           '}'
        );
        if JSON_Error(pJson) ;
           msg = JSON_Message(pJson);
           JSON_dump(pJson);
           JSON_Close(pJson);
           return;
        endif;
        json_WriteStmf( pJson: '/samples/json/dump-payload.json': 1208 : *OFF);
        pNode = JSON_locate(pJson: '/e');
        value = json_getStr  (pNode);

        // Get value for at numeric key
        value = json_getStr  (pJson: %char(123));

        // Get value for at national chars
        value = json_getStr  (pJson: 'ÆØÅ');

        JSON_Close(pJSON);
        *inlr = *on;
