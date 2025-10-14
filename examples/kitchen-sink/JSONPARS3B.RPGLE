
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );
        
        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S pNode        Pointer;
        Dcl-S pArr         Pointer;
        Dcl-S e            Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S tag          Varchar(50);
        Dcl-S s            Varchar(50);
        Dcl-S n            Varchar(50);
        Dcl-S v            Varchar(50);
        Dcl-S i            Int(10);

        //------------------------------------------------------------- *

        pJson = NOX_ParseFile ('/www/systest/demo2.json':'');

        if NOX_Error(pJson) ;
           msg = NOX_Message(pJson);
           dsply msg;
           NOX_dump(pJson);
           NOX_Close(pJson);
           return;
        endif;


        // Loop on the array
        pArr  = NOX_locate(pJson: '/[0]'); // First array element
        dow (pArr <> *NULL) ;
          // Loop all elements in that array element
          e  = nox_GetChild (pArr);
          dow (e  <> *NULL) ;
            n =  nox_getName  (e);
            v =  nox_getValue (e);
            e  = nox_GetNext  (e);
          endDo;
          pArr  = NOX_getNext(pArr);
        endDo;

        NOX_dump(pJson);
        NOX_Close(pJSON);
        *inlr = *on;
