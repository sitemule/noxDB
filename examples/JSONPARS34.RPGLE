
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

        *inlr = *on;

        // First demo: find attribues which contains objects where attibutes has a value
        pJson = json_ParseString ('{-
           "__cid__":12,"title":{"da":"Kontakter","en":""},"image":"" -
        }');

        if json_Error(pJson) ;
           msg = JSON_Message(pJson);
           JSON_dump(pJson);
           JSON_Close(pJson);
           return;
        endif;

        // Get the object in the array where the "x" attribute has the value of 2
        s = json_getStr      (pJson : '/title/da' );
        s = json_getStr      (pJson : '/title/[0]' );
        s = json_getStr      (pJson : '/title'     );

        JSON_Close(pJson);
        // Next  demo: find attribues which contains objects where attibutes has a value
        pJson = json_ParseString ('{-
           "__cid__":12,"title": "Kontakter","image":"" -
        }');

        if json_Error(pJson) ;
           msg = JSON_Message(pJson);
           JSON_dump(pJson);
           JSON_Close(pJson);
           return;
        endif;

        // Get the object in the array where the "x" attribute has the value of 2
        s = json_getStr      (pJson : '/title/da' );
        s = json_getStr      (pJson : '/title/[0]' );
        s = json_getStr      (pJson : '/title'     );

        JSON_Close(pJson);

        *inlr = *on;
