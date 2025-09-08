
        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE');

        /include 'headers/XMLPARSER.rpgle'

        Dcl-S pXml         Pointer;
        Dcl-S pVisit       Pointer;
        Dcl-S pConsignment Pointer;
        Dcl-S xpath        Varchar(128);
        Dcl-S i            Int(10);
        Dcl-S consignments Int(10);
        Dcl-S orderRef     Int(10);
        Dcl-S customerCode Varchar(10);
        Dcl-S discrepancy  Ind;

        Dcl-S Result Varchar(50);

        Dcl-C OB Const(x'9E');
        Dcl-C CB Const(x'9F');

        //------------------------------------------------------------- *

        Dcl-PI XML3;
          pResult Char(50);
        End-Pi;

        Result = '';

        // First parse the XML stream
        pXml = nox_ParseFile('./test/documents/manifest.xml');
        if nox_Error(pXml) ;
           pResult = nox_Message(pXml);
           nox_delete(pXml);
           return;
        endif;

        // Not locate the "visit" and let it be the new temorary root
        // You can also use a comple reference from the root if you like
        pVisit = nox_locate(pXml:'/manifest/visit');
        if (pVisit =  *NULL);
           // If we did not found the "visit" element we die - remember to close the xml to avoid a leak
           pResult = 'null';
           nox_delete(pXml);
           return;
        endif;

         // Consignments is an array: use UBOUND to detect the numbers of entries
        consignments = %int(nox_GetValue(pVisit:'consignment' + 
                                                OB + 'UBOUND' + CB:'0'));

        // Now loop for each elemnt consignments. Note - x-path use 0 as the first element
        // Just for the fun we will find the element from the root - an absolute path
        // but from "pVisit" as root and the only the "consignment" index will work just fine
        for i = 0 to consignments -1;
           xpath = '/manifest/visit/consignment' + OB + %char(i) + CB;
           pConsignment = nox_locate(pXml: xpath );
           orderRef     = %int(nox_GetValue(pConsignment: 'orderRef':'0'));          // As number
           customerCode = nox_GetValue (pConsignment: 'customerCode');        // As string
           discrepancy  = 'NO' <>  nox_GetValue (pConsignment: 'discrepancy');      // As boolean

           Result += %Char(orderRef) + customerCode;
        endfor;

        pResult = Result;

        Return;