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
        //Parse your JSONfile by caling the "json_Parse" function. It returns
        //logical a pointer to an JSON object tree.
        //Examine if the parser ran ok with json_Error() which return *ON if an
        //error did occur. In that case you can examine the reason with
        //the function "json_GetMsg()" to retrive the error and/or
        //use the function "json_Dump()"   to display the xml-tree contents

        //Step 4)
        //Locate each element node by the function "json_Locate".
        //the location can be relative or from the root by prefixinig the location
        //with an "/". Each level is separated by a "/" e.g.
        //"/MyRoot/MyElement"  is "myelement" found within "myroot"

        //Step 5)
        //When a element node is sucessfully fetched, you can write
        //a new JSON document with this element as a root element.
        //Use the json_writeStmf(pElm: FileName : Ccsid)  to produce that task
        //the ccsid can be other than the source JSON document. it will
        //convert it to the selected ccsid. Note: Comments not reproduced.

        //Step 6)
        //Last - remember to close the JSON tree with "json_Close"


        //------------------------------------------------------------- *
        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );
        Dcl-S pJson        Pointer;
        Dcl-S p            Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S s            Varchar(50);
        Dcl-S i            Int(10);
      /include 'headers/JSONPARSER.rpgle'

        pJson = json_ParseString ('{e:[ -
          { "name":"a", "val":"a1"}, -
          { "name":"b", "o": [ -
              { "x":"x1", "q":"11"}, -
              { "x":"x2", "r":"22"}, -
              { "x":"x3", "s":"33"}, -
              { "k":true  , "r":"88"}, -
            ]                        -
          },                         -
          { "name":"c", "val":"c3"} -
        ]}');

        if JSON_Error(pJson) ;
           msg = JSON_Message(pJson);
           JSON_dump(pJson);
           JSON_Close(pJson);
           return;
        endif;

        // Get the object n the array where the "name" attribute is "b"
        p = json_locate  (pJson : '/e[name=b]/o[k=true]');
        s = json_getStr      (p : 'r' );

        *inlr = *on;
