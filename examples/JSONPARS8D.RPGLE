
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S p            Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S s            Varchar(50);
        Dcl-S n            Varchar(50);
        Dcl-S i            Int(10);

        //------------------------------------------------------------- *

        // First demo: find attribues which contains objects where attibutes has a value
        pJson = json_ParseString ('{e:{ -
          "a": { "x":1 , "y":"11"}, -
          "b": { "x":2 , "y":"22"}, -
          "c": { "x":3 , "y":"33"}  -
        }}');

        if json_Error(pJson) ;
           msg = JSON_Message(pJson);
           JSON_dump(pJson);
           JSON_Close(pJson);
           return;
        endif;

        // Get the object in the array where the "x" attribute has the value of 2
        p = json_locate  (pJson : '/e[x=2]');
        n = json_getName(p); // the is the "b" object
        s = json_getStr      (p : 'y' );

        JSON_Close(pJson);
        // Next demo: find attribues in arrays where attibutes has a value
        pJson = json_ParseString ('{e:[ -
          { "x":1 , "y":"11"}, -
          { "x":2 , "y":"22"}, -
          { "x":3 , "y":"33"}  -
        ]}');

        if json_Error(pJson) ;
           msg = json_Message(pJson);
           json_dump(pJson);
           json_Close(pJson);
           return;
        endif;

        // Get the object in the array where the "x" attribute has the value of 2
        p = json_locate  (pJson : '/e[x=2]');
        n = json_getName(p); // This object has no name since it is an element of an array
        s = json_getStr      (p : 'y' );

        *inlr = *on;
