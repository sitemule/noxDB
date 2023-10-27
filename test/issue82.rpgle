**free
    Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

    /include 'headers/jsonparser.rpgle'

    Dcl-S pJson        Pointer;
    Dcl-S pA           Pointer;
    Dcl-S result       varchar(4096);


    //------------------------------------------------------------- *
    pJson = json_parseString('{-
        "top@root": { -
            "name@text.txt" : { -
                "with blank" : "some text" -
            }, -
            "array@keys" : [ -
                {"key 1" : "text1"}, -
                {"key 2" : "text2"} -
            ] -
        } -
    }');

    // Test serialization of only selected elements
    Result = json_asJsonText (pJson);
    json_WriteJsonStmf (pJson: '/prj/noxdb/testout/selected-1.json' : 1208: *OFF);

    pA = json_locate(pJson : '/"top@root"/"name@text.txt"');
    Result = json_asJsonText (pA);
    json_WriteJsonStmf (pA: '/prj/noxdb/testout/selected-2.json' : 1208: *OFF);


    pA = json_locate(pJson : '/"top@root"/"name@text.txt"/"with blank"');
    Result = json_asJsonText (pA);
    Result = json_getStr  (pJson : '/"top@root"/"name@text.txt"/"with blank"');
    json_WriteJsonStmf (pA: '/prj/noxdb/testout/selected-3.json' : 1208: *OFF);


    pA = json_locate(pJson : '/"top@root"/"array@keys"[0]');
    Result = json_asJsonText (pA);
    Result = json_getStr  (pJson : '/"top@root"/"array@keys"[0]');
    Result = json_getStr  (pJson : '/"top@root"/"array@keys"[1]');


    json_delete(pJson);

    Return;