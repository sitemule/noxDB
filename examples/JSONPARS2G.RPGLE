
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pData        Pointer;
        Dcl-S a            Pointer;
        Dcl-S c            Pointer;

        //------------------------------------------------------------- *
        
        pData = json_ParseString (
           '{                      '+
           '  a:123                '+
           '}'
        );
        // Find the "a" node in the data object:
        a = json_locate(pData : 'a');

        // add "d" after "a"
        json_NodeInsert(a:JSON_AFTER_SIBLING :'d':'value for d':JSON_VALUE);

        // now add c between a and d ( LITERALS and VALUES are supported)
        // note: we return the pointer to to node:
        c = json_NodeInsert(a:JSON_AFTER_SIBLING:'c': '1237' : JSON_LITERAL);

        // now add b before c
        json_NodeInsert(c:JSON_BEFORE_SIBLING:'b':'true': JSON_LITERAL);

        // write a,b,c,d in this order:
        json_WritejsonStmf(pData:'/jsonxml/json/NodeInsert-1.json':1208:*OFF);

        json_Close(pData );
        *inlr = *on;
        return;

