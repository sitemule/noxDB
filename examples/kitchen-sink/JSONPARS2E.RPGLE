
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE');

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S abc          Varchar(256);
        Dcl-S b            Varchar(256);
        Dcl-S c            Varchar(256);

        //------------------------------------------------------------- *
        
        pJson = nox_ParseString (
           '{  +
               "a.b.c":"Text for a.b.c." +
            }'
         );

        // Not found - since the '.' is ne notation for "member of"
        abc  = nox_getStr(pJson: 'a.b.c');

        // Now replace the  '.' notation with a |
        nox_setDelimiters('/\@[] |');

        // Works  !!
        abc  = nox_getStr(pJson: 'a.b.c');

        // Done
        nox_Close(pJson);
        *inlr = *on;
