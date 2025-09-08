
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
      
        pJson = NOX_ParseString (
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
        if NOX_Error(pJson) ;
           msg = NOX_Message(pJson);
           NOX_dump(pJson);
           NOX_Close(pJson);
           return;
        endif;

        pNode = NOX_locate(pJson: '/o/n');
        n     = nox_getNum(pNode);

        pNode = NOX_locate(pJson: '/a[1]');
        n     = nox_getNum(pNode);

        pNode = NOX_locate(pJson: '/s');
        value = NOX_getValue(pNode);

        pNode = NOX_locate(pJson: '/u');
        value = NOX_getValue(pNode);

        pNode = NOX_locate(pJson: '/o/a[2]');
        n     = nox_getNum(pNode);

        // Loop on the array
        pArr  = NOX_locate(pJson: '/o/a[0]'); // First array element
        dow (pArr <> *NULL) ;
          n     = nox_getNum(pArr);
          pArr  = NOX_getNext(pArr);
        endDo;

        // Get Value directly
        value = nox_getStr(pJson : '/u');

        // Get Value directly relative
        pNode = NOX_locate(pJson: '/o');
        value = nox_getStr(pNode : 'n');   // This is "n" in "o"

        pNode = NOX_locate(pJson: '/a');
        value = nox_getStr(pNode : '[0]');   // The first element

        NOX_Close(pJSON);
        *inlr = *on;
