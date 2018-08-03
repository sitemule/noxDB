      * ------------------------------------------------------------- *
      * This sample shows the use of the build-in Json/XML parser
      * ------------------------------------------------------------- *
     H BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE')
      /include qAspHdr,JsonParser
     D pJson           s               *
     D pText           s               *
      /free
        *inlr = *on;

        // My root json
        pJson  = json_ParseString (' -
            { text: { da: "Danish" , en: "English" }, -
               abc: "123"   -
            }  -
        ');
        json_SetValue  (pJson : 'mix'  : 'Yes');

        pText  = json_ParseString ( '{ sv: "Swe"                 }');

        // Set by location name
        json_SetValue  (pJson : 'text'  : pText : JSON_OBJCOPY );


        // Write it out:
        Json_WriteStmf (pJson  :
           '/samples/json/jsonout-set-value-to-object.json':1208:*OFF
        );

        // Write it out:
        Json_WriteStmf (pText  :
           '/samples/json/jsonout-ptext.json':1208:*OFF
        );

        // Always close
        json_Close(pText);
        json_Close(pJson);

