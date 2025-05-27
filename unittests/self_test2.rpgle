**FREE

///
// noxDB : procedure and function unit tests
//
// This test suite tests noxDB itself, using noxDB.
//
//
// @author Jens Melgard Churchill
// @date 2025-05-23
// @project noxDB

// compile:
// chgcurlib noxdb
// cd '/prj/noxdb'
// CRTBNDRPG PGM(SELF_TEST2) SRCSTMF('unittests/self_test2.rpgle')  DBGVIEW(*ALL)
///

Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') main(main);

// /include assert
/include qrpgleRef,noxdb

// ------------------------------------------------------------------------------------
// Simple main test
// ------------------------------------------------------------------------------------
dcl-proc main;

    dcl-s pTest pointer;

    // Set your delimiter according to your CCSID of your source file if you parse any strings.
    // Note the "makefile" is set to international - ccsid 500 for all source files in the examples
    json_setDelimitersByCcsid(500);

    // Setup trace/debugging ( or perhaps unit testing) for
    // your code if you like - this is optional
    // myTrace is defined in the bottom in the example
    // Note - you can disable the trace by setting it to *NULL
    json_SetTraceProc (%paddr(myTrace));


    pTest = json_newObject();

    json_setStr(pTest: 'name': 'John');
    assert(json_getStr(pTest: 'name') = 'John':'test for John');

    json_setStr(pTest: 'name': 'ÆØÅæøå');
    assert(json_getStr(pTest: 'name') = 'ÆØÅæøå':'test for ÆØÅæøå');

    json_setInt(pTest: 'age': 41);
    assert(json_getInt(pTest: 'age') = 41:'test for 41');

on-exit;
    json_delete(pTest);
end-proc;

// ------------------------------------------------------------------------------------
// Call Procedure By String
// ------------------------------------------------------------------------------------
dcl-proc assert ;
    dcl-pi *N ind;
        ok ind value;
        text   varchar(4096) const options(*varsize);
    end-pi;

    if ok;
        json_joblog ('Passed: ' + text);
        return *off;
    else;
        json_joblog ('Error: ' + text);
        return *on;
    endif;


end-proc;

// ------------------------------------------------------------------------------------
// myTrace - an example of a trace procedure for debugging and unit test
// This will be called each time you interact with the objec graph - if set by
// json_SetTraceProc ( %paddr(myTrace));
// ------------------------------------------------------------------------------------
dcl-proc myTrace;

    dcl-pi myTrace ;
        text  char(30) const;
        pNode pointer value;
    end-pi;

    dcl-s action char(30);
    dcl-s showme varchar(32000);

    // I could put it into the joblog
    json_joblog(Text);
    json_joblog(pNode);

    // Or I could just have it in variables that i debug
    action = text;
    showme = json_AsJsonText(pNode);

    // Or maybe put it into a stream file
    //json_WriteJsonStmf(pJson:'/prj/noxdb/testout/trace.json':1208:*OFF);

    // Or place it into a trace table.. Up to you !!

end-proc;