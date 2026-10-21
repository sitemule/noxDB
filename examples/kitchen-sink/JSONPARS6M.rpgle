
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE');

        //------------------------------------------------------------- *
        
        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S pText        Pointer;

        //------------------------------------------------------------- *

        *inlr = *on;

        // My root json
        pJson  = nox_ParseString (' -
            { text: { da: "Danish" , en: "English" }, -
               abc: "123"   -
            }  -
        ');
        nox_SetValue  (pJson : 'mix'  : 'Yes');

        pText  = nox_ParseString ( '{ sv: "Swe"                 }');

        // Set by location name
        nox_SetValue  (pJson : 'text'  : pText : NOX_OBJCOPY );


        // Write it out:
        Nox_WriteStmf (pJson  :
           './jsonout-set-value-to-object.json':1208:*OFF
        );

        // Write it out:
        Nox_WriteStmf (pText  :
           './jsonout-ptext.json':1208:*OFF
        );

        // Always close
        nox_Close(pText);
        nox_Close(pJson);

