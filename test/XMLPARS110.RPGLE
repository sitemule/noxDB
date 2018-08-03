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
      * <?xml version="1.0" encoding="utf-8"?>
      * <manifest ID="123456">
      *   <visit ID="ABCDE" sequence="10">
      *     <datetimeActualArrival>2011-11-07T09:28:23.520</datetimeActualArrival>
      *     <datetimeActualDeparture>2011-11-07T09:28:49.550</datetimeActualDeparture>
      *     <late>LATE</late>
      *     <callSequence>10</callSequence>
      *     <consignment type="delivery">
      *       <orderRef>123123</orderRef>
      *       <customerCode>CUST1</customerCode>
      *       <discrepancy>NO</discrepancy>
      *     </consignment>
      *     <consignment type="delivery">
      *       <orderRef>123124</orderRef>
      *       <customerCode>CUST2</customerCode>
      *       <discrepancy>NO</discrepancy>
      *     </consignment>
      *     <consignment type="collection">
      *       <orderRef>123125</orderRef>
      *        <customerCode>CUST3</customerCode>
      *        <discrepancy>NO</discrepancy>
      *      </consignment>
      *    </visit>
      *  </manifest>
      *
      * ------------------------------------------------------------- *
     H BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE')
      /include xmlparser
     d pXml            s               *
     d pVisit          s               *
     d pConsignment    s               *
     d pConsArr        s               *
     d msg             s             50    varying
     d xpath           s            128    varying
     d i               s             10i 0
     d manifestId      s             10i 0
     d visitId         s             10    varying
     d visitSeq        s             10i 0
     d arrival         s               Z
     d consignments    s             10i 0
     d orderRef        s             10i 0
     d customerCode    s             10    varying
     d discrepancy     s               n
      /free
        // First parse the XML stream
        pXml = xml_ParseFile('/udv/expert/manifest.xml');
        if Xml_Error(pXml) ;
           msg = xml_Message(pXml);
           xml_Close(pXml);
           return;
        endif;

        // Get the manifest id: that is a attribue on the root hench the @
        manifestId = %int(xml_GetValue (pXml : '/manifest@ID':'0'));

        // Not locate the "visit" and let it be the new temorary root
        // You can also use a comple reference from the root if you like
        pVisit = xml_locate(pXml:'/manifest/visit');
        if (pVisit =  *NULL);
           // If we did not found the "visit" element we die - remember to close the xml to avoid a leak
           xml_Close(pXml);
           return;
        endif;

        // Now extrace the values from the "visit" tag - some are attribues, some are elements
        visitId   = xml_GetValue (pVisit: '@ID');                         // As String
        visitSeq  = %int(xml_getValue(pVisit: '@sequence':'0'));                // As Number
        // arrival   = CvtWsTs2Ts(xml_GetValue (pVisit: 'datetimeActualArrival')); // As DB/2 timestamp

        // Consignments is an array: use UBOUND to detect the numbers of entries
        consignments = %int(xml_GetValue(pVisit:'consignment[UBOUND]':'0'));

        // Now loop for each elemnt consignments. Note - x-path use 0 as the first element
        // Just for the fun we will find the element from the root - an absolute path
        // but from "pVisit" as root and the only the "consignment" index will work just fine
        for i = 0 to consignments -1;
           xpath = '/manifest/visit/consignment[' + %char(i) + ']';
           pConsignment = xml_locate(pXml: xpath );
           orderRef     = %int(xml_GetValue(pConsignment: 'orderRef':'0'));          // As number
           customerCode = xml_GetValue (pConsignment: 'customerCode');        // As string
           discrepancy  = 'NO' <>  xml_GetValue (pConsignment: 'discrepancy');      // As boolean
        endfor;


        xml_Close(pXml);
        *inlr = *on;
