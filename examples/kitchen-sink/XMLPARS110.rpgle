
        //------------------------------------------------------------- *

        //The XML file we want to parse in this sample look like:

        //<?xml version="1.0" encoding="utf-8"?>
        //<manifest ID="123456">
        //<visit ID="ABCDE" sequence="10">
        //<datetimeActualArrival>2011-11-07T09:28:23.520</datetimeActualArriva
        //<datetimeActualDeparture>2011-11-07T09:28:49.550</datetimeActualDepa
        //<late>LATE</late>
        //<callSequence>10</callSequence>
        //<consignment type="delivery">
        //<orderRef>123123</orderRef>
        //<customerCode>CUST1</customerCode>
        //<discrepancy>NO</discrepancy>
        //</consignment>
        //<consignment type="delivery">
        //<orderRef>123124</orderRef>
        //<customerCode>CUST2</customerCode>
        //<discrepancy>NO</discrepancy>
        //</consignment>
        //<consignment type="collection">
        //<orderRef>123125</orderRef>
        //<customerCode>CUST3</customerCode>
        //<discrepancy>NO</discrepancy>
        //</consignment>
        //</visit>
        //</manifest>

        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE');

        //------------------------------------------------------------- *

        /include xmlparser
        Dcl-S pXml         Pointer;
        Dcl-S pVisit       Pointer;
        Dcl-S pConsignment Pointer;
        Dcl-S pConsArr     Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S xpath        Varchar(128);
        Dcl-S i            Int(10);
        Dcl-S manifestId   Int(10);
        Dcl-S visitId      Varchar(10);
        Dcl-S visitSeq     Int(10);
        Dcl-S arrival      Timestamp;
        Dcl-S consignments Int(10);
        Dcl-S orderRef     Int(10);
        Dcl-S customerCode Varchar(10);
        Dcl-S discrepancy  Ind;

        //------------------------------------------------------------- *

        // First parse the XML stream
        pXml = nox_ParseFile('/udv/expert/manifest.xml');
        if nox_Error(pXml) ;
           msg = nox_Message(pXml);
           nox_Close(pXml);
           return;
        endif;

        // Get the manifest id: that is a attribue on the root hench the @
        manifestId = %int(nox_GetValue (pXml : '/manifest@ID':'0'));

        // Not locate the "visit" and let it be the new temorary root
        // You can also use a comple reference from the root if you like
        pVisit = nox_locate(pXml:'/manifest/visit');
        if (pVisit =  *NULL);
           // If we did not found the "visit" element we die - remember to close the xml to avoid a leak
           nox_Close(pXml);
           return;
        endif;

        // Now extrace the values from the "visit" tag - some are attribues, some are elements
        visitId   = nox_GetValue (pVisit: '@ID');                         // As String
        visitSeq  = %int(nox_getValue(pVisit: '@sequence':'0'));                // As Number
        // arrival   = CvtWsTs2Ts(nox_GetValue (pVisit: 'datetimeActualArrival')); // As DB/2 timestamp

        // Consignments is an array: use UBOUND to detect the numbers of entries
        consignments = %int(nox_GetValue(pVisit:'consignment[UBOUND]':'0'));

        // Now loop for each elemnt consignments. Note - x-path use 0 as the first element
        // Just for the fun we will find the element from the root - an absolute path
        // but from "pVisit" as root and the only the "consignment" index will work just fine
        for i = 0 to consignments -1;
           xpath = '/manifest/visit/consignment[' + %char(i) + ']';
           pConsignment = nox_locate(pXml: xpath );
           orderRef     = %int(nox_GetValue(pConsignment: 'orderRef':'0'));          // As number
           customerCode = nox_GetValue (pConsignment: 'customerCode');        // As string
           discrepancy  = 'NO' <>  nox_GetValue (pConsignment: 'discrepancy');      // As boolean
        endfor;

        nox_Close(pXml);
        *inlr = *on;
