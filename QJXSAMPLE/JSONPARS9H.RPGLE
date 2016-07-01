      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin JSONparser in
      * IceBreak
      *
      * ------------------------------------------------------------- *
     H BndDir('XMLPARSER') dftactgrp(*NO) ACTGRP('QILE')
     D pList           s               *
     D msg             s             50    varying
     D value           s             40    varying
     D list            ds                  likeds(json_iterator)
      /include jsonParser
      /free

        // List elements:
        pList = json_ParseString('["a","b","c"]');

        // Using an iterator
        list = json_setIterator(pList);
        dow json_ForEach(list);
           value = json_GetStr (list.this );
        enddo;

        json_Close(pList);
        *inlr = *on;
