      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin XML parser in
      * IceBreak
      *
      * Look at the header source file "qAspHdr" in the IceBreak   library
      * for a complete description of the functionality
      *
      * Step 1)
      * When using the XML parser - always bind your program to the XMLPARSER
      * bind directory - either by the CRTPGM command or add the "H" spec below:
      *
      * Step 2)
      * Include the prototypes for the xml parser found in member "XMLPARSER"
      * in the source file "qAspHdr" in the IceBreak   library
      *
      * Step 3)
      * Parse your XML file by caling the "XML_ParseFile" function. It returns
      * logical *ON if the parser completed ok - When an error occures
      * use the function "XML_GetMsg" to retrive the error and/or
      * use the function "XML_Dump"   to display the xml-tree contents
      *
      * Step 4)
      * Use X-Path syntax to retrive datavalues (search the net for a description of Xpath)
      * Locate each element node by the function "XML_Locate".
      * the location can be relative or from the root by prefixinig the location
      * with an "/". Each level is separated by a "/" and attributes is prefixed by "@"
      * "/MyRoot/MyElement@myattibute"
      *
      * Step 5)
      * Last - remember to close the XML tree with "XML_Close"
      *
      *
      * The XML file we want to parse in this sample look like:
      *
      * ------------------------------------------------------------- *
     H BndDir('XMLPARSER') dftactgrp(*NO) ACTGRP('QILE')
     Fqprint    O    F  132        printer

      // Globals
     D pXml            s               *
     D id              s             32    varying

      // prototypes
     D Print           PR
     D   Str                        132    const

      /include qAspHdr,xmlparser
      //' -----------------------------------------------------------
      //' Mainline
      //' -----------------------------------------------------------
      /free
        // pXml  = Xml_ParseFile('/IceBreak  /demo/oiodemo.xml':'syntax=LOOSE');
        pXml  = Xml_ParseFile('/udv/expert/XmlSample1.xml':'syntax=LOOSE');
        if Xml_Error(pXml) ;
           Print(XML_Message(pXml));
        else;
           id = Xml_Getvalue(pXml: '/invoice/com:id ': 'N/A');
           id = Xml_Getvalue(pXml: '/Myroot/myelement[1]@myattribute1 ': 'N/A');
           print(id);
        endif;
        Xml_Close(pXml);
        *inlr = *on;
       /end-free
      * ------------------------------------------------------------- *
     P Print           B
     D Print           PI
     D   Str                        132    const
     D Buf             DS           132
      /free
        Buf = str;
        write qprint Buf;
      /end-free
     P Print           E

