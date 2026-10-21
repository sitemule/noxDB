
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *
        
        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S p            Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S s            Varchar(50);
        Dcl-S i            Int(10);

        //------------------------------------------------------------- *

        pJson = nox_ParseString ('{e:[ -
          { "name":"a", "val":"a1"}, -
          { "name":"b", "o": [ -
              { "x":"x1", "q":"11"}, -
              { "x":"x2", "r":"22"}, -
              { "x":"x3", "s":"33"}, -
              { "k":true  , "r":"88"}, -
            ]                        -
          },                         -
          { "name":"c", "val":"c3"} -
        ]}');

        if NOX_Error(pJson) ;
           msg = NOX_Message(pJson);
           NOX_dump(pJson);
           NOX_Close(pJson);
           return;
        endif;

        // Get the object n the array where the "name" attribute is "b"
        p = nox_locate  (pJson : '/e[name=b]/o[k=true]');
        s = nox_getStr      (p : 'r' );

        *inlr = *on;
