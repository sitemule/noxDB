**free
// -------------------------------------------------------------
// issue:
// nested reslutset does not have right ccsid for SQL statement
// -------------------------------------------------------------
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') main(main);
/include qrpgleRef,noxdb

dcl-proc main;

    // Here i force the CCSID of constants to be 500
    // causing the error:
    json_setDelimitersByCcsid(500);

    issue116();

end-proc;
// -------------------------------------------------------------
dcl-proc issue116;

    Dcl-S  pRows      Pointer;

    // return an simple array with rows
    pRows = json_sqlResultSet(
        'Select * from noxdbdemo.unicode':
        1:
        JSON_ALLROWS:
        JSON_AUTOPARSE
    );


    json_WriteJsonStmf(pRows:'/prj/noxdb/testout/issue116.json':1208:*OFF);


on-exit;
    // Cleanup: dispose the rows in the array
    json_delete(pRows);

end-proc;
