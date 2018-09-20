        // ------------------------------------------------------------- *
        // noxDB - Not only XML. JSON, SQL and XML made easy fro RPG
        //
        // Company . . . : System & Method A/S - Sitemule
        // Design  . . . : Niels Liisberg
        //
        // Produce a CSV files directly from a SQL select
        //
        // ------------------------------------------------------------- *
        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');

        /include 'headers/JSONPARSER.rpgle'

        dcl-s rows  pointer;
        dcl-s sql   varchar(4096);

        // Use a simple select
        sql = ('-
            select * from product -
        ');

        // Load all rows
        rows = json_sqlResultSet(sql)    ;

        // Save it as CSV files
        json_WriteCsvStmf (rows : '/tmp/sample.csv' : 1208: *OFF :
        '{ decPoint:",",  delimiter:";", headers:true}'
        );

        // Cleanup: Dispose the row array
        json_delete(rows);

        // That's it..
        *inlr = *on;



