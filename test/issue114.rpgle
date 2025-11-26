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

    issue114();

end-proc;
// -------------------------------------------------------------
dcl-proc issue114;

    Dcl-S  pRows      Pointer;

    // return an simple array with rows
    pRows = json_sqlResultSet(
        'Select * from noxdbdemo.unicode'
    );
    json_WriteJsonStmf(pRows:'/prj/noxdb/testout/issue114.json':1208:*OFF);


on-exit;
    // Cleanup: dispose the rows in the array
    json_delete(pRows);

end-proc;
