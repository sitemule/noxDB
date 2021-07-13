**free
   // ------------------------------------------------------------- *
   Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );
   /include qrpgleRef,noxdb

   Dcl-s pXmlEnvelop pointer;
   Dcl-s pXmlPayloadFromString pointer;
   Dcl-s pXmlPayloadFromFile pointer;
   Dcl-s showMe VarChar(32000);

   // Set the delimiters used to access the graph selector
   // xml_setDelimiters ('/\@[] .{}''"$');


   // Note we use the 'singleroot=true' that omits the dummy root named "rows"
   // singleroot only works if the XML dont contains multiple siblines in the root
   // (The object graph requires a single root node where XML does allow multiple)  

   pXmlEnvelop = xml_ParseString (
      '<envelope></envelope>'
      :'singleroot=true');

   pXmlPayloadFromString = xml_ParseString (
   '<DeliveryNote>-
      <DocumentReference Type="Delivery">-
         <DocumentNumber>0000000004</DocumentNumber>-
         <DocumentDate>2022-04-05</DocumentDate>-
      </DocumentReference>-
      <Qualifier>ORI</Qualifier>-
      <ServiceRequirements>GEN</ServiceRequirements>-
      <DeliveryDetails>-
         <ModeOfTransport>30</ModeOfTransport>-
         <TransportType>10</TransportType>-
      </DeliveryDetails>-
      <PartnerDescription Type="BY">-
         <PartnerNumber>2650</PartnerNumber>-
         <PartnerName1>My Onlineshop</PartnerName1>-
         <Street1>Germanstreet 123</Street1>-
         <City1>Germanheim</City1>-
         <CountryCode>DE</CountryCode>-
         <LanguageCode>DE</LanguageCode>-
      </PartnerDescription>-
      <GoodsValue>-
         <Value>0</Value>-
         <Currency>EUR</Currency>-
      </GoodsValue></DeliveryNote>'
      :'singleroot=true'
   );

   xml_setNodeFormat   (pXmlPayloadFromString : XML_FORMAT_CDATA);
   xml_NodeInsertChildTail  (pXmlEnvelop : pXmlPayloadFromString);

   showme = xml_AsXmlText(pXmlEnvelop); 

   // now even add an extra delivery node from a file 
   pXmlPayloadFromFile = xml_ParseFile ('/prj/noxdb/testdata/Deliverynote.xml' : 'singleroot=true');  
   showme = xml_AsXmlText(pXmlPayloadFromFile); 

   xml_setNodeFormat   (pXmlPayloadFromFile : XML_FORMAT_CDATA);
   xml_NodeInsertChildTail  (pXmlEnvelop : pXmlPayloadFromFile);

   // Note the two nodes are now just after eachother - with their own CDATA, that is allowed
   showme = xml_AsXmlText(pXmlEnvelop); 

   // The complete output:
   xml_WriteXmlStmf (pXmlEnvelop: '/prj/noxdb/testdata/cdata2.xml' : 1208: *OFF);
   
   // Note we do not need to delete pXmlPayload's explicitly - it is a par of the envelope
   // xml_delete(pXmlPayloadFromString) or xml_delete(pXmlPayloadFromFile);
   xml_delete(pXmlEnvelop);

   *inlr = *on;
