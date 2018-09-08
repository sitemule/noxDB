
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE');

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S abc          Varchar(256);
        Dcl-S b            Varchar(256);
        Dcl-S c            Varchar(256);

        //------------------------------------------------------------- *
        
        pJson = json_ParseString (
           '{  +
               "a.b.c":"Text for a.b.c." +
            }'
         );

        // Not found - since the '.' is ne notation for "member of"
        abc  = json_getStr(pJson: 'a.b.c');

        // Now replace the  '.' notation with a |
        json_setDelimiters('/\@[] |');

        // Works  !!
        abc  = json_getStr(pJson: 'a.b.c');

        // Done
        json_Close(pJson);
        *inlr = *on;
