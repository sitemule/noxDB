**free
   // ------------------------------------------------------------- *
   Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );
   /include qrpgleRef,noxdb

   // Set the delimiters used to access the graph selector
   // xml_setDelimiters ('/\@[] .{}''"$');

   test1();
   test2();
   *inlr = *on;

// ------------------------------------------------------------------------------------
// test1
// ------------------------------------------------------------------------------------
dcl-proc test1;

   Dcl-s pXmlEnvelope pointer;
   Dcl-s pEnvelopeElement pointer;
   Dcl-s pXmlPayloadFromString pointer;
   Dcl-s pXmlPayloadFromFile pointer;
   Dcl-s showMe VarChar(32000);

   // Note: the root is the document - so it is anonymus, but 
   // will  contain the envelope element  
   // (The object graph requires a single root node where XML 
   // does allow multiple)  

   pXmlEnvelope = xml_ParseString (
      '<Envelope/>'
   );

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
   );

   // Note : pXmlEnvelope is the document - we need the element named 'envelope'
   pEnvelopeElement = xml_locate(pXmlEnvelope:'/envelope');
   xml_SetNodeOptions   (pEnvelopeElement : XML_FORMAT_CDATA);

   // Note: The documents contents is "move into" the destination, so the 
   // pXmlPayloadFromString will after be a NULL 
   xml_documentInsert  (pEnvelopeElement : pXmlPayloadFromString: XML_LAST_CHILD);

   showme = xml_AsXmlText(pXmlEnvelope); 

   // now even add an extra delivery node from a file 
   pXmlPayloadFromFile = xml_ParseFile ('/prj/noxdb/testdata/Deliverynote.xml');  
   showme = xml_AsXmlText(pXmlPayloadFromFile); 

   xml_documentInsert   (pEnvelopeElement : pXmlPayloadFromFile : XML_LAST_CHILD);

   // Note the two nodes are now just after each other - with their own CDATA, that is allowed
   showme = xml_AsXmlText(pXmlEnvelope); 

   // The complete output:
   xml_WriteXmlStmf (pXmlEnvelope: '/prj/noxdb/testout/cdata1.xml' : 1208: *OFF);
   
   // Note we do not need to delete pXmlPayload's explicitly - they are children of the envelope
   // xml_delete(pXmlPayloadFromString) or xml_delete(pXmlPayloadFromFile);
   xml_delete(pXmlEnvelope);
   
end-proc;
// ------------------------------------------------------------------------------------
// test2
// ------------------------------------------------------------------------------------
dcl-proc test2;

   Dcl-s pXmlEnvelope pointer;
   Dcl-s pEnvelopeElement pointer;
   Dcl-s pXmlPayloadFromString pointer;
   Dcl-s pXmlPayloadFromFile pointer;
   Dcl-s showMe VarChar(32000);

   // similar to above build by hand build 


   // The root object is the XML document. It is the place holder for any elements
   pXmlEnvelope = xml_newObject();
   
   // produce an empty "envelope" element
   pEnvelopeElement = xml_setStr(pXmlEnvelope : 'envelope':'');

   // Since we will have XML in XML we like to serialize it later as CDATA, so parsers will not be confused
   xml_SetNodeOptions   (pEnvelopeElement : XML_FORMAT_CDATA);

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
   );


   // Note: The documents contents is "moved into" the destination, so the 
   // pXmlPayloadFromString will after be a NULL 
   xml_documentInsert  (pEnvelopeElement : pXmlPayloadFromString: XML_LAST_CHILD);

   showme = xml_AsXmlText(pXmlEnvelope); 

   // The complete output:
   xml_WriteXmlStmf (pXmlEnvelope: '/prj/noxdb/testout/cdata2.xml' : 1208: *OFF);
   
   // Note we do not need to delete pXmlPayload's explicitly - they are children of the envelope
   // xml_delete(pXmlPayloadFromString) or xml_delete(pXmlPayloadFromFile);
   xml_delete(pXmlEnvelope);
   
end-proc;
