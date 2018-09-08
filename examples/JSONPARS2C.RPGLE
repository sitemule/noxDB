
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
      
        pJson = JSON_ParseString (
           '{  u:"This is a unicode \u00b5 string"  ,   '+
           '   "s":"abc"                            ,   '+
           '   "e":"line1\nline2\rtab\ttabed     "  ,   '+
           '   a:[1,2,3],                   ' +
           '   o:{           ' +
           '     n:123   , ' +
           '     a:[10 , 20 , 30 ],                ' +
           '     m:"yyyy"  ' +
           '   }         '+
           '}'
             : '');
        if JSON_Error(pJson) ;
           msg = JSON_Message(pJson);
           JSON_dump(pJson);
           JSON_Close(pJson);
           return;
        endif;

        pNode = JSON_locate(pJson: '/o/n');
        n     = json_getNum(pNode);

        pNode = JSON_locate(pJson: '/a[1]');
        n     = json_getNum(pNode);

        pNode = JSON_locate(pJson: '/s');
        value = JSON_getValue(pNode);

        pNode = JSON_locate(pJson: '/u');
        value = JSON_getValue(pNode);

        pNode = JSON_locate(pJson: '/o/a[2]');
        n     = json_getNum(pNode);

        // Loop on the array
        pArr  = JSON_locate(pJson: '/o/a[0]'); // First array element
        dow (pArr <> *NULL) ;
          n     = json_getNum(pArr);
          pArr  = JSON_getNext(pArr);
        endDo;

        // Get Value directly
        value = json_getStr(pJson : '/u');

        // Get Value directly relative
        pNode = JSON_locate(pJson: '/o');
        value = json_getStr(pNode : 'n');   // This is "n" in "o"

        pNode = JSON_locate(pJson: '/a');
        value = json_getStr(pNode : '[0]');   // The first element

        JSON_Close(pJSON);
        *inlr = *on;
