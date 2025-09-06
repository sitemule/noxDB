
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pData        Pointer;
        Dcl-S pTplData     Pointer;
        Dcl-S pProp        Pointer;

        //------------------------------------------------------------- *

        pData = nox_ParseString (
           '{                      '+
           '  a:123,               '+
           '  b:"text",            '+
           '  c:"More text"        '+
           '}'
        );
        pProp = nox_ParseString (
           '{                      '+
           '  name:"Company",      '+
           '  addr:"Smart city"    '+
           '}'
        );
        pTplData = nox_NewObject();
        nox_setValue(pTplData :'this' : pData      : nox_OBJCOPY);
        nox_setValue(pTplData :'site' : pProp      : nox_OBJCOPY);
        nox_WritejsonStmf(pTplData : './props.json' : 1208 : *OFF);

        nox_Close(pProp    );
        nox_Close(pData    );
        nox_Close(pTplData );
        *inlr = *on;
        return;

