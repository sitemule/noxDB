      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin jsonparser in
      * IceBreak
      *
      * ------------------------------------------------------------- *
     H BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' )
     D pData           s               *
     D a               s               *
     D c               s               *
      /include jsonparser
      /free
        pData = json_ParseString (
           '{                      '+
           '  a:123                '+
           '}'
        );
        // Find the "a" node in the data object:
        a = json_locate(pData : 'a');

        // add "d" after "a"
        json_NodeAdd(a:JSON_AFTER_SIBLING :'d':'value for d':JSON_VALUE);

        // now add c between a and d ( LITERALS and VALUES are supported)
        // note: we return the pointer to to node:
        c = json_NodeAdd(a:JSON_AFTER_SIBLING:'c': '1237' : JSON_LITERAL);

        // now add b before c
        json_NodeAdd(c:JSON_BEFORE_SIBLING:'b':'true': JSON_LITERAL);

        // write a,b,c,d in this order:
        json_WritejsonStmf(pData:'/jsonxml/json/nodeadd-1.json':1208:*OFF);

        json_Close(pData );
        *inlr = *on;
        return;

