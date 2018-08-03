      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin JSONparser in
      * IceBreak
      *
      * ------------------------------------------------------------- *
     H BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE')
     D pList           s               *
     D pB              s               *
     D msg             s             50    varying
     D res             s           1024    varying
     D name            s             10    varying
     D value           s             40    varying
     D list            ds                  likeds(json_iterator)
      /include 'headers/JSONPARSER.rpgle'
      /free
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
