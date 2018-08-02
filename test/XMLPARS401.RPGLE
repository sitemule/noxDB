      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin XML parser in
      * IceBreak
      *
      *
      * ------------------------------------------------------------- *
     H BndDir('XMLPARSER') dftactgrp(*NO) ACTGRP('QILE')
      /include xmlparser
     d pXml            s               *
     d a               s             50    varying
     d msg             s            256    varying
     d p               s            256    varying
     d v               s          65000    based(pv)
     d pv              s               *
      /free
        // First parse the XML stream
        pXml = xml_ParseFile('/jsonxml/xml/largeSoapFile.xml');
        if Xml_Error(pXml) ;
           msg = xml_Message(pXml);
           xml_Close(pXml);
           return;
        endif;

        // Get payload tag
        p = '/envelope/body/gnreRespostaMsg/TResultLote_GNRE' +
         '/resultado';
        pv  = xml_getValuePtr(xml_locate(pXml:p));

        xml_Close(pXml);
        *inlr = *on;
