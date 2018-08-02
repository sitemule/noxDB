      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin JSONparser in
      * IceBreak
      *
      * ------------------------------------------------------------- *
     H BndDir('XMLPARSER') dftactgrp(*NO) ACTGRP('QILE')
      /include QASPHDR,JSONparser
     d pJson           s               *
     d pJson2          s               *
     d pSegment        s               *
     d pNode           s               *
     d name            s             64    varying
      * ------------------------------------------------------------- *
      /free
        *inlr = *on;

        // Load an other json into a new memory segment
        pSegment = json_SegmentSelectNo(1);
        pJson2 = Json_ParseFile ('/samples/json/demo.json');
        pNode = json_Locate(pJson2 : '/o/f');
        name =  json_GetStr(pNode);   // Show john
        json_NodeDelete(pNode);        // Delete john

        // Always dispose the complete Segment
        json_SegmentDispose(pSegment);

        json_memstat();

