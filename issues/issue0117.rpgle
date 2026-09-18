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

    issue117a();
    issue117b();

end-proc;
// -------------------------------------------------------------
// Test: JSON_DONTREPLACE
// -------------------------------------------------------------
dcl-proc issue117a;

    Dcl-S  pDest       Pointer;
    Dcl-S  pSource     Pointer;


    pDest = json_newObject();
    json_setStr( pDest : 'a' : 'text1');
    json_setStr( pDest : 'b' : 'text2');

    pSource = json_newObject();
    json_setStr( pSource : 'b' : 'text3');
    json_setStr( pSource : 'c' : 'text4');

    // This is invalid but now supported
    json_MergeObjects (
        pDest :
        pSource:
        JSON_DONTREPLACE
    );

    // dump results
    json_WriteJsonStmf(pDest  :'/prj/noxdb/testout/issue117a-dest.json':1208:*OFF);
    json_WriteJsonStmf(pSource:'/prj/noxdb/testout/issue117a-source.json':1208:*OFF);


on-exit;
    // Cleanup: dispose the nodes
    json_delete(pDest);
    json_delete(pSource);

end-proc;

// -------------------------------------------------------------
// Test: JSON_REPLACE
// -------------------------------------------------------------
dcl-proc issue117b;

    Dcl-S  pDest       Pointer;
    Dcl-S  pSource     Pointer;


    pDest = json_newObject();
    json_setStr( pDest : 'a' : 'text1');
    json_setStr( pDest : 'b' : 'text2');

    pSource = json_newObject();
    json_setStr( pSource : 'b' : 'text3');
    json_setStr( pSource : 'c' : 'text4');

    // This is invalid but now supported
    json_MergeObjects (
        pDest :
        pSource:
        JSON_REPLACE
    );

    // dump results
    json_WriteJsonStmf(pDest  :'/prj/noxdb/testout/issue117b-dest.json':1208:*OFF);
    json_WriteJsonStmf(pSource:'/prj/noxdb/testout/issue117b-source.json':1208:*OFF);


on-exit;
    // Cleanup: dispose the nodes
    json_delete(pDest);
    json_delete(pSource);

end-proc;
