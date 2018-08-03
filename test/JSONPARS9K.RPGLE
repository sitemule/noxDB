      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin JSONparser in
      * IceBreak
      *
      * ------------------------------------------------------------- *
     H BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE')
      /include 'headers/JSONPARSER.rpgle'
     d pJson           s               *
     d pJson2          s               *
     d pSegment        s               *
     d pNode           s               *
     d name            s             64    varying
      * ------------------------------------------------------------- *
      /free
        *inlr = *on;
        // Normal parse a file
        pJson = Json_ParseFile ('/samples/json/simple.json');

        // Now load an other json into a new memory segment
        pSegment = json_SegmentSelectNo(1);
        pJson2 = Json_ParseFile ('/samples/json/demo.json');
        pNode = json_Locate(pJson2 : '/o/f');
        name =  json_GetStr(pNode);   // Show john
        //json_NodeDelete(pNode);        // Delete john

        // !! don't use close when using segments!!
        // !! Json_Close(pJson2);  << Dont do this in segments
        Json_Close(pJson2);

        // Always dispose the complete Segment
        json_SegmentDispose(pSegment);

        // Always close nodes not within segments
        Json_Close(pJson);

         json_memstat();

