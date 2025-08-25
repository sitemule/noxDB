**free
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
/include NOXDB/QRPGLEREF,JSONXML

    dcl-s err   ind;
    dcl-s json  pointer;
    dcl-s json2 pointer;

    err = jx_sqlExec('-
        create or replace table noxdb.mddrepj ( -
            recid integer generated always as identity ( -
                start with 1 increment by 1 -
                no minvalue no maxvalue -
                cycle no order -
                cache 20), -
            rectist timestamp not null with default current_timestamp, -
            jsonstr clob(5m) not null with default ccsid 1208, -
            primary key (recid)-
        ) rcdfmt rddrepj'
    );
    if err;
        jx_joblog(jx_message());
        jx_sqlDisconnect();
        return;
    EndIf;

    // Build a object in the graph:
    json = jx_newObject ();
    jx_setInt       (json: 'JSONSTR.id'         : 12345);
    jx_setStr       (json: 'JSONSTR.name'       : 'md001');
    jx_setStr       (json: 'JSONSTR.type'       : 'rule');
    jx_setBool      (json: 'JSONSTR.enabled'    : 200 > 100); // demo logic expression
    jx_setStr       (json: 'JSONSTR.description': 'Test rule 001');
    jx_setTimeStamp (json: 'JSONSTR.ts'         : %timestamp());


    err = jx_sqlInsert(
        'noxdb.mddrepj':
        json
    );

    if err;
        jx_joblog(jx_message());
        jx_sqlDisconnect();
        return;
    EndIf;

    // Row read it:
    json2 = jx_sqlResultRow  ('-
        Select * -
        from noxdb.mddrepj -
        where recid = (select max(recid) from noxdb.mddrepj)'
    );


    jx_WriteJsonStmf (json2: '/prj/noxdb/testout/mdout.json' : 1208: *OFF);

    jx_delete(json);
    jx_delete(json2);
    jx_sqlDisconnect();

    *inlr = *on;
