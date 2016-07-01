      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin JSONparser in
      * IceBreak
      * ------------------------------------------------------------- *
     H BndDir('JSONPARSER') dftactgrp(*NO) ACTGRP('QILE')
      /include JSONparser
     D pJson           s               *
     D abc             s            256    varying
     D b               s            256    varying
     D c               s            256    varying
      /free
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
