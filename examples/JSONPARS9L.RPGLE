
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE');

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
        pSegment = nox_SegmentSelectNo(1);
        pJson2 = Nox_ParseFile ('/samples/json/demo.json');
        pNode = nox_Locate(pJson2 : '/o/f');
        name =  nox_GetStr(pNode);   // Show john
        nox_NodeDelete(pNode);        // Delete john

        // Always dispose the complete Segment
        nox_SegmentDispose(pSegment);

        nox_memstat();

