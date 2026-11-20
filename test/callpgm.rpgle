**FREE
// nox_CallProgram / nox_CallProcedure: call a program and a service program
// procedure by their PCML, with every parameter type both ways and national
// characters in and out ( the graph is UTF-8, the parameters in the job CCSID ).
//
// Runs every check twice: against PCML 6.0 targets (pgminfo(*PCML:*MODULE),
// what RPG writes by default on 7.3) and PCML 7.0 ones (pgminfo(*PCML:*MODULE:*V7)).
// The two differ in varchar: 6.0 has a <struct> of length + string (and no
// length at all for an input only one), 7.0 has type="varchar" length="n".
// An indicator is char(1) in both - it comes back as "1" / "0".
//
// Needs the targets in the library list:
//   test/calltgt.rpgle  test/calltgt7.rpgle  (programs CALLTGT / CALLTGT7)
//   test/callsrv.rpgle  test/callsrv7.rpgle  (service programs CALLSRV / CALLSRV7)
//   gmake test/calltgt.rpgle test/calltgt7.rpgle test/callsrv.rpgle test/callsrv7.rpgle test/callpgm.rpgle --always-make
//   CRTSRVPGM SRVPGM(<lib>/CALLSRV)  MODULE(<lib>/CALLSRV)  EXPORT(*ALL)
//   CRTSRVPGM SRVPGM(<lib>/CALLSRV7) MODULE(<lib>/CALLSRV7) EXPORT(*ALL)
//   CRTBNDCL PGM(<lib>/RUNTEST) SRCSTMF('test/runtest.clle')
//   CALL RUNTEST PARM('CALLPGM')   - runs it in CCSID 500 (as the RPG is compiled)
//   Failed asserts are in /tmp/CALLPGM.joblog.csv; "Start" and "End" only is a pass.
//   The interface as noxDB sees it: /tmp/callpgm-<pgm>-meta.json and /tmp/callpgm-<pgm>-pcml.xml
ctl-opt main(main)
        option(*srcstmt : *nodebugio : *nounref)
        dftactgrp(*no) actgrp(*new)
        bnddir('NOXDBUTF8')
        ccsid(*char:*jobrun);

/include qrpgleref,noxdbutf8

dcl-proc main;
    nox_Assert('Start callpgm');

    testProgram   ('CALLTGT'  : 'PCML 6.0');
    testProgram   ('CALLTGT7' : 'PCML 7.0');
    testProcedures('CALLSRV'  : 'PCML 6.0');
    testProcedures('CALLSRV7' : 'PCML 7.0');

    // --- Errors: no crash, *null and a message -----------------------------
    nox_Assert('missing program gives *null' :
        nox_CallProgram('*LIBL' : 'NOSUCHPGM' : '{}') = *null);
    nox_Assert('missing procedure gives *null' :
        nox_CallProcedure('*LIBL' : 'CALLSRV' : 'NOSUCHPROC' : '{}') = *null);

    nox_Assert('no memory leak' : not nox_MemLeak());
    nox_Assert('End callpgm');
end-proc;

// ------------------------------------------------------------------------------------
dcl-proc check;
    dcl-pi *n;
        version varchar(10) const;
        title   varchar(80) const;
        ok      ind         const;
    end-pi;
    nox_Assert(version + ': ' + title : ok);
end-proc;

// ------------------------------------------------------------------------------------
// A program with every parameter type, the payload as a JSON string in the job CCSID
// ------------------------------------------------------------------------------------
dcl-proc testProgram;
    dcl-pi *n;
        pgm     char(10)    const;
        version varchar(10) const;
    end-pi;

    dcl-s pOut  pointer;
    dcl-s pMeta pointer;
    dcl-s v     varchar(10);

    v = version;

    // The PCML as noxDB sees it - handy when an assert fails
    pMeta = nox_ApplicationMeta('*LIBL' : pgm : *null);
    check(v : 'program meta' : pMeta <> *null);
    nox_WriteJsonStmf(pMeta : '/tmp/callpgm-' + %trim(pgm) + '-meta.json' : 1208 : *off);
    nox_delete(pMeta);
    pMeta = nox_ProgramMeta('*LIBL' : pgm);
    check(v : 'program PCML' : pMeta <> *null);
    nox_WriteXmlStmf(pMeta : '/tmp/callpgm-' + %trim(pgm) + '-pcml.xml' : 1208 : *off);
    nox_delete(pMeta);

    pOut = nox_CallProgram('*LIBL' : pgm :
        '{"name":"Niels","text":"","age":41,"amount":12.25,"count":7,' +
        '"big":1234567890123,"uns":4000000000,"flag":false,' +
        '"birth":"2026-11-20","birthEur":"2026-12-31","at":"10:15:30",' +
        '"stamp":"2026-11-20T10:15:30.123456","vc":"Blåbær",' +
        '"list":["a","b","c"],' +
        '"emp":{"id":1,"name":"Søren","income":1000.50,"tags":["x","y","z"]}}');

    check(v : 'program call returns a graph' : pOut <> *null);
    if pOut = *null;
        nox_joblog(nox_Message(*null));
        return;
    endif;
    nox_joblog(nox_AsJsonText(pOut));

    check(v : 'char out, national characters' :
        nox_GetStr(pOut : 'text') = 'Hello Niels æøå');
    check(v : 'input only parameter not returned' : not nox_Has(pOut : 'name'));
    check(v : 'packed' : nox_GetInt(pOut : 'age') = 42);
    check(v : 'zoned' : nox_GetDec(pOut : 'amount') = 24.50);
    check(v : 'int(10)' : nox_GetInt(pOut : 'count') = 8);
    check(v : 'int(20)' : nox_GetInt(pOut : 'big') = -1234567890123);
    check(v : 'uns(10) beyond int(10)' : nox_GetStr(pOut : 'uns') = '4000000001');
    // RPG writes an indicator as char(1) in both PCML versions
    check(v : 'indicator as char(1)' : nox_GetStr(pOut : 'flag') = '1');
    check(v : 'date *iso' : nox_GetStr(pOut : 'birth') = '2026-11-21');
    check(v : 'date *eur' : nox_GetStr(pOut : 'birthEur') = '2027-01-01');
    check(v : 'time' : nox_GetStr(pOut : 'at') = '11.15.30');
    check(v : 'timestamp from ISO 8601' :
        %subst(nox_GetStr(pOut : 'stamp') : 1 : 19) = '2026-11-20T10:15:31'
     or %subst(nox_GetStr(pOut : 'stamp') : 1 : 19) = '2026-11-20-10.15.31');
    check(v : 'varchar, national characters' : nox_GetStr(pOut : 'vc') = 'Blåbær!');
    check(v : 'array first' : nox_GetStr(pOut : 'list[0]') = 'c');
    check(v : 'array last'  : nox_GetStr(pOut : 'list[2]') = 'a');
    check(v : 'struct int' : nox_GetInt(pOut : 'emp/id') = 2);
    check(v : 'struct char' : nox_GetStr(pOut : 'emp/name') = 'Søren Ø');
    check(v : 'struct packed' : nox_GetDec(pOut : 'emp/income') = 1100.50);
    check(v : 'array in struct' : nox_GetStr(pOut : 'emp/tags[1]') = 'two');
    check(v : 'array in struct kept' : nox_GetStr(pOut : 'emp/tags[2]') = 'z');
    nox_delete(pOut);
end-proc;

// ------------------------------------------------------------------------------------
// Service program procedures, the payload as a graph and as a string
// ------------------------------------------------------------------------------------
dcl-proc testProcedures;
    dcl-pi *n;
        srv     char(10)    const;
        version varchar(10) const;
    end-pi;

    dcl-s pIn   pointer;
    dcl-s pOut  pointer;
    dcl-s pMeta pointer;
    dcl-s v     varchar(10);

    v = version;

    pIn = nox_NewObject();
    nox_SetStr(pIn : 'name' : 'Åse');
    nox_SetInt(pIn : 'times' : 21);
    pOut = nox_CallProcedure('*LIBL' : srv : 'GREET' : pIn);
    check(v : 'procedure call returns a graph' : pOut <> *null);
    if pOut <> *null;
        nox_joblog(nox_AsJsonText(pOut));
        check(v : 'input only varchar, varchar out' :
            nox_GetStr(pOut : 'text') = 'Hej Åse fra Ærø');
        check(v : 'int out' : nox_GetInt(pOut : 'times') = 42);
        nox_delete(pOut);
    endif;
    nox_delete(pIn);

    pOut = nox_CallProcedure('*LIBL' : srv : 'ADDDAYS' :
        '{"start":"2026-12-30","days":3}');
    check(v : 'second procedure' : pOut <> *null and
        nox_GetStr(pOut : 'result') = '2027-01-02');
    nox_delete(pOut);

    pMeta = nox_ApplicationMeta('*LIBL' : srv : '*ALL');
    check(v : 'service program meta' : pMeta <> *null);
    nox_WriteJsonStmf(pMeta : '/tmp/callpgm-' + %trim(srv) + '-meta.json' : 1208 : *off);
    nox_delete(pMeta);
    pMeta = nox_ProcedureMeta('*LIBL' : srv : '*ALL');
    check(v : 'service program PCML' : pMeta <> *null);
    nox_WriteXmlStmf(pMeta : '/tmp/callpgm-' + %trim(srv) + '-pcml.xml' : 1208 : *off);
    nox_delete(pMeta);
end-proc;
