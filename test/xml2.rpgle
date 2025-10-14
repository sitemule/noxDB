
        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE');

        /include 'headers/XMLPARSER.rpgle'

        Dcl-S pXml         Pointer;
        Dcl-S pVisit       Pointer;
        Dcl-S manifestId   Int(10);
        Dcl-S visitId      Varchar(10);
        Dcl-S visitSeq     Int(10);

        Dcl-C AT Const(x'80');

        //------------------------------------------------------------- *

        Dcl-PI XML2;
          pResult Char(50);
        End-Pi;

        // First parse the XML stream
        pXml = nox_ParseFile('./test/documents/manifest.xml');
        if nox_Error(pXml) ;
           pResult = nox_Message(pXml);
           nox_delete(pXml);
           return;
        endif;

        // Get the manifest id: that is a attribue on the root hench the @
        manifestId = %int(nox_GetValue (pXml : '/manifest' + AT + 'ID':'0'));

        // Not locate the "visit" and let it be the new temorary root
        // You can also use a comple reference from the root if you like
        pVisit = nox_locate(pXml:'/manifest/visit');
        if (pVisit =  *NULL);
           // If we did not found the "visit" element we die - remember to close the xml to avoid a leak
           pResult = 'null';
           nox_delete(pXml);
           return;
        endif;

        // Now extrace the values from the "visit" tag - some are attribues, some are elements
        visitId   = nox_GetValue (pVisit: AT + 'ID'); // As String
        visitSeq  = %int(nox_getValue(pVisit: AT + 'sequence':'0')); // As Number

        pResult = %Char(manifestId) + visitID + %Char(visitSeq);

        Return;