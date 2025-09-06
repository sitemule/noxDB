        
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE');

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S root         Pointer;
        Dcl-S a            Pointer;
        Dcl-S b            Pointer;
        Dcl-S c            Pointer;

        //------------------------------------------------------------- *

        *inlr = *on;

        // My root json
        root = nox_newObject();

        a   = nox_newObject();
        nox_SetValue  (a  : 'a'  : 'a has a value');

        b   = nox_newObject();
        nox_SetValue  (b  : 'b'  : 'b has a value');

        c   = nox_newObject();
        nox_SetValue  (c  : 'c'  : 'c has a value');

        nox_MoveObjectInto(root : 'e1' : a);
        nox_MoveObjectInto(root : 'e2' : b);
        nox_MoveObjectInto(root : 'e3' : c);

        // result in:
        //  {
        //     e1:{
        //        a : 'a has a value'
        //     }
        //     e2:{
        //        b : 'b has a value'
        //     }
        //     e3:{
        //        b : 'b has a value'
        //     }
        //  }
        //

        // Write it out:
        Nox_WriteStmf (root  :
           './abc-object1.json':1208:*OFF
        );


        // Always close  - p1 contains everything after the move
        nox_Close(root );

