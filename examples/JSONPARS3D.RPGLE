        //------------------------------------------------------------- *
        //This sample shows array handleing


        //------------------------------------------------------------- *
        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );
        Dcl-S pArr         Pointer;
        Dcl-S pB           Pointer;
        Dcl-S pC           Pointer;
        Dcl-S pD           Pointer;
        Dcl-S len          Int(5);
        Dcl-S t            Varchar(512);
      /include 'headers/JSONPARSER.rpgle'
        pArr = json_parseString('[a,b,c]');
        pB   = json_lookupValue(pArr :  'B' : JSON_IGNORE_CASE);
        pC   = json_lookupValue(pArr :  'c' : JSON_SAME_CASE);
        pC   = json_lookupValue(pArr :  'c' ); // Same case is default
        pD   = json_arrayPush(pArr : 'd');
        len  = json_getLength(pArr);

        t =   json_asJsonText(pArr);

        json_close(pArr);
        *inlr = *on;
