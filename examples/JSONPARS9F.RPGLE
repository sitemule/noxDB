
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pList        Pointer;
        Dcl-S pB           Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S res          Varchar(1024);
        Dcl-S name         Varchar(10);
        Dcl-S value        Varchar(40);
        Dcl-DS list  likeds(json_iterator);
        End-DS;

        //------------------------------------------------------------- *

        // Move elemet "b" out into a new object
        pList = json_ParseString('[{a:1}, {b:2}, {c:3 }]');

        if json_Error(pList) ;
           msg = json_Message(pList);
           json_dump(pList);
           json_Close(pList);
           return;
        endif;

        list = json_setIterator(pList);
        dow json_ForEach(list);
           name = json_GetName(json_locate(list.this:'[0]'));
           if  name  = 'b';
              pB = json_newObject();
              json_MoveObjectInto (pb : 'AsNewB' : list.this);
           endif;
        enddo;

        // res - without "b"
        res  = json_asJsonText(pList);

        // res - with then new "b"
        res  = json_asJsonText(pB   );

        json_Close(pList);
        *inlr = *on;
