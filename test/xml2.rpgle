
        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');

        /include 'headers/XMLPARSER.rpgle'

        Dcl-S pXml         Pointer;
        Dcl-S pVisit       Pointer;
        Dcl-S manifestId   Int(10);
        Dcl-S visitId      Varchar(10);
        Dcl-S visitSeq     Int(10);

        Dcl-C AT Const(x'80');

        //------------------------------------------------------------- *

        dcl-pi *N;
          pResult Char(50);
        End-Pi;

        // First parse the XML stream
        pXml = xml_ParseFile('/prj/noxdb/testdata/manifest.xml');
        if Xml_Error(pXml) ;
           pResult = xml_Message(pXml);
           xml_delete(pXml);
           return;
        endif;

        // Get the manifest id: that is a attribue on the root hench the @
        manifestId = %int(xml_GetValue (pXml : '/manifest' + AT + 'ID':'0'));

        // Not locate the "visit" and let it be the new temorary root
        // You can also use a comple reference from the root if you like
        pVisit = xml_locate(pXml:'/manifest/visit');
        if (pVisit =  *NULL);
           // If we did not found the "visit" element we die - remember to close the xml to avoid a leak
           pResult = 'null';
           xml_delete(pXml);
           return;
        endif;

        // Now extrace the values from the "visit" tag - some are attribues, some are elements
        visitId   = xml_GetValue (pVisit: AT + 'ID'); // As String
        visitSeq  = %int(xml_getValue(pVisit: AT + 'sequence':'0')); // As Number

        pResult = %Char(manifestId) + visitID + %Char(visitSeq);

        Return;