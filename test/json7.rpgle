
        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pTplData     Pointer;
        Dcl-S pProp        Pointer;

        //------------------------------------------------------------- *

        Dcl-Pi JSON7;
          pResult Char(50);
        End-Pi;

        pProp = json_ParseString (
           '{                      '+
           '  name:"Company",      '+
           '  addr:"Smart city"    '+
           '}'
        );

        pTplData = json_NewObject();
        json_setValue(pTplData:'site':pProp:JSON_OBJCOPY);
        
        pResult = json_asJsonText(pTplData);

        json_Close(pProp);
        json_Close(pTplData);

        *inlr = *on;
        return;

