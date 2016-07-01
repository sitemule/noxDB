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
      * Parse your XML file by caling the "XML_Parse" function. It returns
      * logical *ON if the parser completed ok - When an error occures
      * use the function "XML_GetMsg" to retrive the error and/or
      * use the function "XML_Dump"   to display the xml-tree contents
      *
      * Step 4)
      * Locate each element node by the function "XML_Locate".
      * the location can be relative or from the root by prefixinig the location
      * with an "/". Each level is separated by a "/" e.g.
      * "/MyRoot/MyElement"  is "myelement" found within "myroot"
      *
      * Step 5)
      * When a element node is sucessfully fetched, then you can
      * can retrieve its value by "Xml_GetElemValue" and it attributes
      * with "XML_GetAttr". Note that you can supply a default
      * value forboth - if the node/attribute is not found.
      * Enshure that your result variable is big enough to hold the result
      * - otherwise unpredictble results may occure.
      *
      * Step 6)
      * Itterate through all elements by returning the next element
      * with "Xml_GetElemNext" until it returns *NULL
      *
      * Step 7)
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
      * ------------------------------------------------------------- *
     H BndDir('XMLPARSER') dftactgrp(*NO) ACTGRP('QILE' )
     D pXml            s               *
     D pElem           s               *
     D MyString        s             50    varying
     D MyElem          s             50    varying
     D msg             s             50    varying
      /include qAspHdr,xmlparser
      /free
        pXml = xml_ParseFile('/udv/expert/xmlsample1.xml');
        if Xml_Error(pXml) ;
           msg = xml_Message(pXml);
        else;
           pElem = xml_locate(pXml:'/MyRoot/MyElement');
           dow (pElem <> *NULL);
              MyElem   = xml_GetElemValue (pElem : 'N/A');
              MyString = xml_GetAttr      (pElem : 'MyAttribute1' : 'N/A');
              pElem = xml_GetElemNext(pElem);
           enddo;
        endif;
        xml_Close(pXml);
        *inlr = *on;
