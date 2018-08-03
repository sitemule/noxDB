      * ------------------------------------------------------------- *
      * This sample shows array handleing
      *
      *
      * ------------------------------------------------------------- *
     H BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' )
     D pArr            s               *
     D pB              s               *
     D pC              s               *
     D pD              s               *
     D len             s              5i 0
     D t               s            512a   varying
      /include JsonParser
      /free
        pArr = json_parseString('[a,b,c]');
        pB   = json_lookupValue(pArr :  'B' : JSON_IGNORE_CASE);
        pC   = json_lookupValue(pArr :  'c' : JSON_SAME_CASE);
        pC   = json_lookupValue(pArr :  'c' ); // Same case is default
        pD   = json_arrayPush(pArr : 'd');
        len  = json_getLength(pArr);

        t =   json_asJsonText(pArr);

        json_close(pArr);
        *inlr = *on;
