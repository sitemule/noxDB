
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S v            Varchar(50);
        Dcl-S i            Int(10);
        Dcl-S maxid        Int(10);
        Dcl-S id           Int(10);
        Dcl-S index        Pointer    dim(100);
        Dcl-DS list  likeds(json_iterator);
        End-DS;

        //------------------------------------------------------------- *
        
        pJson = JSON_ParseFile (
            '/www/portfolio/Public/TwiSite/xpd/folder.xpd'
        );

        if JSON_Error(pJson) ;
           msg = JSON_Message(pJson);
           JSON_dump(pJson);
           JSON_Close(pJson);
           return;
        endif;

        list = json_setRecursiveIterator(pJson);
        dow json_ForEach(list);
           if ('id' = json_getName (list.this));
              id = json_getNum     (list.this);
              index(id) = json_getParent(list.this);
              if maxid < id;
                 maxid = id;
              endif;
           endif;
        enddo;

        // Lets play with it:
        for i = 1 to maxid;
          v = json_getStr    (index(i):'title');
          dsply v;
        endfor;

        JSON_Close(pJSON);
        *inlr = *on;
