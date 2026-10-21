
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

        *inlr = *on;

        // First demo: find attribues which contains objects where attibutes has a value
        pJson = nox_ParseString ('{-
           "__cid__":12,"title":{"da":"Kontakter","en":""},"image":"" -
        }');

        if nox_Error(pJson) ;
           msg = NOX_Message(pJson);
           NOX_dump(pJson);
           NOX_Close(pJson);
           return;
        endif;

        // Get the object in the array where the "x" attribute has the value of 2
        s = nox_getStr      (pJson : '/title/da' );
        s = nox_getStr      (pJson : '/title/[0]' );
        s = nox_getStr      (pJson : '/title'     );

        NOX_Close(pJson);
        // Next  demo: find attribues which contains objects where attibutes has a value
        pJson = nox_ParseString ('{-
           "__cid__":12,"title": "Kontakter","image":"" -
        }');

        if nox_Error(pJson) ;
           msg = NOX_Message(pJson);
           NOX_dump(pJson);
           NOX_Close(pJson);
           return;
        endif;

        // Get the object in the array where the "x" attribute has the value of 2
        s = nox_getStr      (pJson : '/title/da' );
        s = nox_getStr      (pJson : '/title/[0]' );
        s = nox_getStr      (pJson : '/title'     );

        NOX_Close(pJson);

        *inlr = *on;
