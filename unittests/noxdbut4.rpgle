**FREE

///
// noxDB : procedure and function unit tests
//
// This test suite tests the internal noxDB procedures and functions.
//
//
// @author Jens Melgard Churchill
// @date 2025-05-16
// @project noxDB
///

Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') ;

// /include assert
/include qrpgleRef,noxdb

// Set your delimiter according to your CCSID of your source file if you parse any strings.
// Note the "makefile" is set to international - ccsid 500 for all source files in the examples
json_setDelimitersByCcsid(500);

// Run tests...
test_a(run_test('HELOSRVPGM' : 'NAMEAGE': '{-
"name":"John",-
"age":41}'));

test_a(run_test('HELOSRVPGM' : 'ALLTYPES': '{-
"char":"xyz",-
"varchar":"Test",-
"int8":-456789012345,-
"int4":-56789,-
"uns8":456789012345,-
"uns4":56789,-
"uns2":255,-
"packed":-987.65,-
"zoned":-8765.43,-
"ind":"0",-
"date":"2025-05-06",-
"time":"17.42.39",-
"timestamp":"2025-05-06-17.42.39.85600}'));

// That's it..
*inlr = *on;

dcl-proc test_a;
    dcl-pi *N;
        pResult Pointer const;
    end-pi;

    // Dump the result
    json_joblog(pResult);

    json_delete(pResult);
end-proc;


// ------------------------------------------------------------------------------------
// Call Procedure By String
// ------------------------------------------------------------------------------------
dcl-proc run_test;
    dcl-pi *N Pointer;
        pPgm       varchar(10) const;
        pFn        varchar(128) const;
        pIn        varchar(32000) const;
    end-pi;

    Dcl-S pOut       Pointer;
    Dcl-s msg        char(50);

    pOut  = json_CallProcedure ('*LIBL': pPgm: pFn: pIn: JSON_GRACEFUL_ERROR);

    return pOut;
end-proc;
