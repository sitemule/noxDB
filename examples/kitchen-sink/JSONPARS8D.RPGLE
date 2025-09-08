
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

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
        pJson = nox_ParseString ('{e:{ -
          "a": { "x":1 , "y":"11"}, -
          "b": { "x":2 , "y":"22"}, -
          "c": { "x":3 , "y":"33"}  -
        }}');

        if nox_Error(pJson) ;
           msg = NOX_Message(pJson);
           NOX_dump(pJson);
           NOX_Close(pJson);
           return;
        endif;

        // Get the object in the array where the "x" attribute has the value of 2
        p = nox_locate  (pJson : '/e[x=2]');
        n = nox_getName(p); // the is the "b" object
        s = nox_getStr      (p : 'y' );

        NOX_Close(pJson);
        // Next demo: find attribues in arrays where attibutes has a value
        pJson = nox_ParseString ('{e:[ -
          { "x":1 , "y":"11"}, -
          { "x":2 , "y":"22"}, -
          { "x":3 , "y":"33"}  -
        ]}');

        if nox_Error(pJson) ;
           msg = nox_Message(pJson);
           nox_dump(pJson);
           nox_Close(pJson);
           return;
        endif;

        // Get the object in the array where the "x" attribute has the value of 2
        p = nox_locate  (pJson : '/e[x=2]');
        n = nox_getName(p); // This object has no name since it is an element of an array
        s = nox_getStr      (p : 'y' );

        *inlr = *on;
