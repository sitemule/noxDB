
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pList        Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S value        Varchar(40);
        Dcl-DS list  likeds(json_iterator);
        End-DS;

        //------------------------------------------------------------- *

        // List elements:
        pList = json_ParseString('["a","b","c"]');

        // Using an iterator
        list = json_setIterator(pList);
        dow json_ForEach(list);
           value = json_GetStr (list.this );
        enddo;

        json_Close(pList);
        *inlr = *on;
