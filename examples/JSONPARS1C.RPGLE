
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pJson        Pointer;
        Dcl-S pNode        Pointer;
        Dcl-S pArr         Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S tag          Varchar(50);
        Dcl-S value        Varchar(50);
        Dcl-S n            Packed(15:2);

        //------------------------------------------------------------- *

        *inlr = *on;
        pJson = Json_ParseFile ('./test/documents/demo.json');

        if Json_Error(pJson) ;
           msg = Json_Message(pJson);
           dsply msg;
           Json_dump(pJson);
           Json_Close(pJson);
           return;
        endif;

        pNode = Json_locate(pJson: '/o/n');
        n     = Json_getNum(pNode);

        pNode = Json_locate(pJson: '/a[1]');
        n     = Json_GetNum (pNode);

        pNode = Json_locate(pJson: '/s');
        value = Json_getStr(pNode);

        pNode = Json_locate(pJson: '/u');
        value = Json_getStr(pNode);

        pNode = Json_locate(pJson: '/o/a[2]');
        n     = Json_GetNum(pNode);

        // Loop on the array
        pArr  = Json_locate(pJson: '/o/a[0]'); // First array element
        dow (pArr <> *NULL) ;
          n     = Json_GetNum (pArr);
          pArr  = Json_GetNext(pArr);
        endDo;

        // Loop the root: Note the  "/" will position to the first chile of the root
        pNode  = Json_locate(pJson: '/'); // First array element
        dow (pNode <> *NULL) ;
          value  = Json_GetStr (pNode);
          pNode  = Json_GetNext(pNode);
        endDo;

        // Get Value directly
        value = Json_GetStr    (pJson : '/u');

        // Get Value directly relative
        pNode = Json_locate(pJson: '/o');
        value = Json_GetStr (pNode : 'n');   // This is "n" in "o"

        // Get number of entries in arrays
        n  = Json_GetNum(pJson : '/o/a[UBOUND]': -1 );

        Json_dump(pJson);
        Json_Close(pJson);
