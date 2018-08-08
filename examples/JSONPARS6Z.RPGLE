        //------------------------------------------------------------- *
        //This sample shows the use of the build-in Json/XML parser
        //------------------------------------------------------------- *
        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE');
      /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        *inlr = *on;

        // My root json
        pJson  = json_ParseString ( '{ a:99, b:77 }');

        // Set by location name (paramter 2) .. set c to 3
        json_SetInt    (pJson : 'c'  : 3 );

        // Merge object into  the root ( note the location is blank )
        // Note: value from a is replaced and d is added since modifier is "MO_MERGE_REPLACE"
        json_SetValue  (pJson : '' : '{a:1,d:4}' :JSON_EVAL+MO_MERGE_REPLACE);

        // Merge object into  the root ( note the location is blank )
        // Note: value from b is unchaned but e is set with "MO_MERGE_NEW" , since b exists and e dont
        json_SetValue  (pJson : '' : '{b:88,e:5}' :JSON_EVAL+MO_MERGE_NEW    );

        // Merge object into  the root ( note the location is blank )
        // Note: value from b is changed  but f is not merged since it does not exists
        json_SetValue  (pJson : '' : '{b:2,f:66}' :JSON_EVAL+MO_MERGE_MATCH  );

        // Finally - add an new array to the root with two object
        json_SetValue  (pJson : 'arr1:[]' : '{x:1,y:2}' : JSON_EVAL);
        json_SetValue  (pJson : 'arr1:[]' : '{x:3,y:4}' : JSON_EVAL);

        // Write it out:
        Json_WriteStmf (pJson  :
           '/samples/json/jsonout-set-By-Parse.json':1208:*OFF
        );

        // Always close
        json_Close(pJson);

