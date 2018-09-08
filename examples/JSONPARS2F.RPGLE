
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pData        Pointer;
        Dcl-S pTplData     Pointer;
        Dcl-S pProp        Pointer;

        //------------------------------------------------------------- *

        pData = json_ParseString (
           '{                      '+
           '  a:123,               '+
           '  b:"text",            '+
           '  c:"More text"        '+
           '}'
        );
        pProp = json_ParseString (
           '{                      '+
           '  name:"Company",      '+
           '  addr:"Smart city"    '+
           '}'
        );
        pTplData = json_NewObject();
        json_setValue(pTplData :'this' : pData      : json_OBJCOPY);
        json_setValue(pTplData :'site' : pProp      : json_OBJCOPY);
        json_WritejsonStmf(pTplData : './props.json' : 1208 : *OFF);

        json_Close(pProp    );
        json_Close(pData    );
        json_Close(pTplData );
        *inlr = *on;
        return;

