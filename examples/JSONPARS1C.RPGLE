
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

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
        pJson = Nox_ParseFile ('./test/documents/demo.json');

        if Nox_Error(pJson) ;
           msg = Nox_Message(pJson);
           dsply msg;
           Nox_dump(pJson);
           Nox_Close(pJson);
           return;
        endif;

        pNode = Nox_locate(pJson: '/o/n');
        n     = Nox_getNum(pNode);

        pNode = Nox_locate(pJson: '/a[1]');
        n     = Nox_GetNum (pNode);

        pNode = Nox_locate(pJson: '/s');
        value = Nox_getStr(pNode);

        pNode = Nox_locate(pJson: '/u');
        value = Nox_getStr(pNode);

        pNode = Nox_locate(pJson: '/o/a[2]');
        n     = Nox_GetNum(pNode);

        // Loop on the array
        pArr  = Nox_locate(pJson: '/o/a[0]'); // First array element
        dow (pArr <> *NULL) ;
          n     = Nox_GetNum (pArr);
          pArr  = Nox_GetNext(pArr);
        endDo;

        // Loop the root: Note the  "/" will position to the first chile of the root
        pNode  = Nox_locate(pJson: '/'); // First array element
        dow (pNode <> *NULL) ;
          value  = Nox_GetStr (pNode);
          pNode  = Nox_GetNext(pNode);
        endDo;

        // Get Value directly
        value = Nox_GetStr    (pJson : '/u');

        // Get Value directly relative
        pNode = Nox_locate(pJson: '/o');
        value = Nox_GetStr (pNode : 'n');   // This is "n" in "o"

        // Get number of entries in arrays
        n  = Nox_GetNum(pJson : '/o/a[UBOUND]': -1 );

        Nox_dump(pJson);
        Nox_Close(pJson);
