**free
// ------------------------------------------------------------------------------------
Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE' ) main(main);
/include 'headers/noxDb2.rpgle'

dcl-proc main;

   test1();
   test2();
end-proc;

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

   pXmlEnvelope = nox_ParseString (
      '<Envelope/>'
   );

   pXmlPayloadFromString = nox_ParseString (
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
   pEnvelopeElement = nox_locate(pXmlEnvelope:'/envelope');
   nox_SetNodeOptions   (pEnvelopeElement : nox_FORMAT_CDATA);

   // Note: The documents contents is "move into" the destination, so the 
   // pXmlPayloadFromString will after be a NULL 
   nox_documentInsert  (pEnvelopeElement : pXmlPayloadFromString: nox_LAST_CHILD);

   showme = nox_AsXmlText(pXmlEnvelope); 

   // now even add an extra delivery node from a file 
   pXmlPayloadFromFile = nox_ParseFile ('/prj/noxdb2/testdata/Deliverynote.xml');  
   showme = nox_AsXmlText(pXmlPayloadFromFile); 

   nox_documentInsert   (pEnvelopeElement : pXmlPayloadFromFile : nox_LAST_CHILD);

   // Note the two nodes are now just after each other - with their own CDATA, that is allowed
   showme = nox_AsXmlText(pXmlEnvelope); 

   // The complete output:
   nox_WriteXmlStmf (pXmlEnvelope: '/prj/noxdb2/test/out/cdata1.xml' : 1208: *OFF);
   
   // Note we do not need to delete pXmlPayload's explicitly - they are children of the envelope
   // nox_delete(pXmlPayloadFromString) or nox_delete(pXmlPayloadFromFile);
   nox_delete(pXmlEnvelope);
   
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
   pXmlEnvelope = nox_newObject();
   
   // produce an empty "envelope" element
   pEnvelopeElement = nox_setStr(pXmlEnvelope : 'envelope':'');

   // Since we will have XML in XML we like to serialize it later as CDATA, so parsers will not be confused
   nox_SetNodeOptions   (pEnvelopeElement : NOX_FORMAT_CDATA);

   pXmlPayloadFromString = nox_ParseString (
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
   nox_documentInsert  (pEnvelopeElement : pXmlPayloadFromString: nox_LAST_CHILD);

   showme = nox_AsXmlText(pXmlEnvelope); 

   // The complete output:
   nox_WriteXmlStmf (pXmlEnvelope: '/prj/noxdb2/test/out/cdata2.xml' : 1208: *OFF);
   
   // Note we do not need to delete pXmlPayload's explicitly - they are children of the envelope
   // nox_delete(pXmlPayloadFromString) or nox_delete(pXmlPayloadFromFile);
   nox_delete(pXmlEnvelope);
   
end-proc;
