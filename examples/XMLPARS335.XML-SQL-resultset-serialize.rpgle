**free
   // ------------------------------------------------------------- *
   Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );
   /include qrpgleRef,noxdb

   // Always set your ccsid for constants: 
   xml_setDelimitersByCcsid(500);


   test1();
   *inlr = *on;

// ------------------------------------------------------------------------------------
// test1
// ------------------------------------------------------------------------------------
dcl-proc test1;

   dcl-s showMe   varchar(32000);
   dcl-s pResult	pointer;
   dcl-s pRows 	pointer;

   // The XML_META constructs a resultset object with a document root and a "row" array
   pResult = xml_sqlResultSet(
      'Select * from qiws.QCUSTCDT':
      1: // Start 
      XML_ALLROWS: // Number of rows
      XML_META     // Important: This gives you a document root - otherwise you will have individual elements
   );

   showme = xml_AsXmlText(pResult); 

   // The complete output:
   xml_WriteXmlStmf (pResult: '/prj/noxdb/testout/customer1.xml' : 1208: *OFF);

   // Perhaps you will only use the row elemet:
   pRows = xml_locate(pResult: 'rows');

   showme = xml_AsXmlText(pRows); 

   // The rows object alone:
   xml_WriteXmlStmf (pRows: '/prj/noxdb/testout/customer2.xml' : 1208: *OFF);

   // Cleanup: Close the SQL cursors, dispose the rows, arrays and disconnect
   xml_delete(pResult);
   xml_sqlDisconnect();
   
end-proc;

