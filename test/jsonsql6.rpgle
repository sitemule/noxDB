
        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE' );
        
        /include 'headers/JSONPARSER.rpgle'
        
        Dcl-S pJson        Pointer;
        Dcl-S sql          Varchar(512);
        Dcl-S start        Int(10);
        Dcl-S limit        Int(10);

        //------------------------------------------------------------- *
        
        Dcl-Pi JSONSQL6;
          pResult Char(50);
        End-Pi;
        
        //First 5 rows
        start = 1;
        limit = 5;

        // JSON_META constructs a resultset object with a "row" array
        // JSON_TOTALROWS converts ( if possible ) the select to an select count(*) first
        sql   = (
           'Select PRODKEY from product ' +
           'where PRODID like ''Coolpix%'' '
        );

        pJson = json_sqlResultSet(sql:start:limit);

        pResult = json_asJsonText(pJson);

        // Cleanup: delete the object and disconnect
        json_delete (pJson);
        json_sqlDisconnect();

        // That's it..
        *inlr = *on;
        
        Return;