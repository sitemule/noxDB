
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pData        Pointer;
        Dcl-S a            Pointer;
        Dcl-S c            Pointer;

        //------------------------------------------------------------- *
        
        pData = nox_ParseString (
           '{                      '+
           '  a:123                '+
           '}'
        );
        // Find the "a" node in the data object:
        a = nox_locate(pData : 'a');

        // add "d" after "a"
        nox_NodeInsert(a:NOX_AFTER_SIBLING :'d':'value for d':NOX_VALUE);

        // now add c between a and d ( LITERALS and VALUES are supported)
        // note: we return the pointer to to node:
        c = nox_NodeInsert(a:NOX_AFTER_SIBLING:'c': '1237' : NOX_LITERAL);

        // now add b before c
        nox_NodeInsert(c:NOX_BEFORE_SIBLING:'b':'true': NOX_LITERAL);

        // write a,b,c,d in this order:
        nox_WritejsonStmf(pData:'/jsonxml/json/NodeInsert-1.json':1208:*OFF);

        nox_Close(pData );
        *inlr = *on;
        return;

