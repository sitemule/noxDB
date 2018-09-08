        
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE');

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S root         Pointer;
        Dcl-S a            Pointer;
        Dcl-S b            Pointer;
        Dcl-S c            Pointer;

        //------------------------------------------------------------- *

        *inlr = *on;

        // My root json
        root = json_newObject();

        a   = json_newObject();
        json_SetValue  (a  : 'a'  : 'a has a value');

        b   = json_newObject();
        json_SetValue  (b  : 'b'  : 'b has a value');

        c   = json_newObject();
        json_SetValue  (c  : 'c'  : 'c has a value');

        json_MoveObjectInto(root : 'e1' : a);
        json_MoveObjectInto(root : 'e2' : b);
        json_MoveObjectInto(root : 'e3' : c);

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
        Json_WriteStmf (root  :
           './abc-object1.json':1208:*OFF
        );


        // Always close  - p1 contains everything after the move
        json_Close(root );

