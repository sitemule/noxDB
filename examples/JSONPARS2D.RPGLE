
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE');

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S a            Varchar(256);
        Dcl-S b            Varchar(256);
        Dcl-S c            Varchar(256);

        //------------------------------------------------------------- *

        // u00b5 is "Micro sign" and exists in ebcdic
        // u2318 is "sight of interest" icon and have no equvalent in ebedic so
        // \u2318 will be un touched in the input string
        pJson = nox_ParseString (
           '{  +
               a:"A valid unicode \u00b5 string",    +
               b:"An invalid unicode \u2318 string",  +
               c:"Escaped \\ string \"  data "        +
            }'
         );

        a  = nox_getStr(pJson: 'a');
        b  = nox_getStr(pJson: 'b');
        c  = nox_getStr(pJson: 'c');
        nox_WriteJsonStmf( pJson:
            './unicode-strings.json': 1208 : *OFF);
        nox_Close(pJson);
        *inlr = *on;
