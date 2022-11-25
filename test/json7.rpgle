
        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE' );

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pTplData     Pointer;
        Dcl-S pProp        Pointer;
        
        Dcl-C OS Const(x'9C');
        Dcl-C CS Const(x'47');

        //------------------------------------------------------------- *

        Dcl-Pi JSON7;
          pResult Char(50);
        End-Pi;

        pProp = json_ParseString (
           OS+
           '  name:"Company",      '+
           '  addr:"Smart city"    '+
           CS
        );
        
        If Json_Error(pProp) ;
           pResult = Json_Message(pProp);
           Json_dump(pProp);
           Json_delete(pProp);
           return;
        Endif;

        pTplData = json_NewObject();
        json_setValue(pTplData:'site':pProp:JSON_OBJCOPY);
        
        pResult = Json_GetStr(pTplData: '/site/addr');

        json_delete(pProp);
        json_delete(pTplData);

        *inlr = *on;
        return;

