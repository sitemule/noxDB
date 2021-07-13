**free

   // ------------------------------------------------------------- *
   Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );
   Dcl-S pxml               Pointer;
   Dcl-S pn                 Pointer;

   Dcl-S msg                VarChar(50);
   Dcl-S n                  VarChar(50);
   Dcl-S v                  VarChar(4096);
   /include qrpgleRef,noxdb

   // Set the delimiters used to access the graph selector
   // xml_setDelimiters ('/\@[] .{}''"$');


   pxml  = xml_ParseString (
   '<a><![CDATA[<DeliveryNote>-
      <DocumentReference Type="Delivery">-
         <DocumentNumber>0000000003</DocumentNumber>-
         <DocumentDate>2021-03-26</DocumentDate>-
      </DocumentReference>-
      <Qualifier>ORI</Qualifier>-
      <ServiceRequirements>GEN</ServiceRequirements>-
      <DeliveryDetails>-
         <ModeOfTransport>30</ModeOfTransport>-
         <TransportType>10</TransportType>-
      </DeliveryDetails>-
      <PartnerDescription Type="BY">-
         <PartnerNumber>1650</PartnerNumber>-
         <PartnerName1>My Onlineshop</PartnerName1>-
         <Street1>Germanstreet 123</Street1>-
         <City1>Germanheim</City1>-
         <CountryCode>DE</CountryCode>-
         <LanguageCode>DE</LanguageCode>-
      </PartnerDescription>-
      <GoodsValue>-
         <Value>0</Value>-
         <Currency>EUR</Currency>-
      </GoodsValue></DeliveryNote>]]></a>'
   );

   // pxml  = xml_ParseString (
   //    '<a><![CDATA[xxx]]></a>'
   // );

   If xml_Error(pxml) ;
      msg = xml_Message(pxml);
      xml_dump(pxml);
      xml_delete(pxml);
      Return;
   EndIf;

   pn = xml_locate (pxml :'a');
   v = xml_getStr(pn);

   xml_WriteXmlStmf (pn: '/prj/noxdb/testdata/xmlnode.xml' : 1208: *OFF);
   xml_WriteXmlStmf (pxml: '/prj/noxdb/testdata/cdata1.xml' : 1208: *OFF);
   xml_delete(pxml);
   *inlr = *on;
