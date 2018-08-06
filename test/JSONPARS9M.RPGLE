        //------------------------------------------------------------- *
        //This sample shows the use of the buildin JSONparser in
        //IceBreak

        //------------------------------------------------------------- *
        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE');
      /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson1       Pointer;
        Dcl-S pJson2       Pointer;
        Dcl-S pSegment1    Pointer;
        Dcl-S pSegment2    Pointer;
        Dcl-S pNode        Pointer;
        Dcl-S name         Varchar(64);
        //------------------------------------------------------------- *
        *inlr = *on;

        // Load an other json into a new memory segment
        pSegment1 = json_SegmentSelectNo(1);
        pJson1 = Json_ParseFile ('/samples/json/demo.json');
        pNode = json_Locate(pJson1 : '/'); // Delete root ... empty all
        json_NodeDelete(pNode);        // Delete john


        // Load an other json into a new memory segment
        pSegment2= json_SegmentSelectNo(2);
        pJson2 = Json_ParseFile ('/samples/json/demo.json');
        pNode = json_Locate(pJson2 : '/o/f');
        name =  json_GetStr(pNode);   // Show john

        // Always dispose the complete Segment
        json_SegmentDispose(pSegment1);
        json_SegmentDispose(pSegment2);

        json_memstat();

