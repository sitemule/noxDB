        
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S msg          Varchar(50);

        //------------------------------------------------------------- *

     C     *entry        plist
     C                   parm                    file            128
     C                   parm                    text             64
     C                   parm                    origin            3
        pJson = NOX_ParseFile   ( file);
        if NOX_Error(pJson) ;
           msg = NOX_Message(pJson);
           NOX_Close(pJson);
           return;
        endif;

        nox_SetValue(pJson : '/session/preset/text'  : Text);
        nox_SetValue(pJson : '/session/preset/origin': Origin);

        nox_WriteStmf  (pJson : file  : 1208 : *OFF);
        NOX_Close(pJSON);
        *inlr = *on;
