
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE');

        //------------------------------------------------------------- *

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
        pSegment1 = nox_SegmentSelectNo(1);
        pJson1 = Nox_ParseFile ('/samples/json/demo.json');
        pNode = nox_Locate(pJson1 : '/'); // Delete root ... empty all
        nox_NodeDelete(pNode);        // Delete john


        // Load an other json into a new memory segment
        pSegment2= nox_SegmentSelectNo(2);
        pJson2 = Nox_ParseFile ('/samples/json/demo.json');
        pNode = nox_Locate(pJson2 : '/o/f');
        name =  nox_GetStr(pNode);   // Show john

        // Always dispose the complete Segment
        nox_SegmentDispose(pSegment1);
        nox_SegmentDispose(pSegment2);

        nox_memstat();

