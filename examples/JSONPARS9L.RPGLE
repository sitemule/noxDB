
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S pJson2       Pointer;
        Dcl-S pSegment     Pointer;
        Dcl-S pNode        Pointer;
        Dcl-S name         Varchar(64);

        //------------------------------------------------------------- *
        
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

