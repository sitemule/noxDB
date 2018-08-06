        //------------------------------------------------------------- *
        //This sample shows the use of the buildin XML parser in
        //IceBreak

        //Look at the header source file "qAspHdr" in the IceBreak   library
        //for a complete description of the functionality

        //Step 1)
        //When using the XML parser - always bind your program to the XMLPARSER
        //bind directory - either by the CRTPGM command or add the "H" spec below:

        //Step 2)
        //Include the prototypes for the xml parser found in member "XMLPARSER"
        //in the source file "qAspHdr" in the IceBreak   library

        //Step 3)
        //Parse your XML file by caling the "XML_ParseFile" function. It returns
        //logical *ON if the parser completed ok - When an error occures
        //use the function "XML_GetMsg" to retrive the error and/or
        //use the function "XML_Dump"   to display the xml-tree contents

        //Step 4)
        //Use X-Path syntax to retrive datavalues (search the net for a descriptio
        //Locate each element node by the function "XML_Locate".
        //the location can be relative or from the root by prefixinig the location
        //with an "/". Each level is separated by a "/" and attributes is prefixed
        //"/MyRoot/MyElement@myattibute"

        //Step 5)
        //Last - remember to close the XML tree with "XML_Close"


        //The XML file we want to parse in this sample look like:

        //------------------------------------------------------------- *
        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );

      // Globals
        Dcl-S pXml         Pointer;
        Dcl-S p            Varchar(128);

      /include 'headers/XMLPARSER.rpgle'
      //' -----------------------------------------------------------
      //' Mainline
      //' -----------------------------------------------------------
        p ='/data/TestNFei/XMLSIGN/'
        +'35081145841137000107550010000332506603325076-nfe.xml';
        pXml  = Xml_ParseFile(p:'syntax=LOOSE');
        if Xml_Error(pXml) ;
           p = XML_Message(pXml);
        else;
           XML_Dump(pXml);
        endif;
        Xml_Close(pXml);
        *inlr = *on;
       /end-free
