
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pj1          Pointer;
        Dcl-S pj2          Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S tag          Varchar(50);
        Dcl-S value        Varchar(50);

        //------------------------------------------------------------- *
        
        pj1   = NOX_ParseString (' +
            { items: [{name:"john", height:22}]} +
           ');

        if NOX_Error(pj1  ) ;
           msg = NOX_Message(pj1  );
           NOX_dump(pj1  );
           NOX_Close(pj1  );
           return;
        endif;

        pj2   = NOX_ParseFile (
             '/www/systest/simpleform.json'
             : '');

        if NOX_Error(pj2  ) ;
           msg = NOX_Message(pj2  );
           NOX_dump(pj2  );
           NOX_Close(pj1  );
           NOX_Close(pj2  );
           return;
        endif;

        // NOX_dump(pj2  );
        NOX_CloneFormat(pj1: pj2 );
        nox_WriteStmf  (pj1: './jsonout.json' : 1208 : *OFF);
        NOX_Close(pj1  );
        NOX_Close(pj2  );
        *inlr = *on;
