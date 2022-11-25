
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE' );
        
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

        pJson = JSON_ParseFile ('/www/systest/demo2.json':'');

        if JSON_Error(pJson) ;
           msg = JSON_Message(pJson);
           dsply msg;
           JSON_dump(pJson);
           JSON_Close(pJson);
           return;
        endif;


        // Loop on the array
        pArr  = JSON_locate(pJson: '/[0]'); // First array element
        dow (pArr <> *NULL) ;
          // Loop all elements in that array element
          e  = json_GetChild (pArr);
          dow (e  <> *NULL) ;
            n =  json_getName  (e);
            v =  json_getValue (e);
            e  = json_GetNext  (e);
          endDo;
          pArr  = JSON_getNext(pArr);
        endDo;

        JSON_dump(pJson);
        JSON_Close(pJSON);
        *inlr = *on;
