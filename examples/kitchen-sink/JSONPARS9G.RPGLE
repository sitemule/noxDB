
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE');

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pList        Pointer;
        Dcl-S pB           Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S res          Varchar(1024);
        Dcl-S name         Varchar(10);
        Dcl-S value        Varchar(40);
        Dcl-DS list  likeds(nox_iterator);
        End-DS;

        //------------------------------------------------------------- *
        
        // Move elemet "b" out into a new object
        // This will not work !!!  it is not objects but values you are moving
        pList = nox_ParseString('{a:1,b:2,c:3}');

        if nox_Error(pList) ;
           msg = nox_Message(pList);
           nox_dump(pList);
           nox_Close(pList);
           return;
        endif;

        list = nox_setIterator(pList);
        dow nox_ForEach(list);
           name = nox_GetName(list.this);
           // name = nox_GetName(nox_locate(list.this:'[0]'));
           if  name  = 'b';
              pB = nox_newObject();
              nox_MoveObjectInto (pb : 'AsNewB' : list.this);
           endif;
        enddo;

        // res - without "b"
        res  = nox_asJsonText(pList);

        // res - with then new "b"
        res  = nox_asJsonText(pB   );

        nox_Close(pList);
        *inlr = *on;
