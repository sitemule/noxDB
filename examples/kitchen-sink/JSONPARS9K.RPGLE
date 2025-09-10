
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

        // Normal parse a file
        pJson = Nox_ParseFile ('/samples/json/simple.json');

        // Now load an other json into a new memory segment
        pSegment = nox_SegmentSelectNo(1);
        pJson2 = Nox_ParseFile ('/samples/json/demo.json');
        pNode = nox_Locate(pJson2 : '/o/f');
        name =  nox_GetStr(pNode);   // Show john
        //nox_Delete(pNode);        // Delete john

        // !! don't use close when using segments!!
        // !! Nox_Close(pJson2);  << Dont do this in segments
        Nox_Close(pJson2);

        // Always dispose the complete Segment
        nox_SegmentDispose(pSegment);

        // Always close nodes not within segments
        Nox_Close(pJson);

         nox_memstat();

