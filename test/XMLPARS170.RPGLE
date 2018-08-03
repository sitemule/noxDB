      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin XML parser in
      * IceBreak
      *
      * Look at the header source file "qAspHdr" in the IceBreak   library
      * for a complete description of the functionality
      *
      * The aim is to produce a XML document based on an element location from
      * a input XML document.
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
      * Parse your XML file by caling the "XML_Parse" function. It returns
      * logical a pointer to an XML object tree.
      * Examine if the parser ran ok with xml_Error() which return *ON if an
      * error did occur. In that case you can examine the reason with
      * the function "XML_GetMsg()" to retrive the error and/or
      * use the function "XML_Dump()"   to display the xml-tree contents
      *
      * Step 4)
      * Locate each element node by the function "XML_Locate".
      * the location can be relative or from the root by prefixinig the location
      * with an "/". Each level is separated by a "/" e.g.
      * "/MyRoot/MyElement"  is "myelement" found within "myroot"
      *
      * Step 5)
      * When a element node is sucessfully fetched, you can write
      * a new XML document with this element as a root element.
      * Use the XML_writeStmf(pElm: FileName : Ccsid)  to produce that task
      * the ccsid can be other than the source XMl document. it will
      * convert it to the selected ccsid. Note: Comments not reproduced.
      *
      * Step 6)
      * Last - remember to close the XML tree with "XML_Close"
      *
      *
      * The XML file we want to parse in this sample look like:
      *
      *   <?xml version="1.0" encoding="ISO-8859-1"?>
      *   <Myroot>
      *      <Myelement Myattribute1="My Company name" Myattribute2="1">abc</Myelement>
      *      <Myelement Myattribute1="Another name"    Myattribute2="0">def</Myelement>
      *   </Myroot>
      *
      * which will produce:
      *
      *   <?xml version="1.0" encoding="UTF-8"?>
      *   <Myelement Myattribute1="Another name" Myattribute2="0">def</Myelement>
      *
      * ------------------------------------------------------------- *
     H BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' )
     D pXml1           s               *
     D pXml2           s               *
     D pSrcElm         s               *
     D pDstElm         s               *
     D pDelete         s               *
     D pOut            s               *
     D msg             s             50    varying
      /include 'headers/XMLPARSER.rpgle'
      /free
        pXml1 = xml_ParseFile('/udv/expert/simple1.xml':'syntax=LOOSE');
        if Xml_Error(pXml1) ;
           msg = xml_Message(pXml1);
           xml_Close(pXml1);
           return;
        endif;
        pOut    = xml_locate(pXml1:'/A');
        xml_writeStmf(pXml1 : '/udv/expert/simpleout1.xml' : 1208);

        pXml2 = xml_ParseFile('/udv/expert/simple2.xml':'syntax=LOOSE');
        if Xml_Error(pXml2) ;
           msg = xml_Message(pXml2);
           xml_Close(pXml2);
           return;
        endif;

        xml_writeStmf(pXml2 : '/udv/expert/simpleout2.xml' : 1208);

        // initial locatores in the XML tree
        pOut    = xml_locate(pXml1:'/A');
        pOut    = xml_locate(pXml2:'/X');
        xml_Close(pXml1);
        xml_Close(pXml2);
        *inlr = *on;
