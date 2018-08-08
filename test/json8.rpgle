
        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pData        Pointer;
        Dcl-S a            Pointer;
        Dcl-S c            Pointer;

        //------------------------------------------------------------- *

        Dcl-Pi JSON8;
          pResult Char(50);
        End-Pi;

        pData = json_ParseString (
           '{                      '+
           '  a:123                '+
           '}'
        );

        // Find the "a" node in the data object:
        a = json_locate(pData : 'a');

        // add "d" after "a"
        json_NodeAdd(a:JSON_AFTER_SIBLING :'d':'d value':JSON_VALUE);

        // now add c between a and d ( LITERALS and VALUES are supported)
        // note: we return the pointer to to node:
        c = json_NodeAdd(a:JSON_AFTER_SIBLING:'c':'12':JSON_LITERAL);

        // now add b before c
        json_NodeAdd(c:JSON_BEFORE_SIBLING:'b':'true':JSON_LITERAL);

        // write a,b,c,d in this order:
        pResult = json_asJsonText(pData:'/');

        json_Close(pData);
        *inlr = *on;
        return;

