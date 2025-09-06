
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pArr         Pointer;
        Dcl-S pB           Pointer;
        Dcl-S pC           Pointer;
        Dcl-S pD           Pointer;
        Dcl-S len          Int(5);
        Dcl-S t            Varchar(512);

        //------------------------------------------------------------- *
      
        pArr = nox_parseString('[a,b,c]');
        pB   = nox_lookupValue(pArr :  'B' : NOX_IGNORE_CASE);
        pC   = nox_lookupValue(pArr :  'c' : NOX_SAME_CASE);
        pC   = nox_lookupValue(pArr :  'c' ); // Same case is default
        pD   = nox_arrayPush(pArr : 'd');
        len  = nox_getLength(pArr);

        t =   nox_asJsonText(pArr);

        nox_close(pArr);
        *inlr = *on;
