
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S v            Varchar(50);
        Dcl-S i            Int(10);
        Dcl-S maxid        Int(10);
        Dcl-S id           Int(10);
        Dcl-S index        Pointer    dim(100);
        Dcl-DS list  likeds(nox_iterator);
        End-DS;

        //------------------------------------------------------------- *
        
        pJson = NOX_ParseFile (
            '/www/portfolio/Public/TwiSite/xpd/folder.xpd'
        );

        if NOX_Error(pJson) ;
           msg = NOX_Message(pJson);
           NOX_dump(pJson);
           NOX_Close(pJson);
           return;
        endif;

        list = nox_setRecursiveIterator(pJson);
        dow nox_ForEach(list);
           if ('id' = nox_getName (list.this));
              id = nox_getNum     (list.this);
              index(id) = nox_getParent(list.this);
              if maxid < id;
                 maxid = id;
              endif;
           endif;
        enddo;

        // Lets play with it:
        for i = 1 to maxid;
          v = nox_getStr    (index(i):'title');
          dsply v;
        endfor;

        NOX_Close(pJSON);
        *inlr = *on;
