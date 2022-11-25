
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pResult      Pointer;
        Dcl-S pSelected    Pointer;
        Dcl-S sql          Varchar(512);
        Dcl-S start        Int(10);
        Dcl-S limit        Int(10);

        //------------------------------------------------------------- *

        // return a object with all rows
        sql   = 'Select * from product';
        start = 1;
        limit = 10; // Give me the 10 first rows

        // The JSON_META constructs a resultset object with a "row" array
        // Total rows convert ( if possible ) the select to an select count(*) first
        pResult = json_sqlResultSet(sql:start:limit:
           JSON_META + JSON_TOTALROWS
        );

        // Produce an other result set - like a selected dropdownbox
        sql   = 'Select * from product where prodkey  = 160';
        pSelected = json_sqlResultRow(sql);
        json_MoveObjectInto (pResult : 'selected' : pSelected);

        // Produce a JSON stream file in the root of the IFS
        json_writeJsonStmf(pResult:
           '/jsonxml/json/resultset-total-rows-one-selected.json' : 1208 : *ON
        );

        // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
        json_close(pResult);
        json_sqlDisconnect();

        // That's it..
        *inlr = *on;
