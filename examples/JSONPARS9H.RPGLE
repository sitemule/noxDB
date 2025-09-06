
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE');

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pList        Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S value        Varchar(40);
        Dcl-DS list  likeds(nox_iterator);
        End-DS;

        //------------------------------------------------------------- *

        // List elements:
        pList = nox_ParseString('["a","b","c"]');

        // Using an iterator
        list = nox_setIterator(pList);
        dow nox_ForEach(list);
           value = nox_GetStr (list.this );
        enddo;

        nox_Close(pList);
        *inlr = *on;
