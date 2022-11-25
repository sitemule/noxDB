
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pj1          Pointer;
        Dcl-S pj2          Pointer;
        Dcl-S msg          Varchar(50);
        Dcl-S tag          Varchar(50);
        Dcl-S value        Varchar(50);

        //------------------------------------------------------------- *
        
        pj1   = JSON_ParseString (' +
            { items: [{name:"john", height:22}]} +
           ');

        if JSON_Error(pj1  ) ;
           msg = JSON_Message(pj1  );
           JSON_dump(pj1  );
           JSON_Close(pj1  );
           return;
        endif;

        pj2   = JSON_ParseFile (
             '/www/systest/simpleform.json'
             : '');

        if JSON_Error(pj2  ) ;
           msg = JSON_Message(pj2  );
           JSON_dump(pj2  );
           JSON_Close(pj1  );
           JSON_Close(pj2  );
           return;
        endif;

        // JSON_dump(pj2  );
        JSON_CloneFormat(pj1: pj2 );
        json_WriteStmf  (pj1: './jsonout.json' : 1208 : *OFF);
        JSON_Close(pj1  );
        JSON_Close(pj2  );
        *inlr = *on;
