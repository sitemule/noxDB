
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE');

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S pJson2       Pointer;
        Dcl-S pSegment     Pointer;
        Dcl-S pNode        Pointer;
        Dcl-S name         Varchar(64);

        //------------------------------------------------------------- *

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

