        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE' );
    
        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pJson        Pointer;
        Dcl-S pArr         Pointer;
        Dcl-S Result       Varchar(50);
        Dcl-S n            Packed(15:2);
        
        Dcl-C OB Const(x'9E');
        Dcl-C CB Const(x'9F');
        
        //------------------------------------------------------------- *

        Dcl-Pi JSON5;
          pResult Char(50);
        End-Pi;
        
        Result = '';
        *inlr = *on;
        pJson = Json_ParseFile ('./test/documents/demo.json');

        if Json_Error(pJson) ;
           pResult = Json_Message(pJson);
           Json_dump(pJson);
           Json_delete(pJson);
           return;
        endif;
        
        // Loop on the array
        pArr  = Json_locate(pJson: '/o/a' + OB + '0' + CB); // First array element
        dow (pArr <> *NULL) ;
          n     = Json_GetNum (pArr);
          Result += %Char(n);

          pArr  = Json_GetNext(pArr);
        endDo;

        pResult = Result;

        Json_delete(pJson);

        Return;