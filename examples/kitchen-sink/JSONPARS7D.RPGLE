        
        //------------------------------------------------------------- *

        //Join an array and return is as string
        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *
        
        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;

        //------------------------------------------------------------- *

        *inlr = *on;

        // Simple - on column
        pJson = nox_ParseString ('                          -
             [                                               -
                { key: "d" , value : 4 },                    -
                { key: "c" , value : 3 },                    -
                { key: "b" , value : 2 },                    -
                { key: "a"   value : 1 }                     -
             ]                                               -
        ');

        // Sort the array after the key field
        nox_arraySort(pJson : 'key' );

        // save as new file
        nox_WriteJsonStmf(pJson : '/jsonxml/sample7D.json' : 1208 : *OFF);

        nox_close(pJson);

        // Multiple keys
        pJson = nox_ParseString ('                          -
             [                                               -
                { keya: "b" , keyb: "2" , value : 4 },        -
                { keya: "b" , keyb: "1" , value : 3 },        -
                { keya: "a" , keyb: "2" , value : 2 },        -
                { keya: "a" , keyb: "1" , value : 1 }         -
             ]                                               -
        ');

        // Sort the array after the key field
        nox_arraySort(pJson : 'keya,keyb' );

        // save as new file
        nox_WriteJsonStmf(pJson : '/jsonxml/sample7D1.json' : 1208 : *OFF);

        nox_close(pJson);
