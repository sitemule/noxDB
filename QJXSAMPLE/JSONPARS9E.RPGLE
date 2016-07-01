      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin JSONparser in
      * IceBreak
      *
      * ------------------------------------------------------------- *
     H BndDir('XMLPARSER') dftactgrp(*NO) ACTGRP('QILE')
     D pJson           s               *
     D msg             s             50    varying
     D name            s             10    varying
     D value           s             40    varying
     D list            ds                  likeds(json_iterator)
      /include jsonParser
      /free
        pJson = json_ParseString('{ a: 1, b : { c: 2 ,d : 3}}');

        if json_Error(pJson) ;
           msg = json_Message(pJson);
           json_dump(pJson);
           json_Close(pJson);
           return;
        endif;

        list = json_setRecursiveIterator(pJson);
        dow json_ForEach(list);
           name  = json_GetNameAsPath(list.this:'.');
           value = json_GetValue (list.this);
           dsply (name + value);
        enddo;

        json_Close(pJSON);
        *inlr = *on;
