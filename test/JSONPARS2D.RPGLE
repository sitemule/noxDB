      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin JSONparser in
      * IceBreak
      * ------------------------------------------------------------- *
     H BndDir('JSONPARSER') dftactgrp(*NO) ACTGRP('QILE')
      /include qAspHdr,JSONparser
     D pJson           s               *
     D a               s            256    varying
     D b               s            256    varying
     D c               s            256    varying
      /free
        // u00b5 is "Micro sign" and exists in ebcdic
        // u2318 is "sight of interest" icon and have no equvalent in ebedic so
        // \u2318 will be un touched in the input string
        pJson = json_ParseString (
           '{  +
               a:"A valid unicode \u00b5 string",    +
               b:"An invalid unicode \u2318 string",  +
               c:"Escaped \\ string \"  data "        +
            }'
         );

        a  = json_getStr(pJson: 'a');
        b  = json_getStr(pJson: 'b');
        c  = json_getStr(pJson: 'c');
        json_WriteJsonStmf( pJson:
            '/jsonxml/json/unicode-strings.json': 1208 : *OFF);
        json_Close(pJson);
        *inlr = *on;
