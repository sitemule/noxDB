
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //This sample shows the use of the buildin JSON parser in IceBreak

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S p1           Pointer;
        Dcl-S p2           Pointer;
        Dcl-S pJson        Pointer;
        Dcl-S pNode        Pointer;
        Dcl-S pO           Pointer;
        Dcl-S pR           Pointer;
        Dcl-S pRcv         Pointer;
        Dcl-S pArr         Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S tag          Varchar(50);
        Dcl-S value        Varchar(50);
        Dcl-S n            Packed(15:2);

        //------------------------------------------------------------- *

        *inlr = *on;

        p1  = Nox_ParseString ('  -
            {  a: 1,               -
               b: 2                -
            }                      -
        ');
        p2  = Nox_ParseString ('  -
            {  c: 3,               -
               d: 4                -
            }                      -
        ');

        Nox_mergeObjects (p1 : p2) ;
        Nox_WriteStmf  (p1   : '/samples/json/json-merge1.json' : 1208 : *ON );
        Nox_Close(p1   );
        Nox_Close(p2   );


        // Yet more advanced
        pJson = Nox_ParseString (
           '{  u:"This is a unicode \u00b5 string"  ,   '+
           '   "s":"abc"                            ,   '+
           '   a:[1,2,3],                   ' +
           '   o:{           ' +
           '     n:123   , ' +
           '     a:[10 , 20 , 30 ],                ' +
           '     b:[10 , 20 , 30 ],                ' +
           '     c:[[1,2],[3,4]],                ' +
           '     m:"yyyy", ' +
           '     o2:{           ' +
           '      x:345   , ' +
           '      y:345     ' +
           '     }         '+
           '   }         '+
           '}'
             : '');
        if Nox_Error(pJson) ;
           msg = Nox_Message(pJson);
           Nox_dump(pJson);
           Nox_Close(pJson);
           return;
        endif;
        pRcv  = Nox_ParseString (
           '{  r: {                                     '+
           '     o: {                                     '+
           '       n:"Do not overwrite me"    ' +
           '     }' +
           '   }' +
           '}'
             : '');
        if Nox_Error(pRcv ) ;
           msg = Nox_Message(pRcv );
           Nox_dump(pRcv );
           Nox_Close(pRcv );
           return;
        endif;

        pO    = Nox_locate(pJson: '/o');
        pR    = Nox_locate(pRcv : '/r');
        Nox_merge (pR : pO : Nox_DONTREPLACE);
        Nox_dump(pRcv );
        Nox_WriteStmf  (pR   : '/samples/json/jsonout.json' : 1208 : *OFF);
        Nox_Close(pJson);
        Nox_Close(pRcv );
