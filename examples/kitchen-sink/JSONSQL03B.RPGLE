        // ------------------------------------------------------------- *
        // noxDB - Not only XML. JSON, SQL and XML made easy fro RPG
        //
        // Company . . . : System & Method A/S - Sitemule
        // Design  . . . : Niels Liisberg
        //
        // Produce a CSV files directly from a SQL select
        //
        // ------------------------------------------------------------- *
        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE');

        /include 'headers/JSONPARSER.rpgle'

        dcl-s rows  pointer;
        dcl-s sql   varchar(4096);

        // Use a simple select
        sql = ('-
            select * from product -
        ');

        // Load all rows
        rows = nox_sqlResultSet(sql)    ;

        // Save it as CSV files
        nox_WriteCsvStmf (rows : '/tmp/sample.csv' : 1208: *OFF :
        '{ decPoint:",",  delimiter:";", headers:true}'
        );

        // Cleanup: Dispose the row array
        nox_delete(rows);

        // That's it..
        *inlr = *on;



