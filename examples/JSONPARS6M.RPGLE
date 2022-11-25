
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE');

        //------------------------------------------------------------- *
        
        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S pText        Pointer;

        //------------------------------------------------------------- *

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
           './jsonout-set-value-to-object.json':1208:*OFF
        );

        // Write it out:
        Json_WriteStmf (pText  :
           './jsonout-ptext.json':1208:*OFF
        );

        // Always close
        json_Close(pText);
        json_Close(pJson);

