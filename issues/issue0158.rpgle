**FREE
// Issue 158: call programs and service program procedures with JSON
//            ( nox_CallProgram / nox_CallProcedure )
//
// Samples - each one also checks its result with nox_Assert:
//   1. A payload built from SQL rows: columns map to fields by name
//   2. The same program with a JSON string
//   3. A service program procedure
//   4. A top level array with its _LENGTH parameter
//   5. The interface as JSON
//   6. Errors: *null and nox_Message() - no exception
//
// Build ( the RPG in this repo is compiled in CCSID 500 ):
//   gmake issues/issue0158p.rpgle issues/issue0158s.rpgle issues/issue0158.rpgle --always-make
//   CRTSRVPGM SRVPGM(<lib>/ISSUE0158S) MODULE(<lib>/ISSUE0158S) EXPORT(*ALL)
// Run in CCSID 500, with <lib> in the library list:
//   CALL RUNTEST PARM('ISSUE0158')   ( test/runtest.clle - job log in /tmp/ISSUE0158.joblog.csv )
//   "Start" and "End" only is a pass.
ctl-opt main(main)
        option(*srcstmt : *nodebugio : *nounref)
        dftactgrp(*no) actgrp(*new)
        bnddir('NOXDBUTF8')
        ccsid(*char:*jobrun);

/include qrpgleref,noxdbutf8

dcl-proc main;

    dcl-s pCon     pointer;
    dcl-s pRows    pointer;
    dcl-s pParms   pointer;
    dcl-s pResult  pointer;
    dcl-s pMeta    pointer;
    dcl-s pSrv     pointer;

    nox_Assert('Start issue0158');

    // 1. A payload built from SQL rows ----------------------------------------------
    // The program has one data structure parameter, "payroll". The payload has no
    // element by that name, so the whole payload is mapped onto it: "percent" and the
    // array "employees" - whose rows come straight from SQL.
    pCon  = nox_sqlConnect();
    pRows = nox_sqlResultSet(pCon :
        'select name, salary from (values ' +
        '(''Åse Ærø'', 40000.00), (''Søren Blåbær'', 42000.00), (''Niels'', 39000.00)) ' +
        't(name, salary) order by salary');
    nox_Assert('rows from SQL' : nox_GetLength(pRows) = 3);

    // nox_Object takes the rows over: they are deleted with pParms
    pParms = nox_Object('percent' : nox_Dec(3.5) : 'employees' : pRows);
    pResult = nox_CallProgram('*LIBL' : 'ISSUE0158P' : pParms);
    nox_delete(pParms);

    // {"PAYROLL":{"PERCENT":3.50,"EMPLOYEES":[{"NAME":"Niels","SALARY":39000.00,
    //  "NEWSALARY":40365.00}, ... 3 ],"TOTAL":125235.00,"RAISEDAT":"..."}}
    nox_Assert('program result' : pResult <> *null);
    nox_WriteJsonStmf(pResult : '/tmp/issue0158-payroll.json' : 1208 : *off);
    nox_Assert('_LENGTH filled from the payload, 3 returned' :
        nox_GetLength(nox_Locate(pResult : 'payroll/employees')) = 3);
    nox_Assert('_LENGTH field not returned' :
        not nox_Has(pResult : 'payroll/employees_LENGTH'));
    nox_Assert('national characters both ways' :
        nox_GetStr(pResult : 'payroll/employees[0]/name') = 'Niels' and
        nox_GetStr(pResult : 'payroll/employees[1]/name') = 'Åse Ærø');
    nox_Assert('array of structures computed' :
        nox_GetDec(pResult : 'payroll/employees[0]/newSalary') = 40365.00);
    nox_Assert('total' : nox_GetDec(pResult : 'payroll/total') = 125235.00);
    nox_Assert('timestamp' : nox_GetStr(pResult : 'payroll/raisedAt') <> '');
    nox_delete(pResult);
    nox_sqlDisconnect(pCon);

    // 2. The same program with a JSON string ( in the job CCSID ) -------------------
    pResult = nox_CallProgram('*LIBL' : 'ISSUE0158P' :
        '{"percent":10,"employees":[{"name":"Ærø Is","salary":1000}]}');
    nox_Assert('JSON string payload' :
        nox_GetDec(pResult : 'payroll/employees[0]/newSalary') = 1100.00 and
        nox_GetLength(nox_Locate(pResult : 'payroll/employees')) = 1);
    nox_delete(pResult);

    // 3. A service program procedure ------------------------------------------------
    pResult = nox_CallProcedure('*LIBL' : 'ISSUE0158S' : 'CONVERT' :
        '{"amount":100,"fromCur":"EUR","toCur":"DKK"}');
    nox_WriteJsonStmf(pResult : '/tmp/issue0158-convert.json' : 1208 : *off);
    nox_Assert('procedure result' : nox_GetDec(pResult : 'result') = 746.00);
    nox_Assert('only inputoutput returned' :
        not nox_Has(pResult : 'amount') and nox_Has(pResult : 'rate'));
    nox_delete(pResult);

    // 4. A top level array with its _LENGTH parameter -------------------------------
    pResult = nox_CallProcedure('*LIBL' : 'ISSUE0158S' : 'SPLIT' :
        '{"text":"Hej fra Ærø og Æbeltoft"}');
    nox_WriteJsonStmf(pResult : '/tmp/issue0158-split.json' : 1208 : *off);
    nox_Assert('top level array cut at _LENGTH' :
        nox_GetLength(nox_Locate(pResult : 'words')) = 5);
    nox_Assert('top level array values' :
        nox_GetStr(pResult : 'words[2]') = 'Ærø' and
        nox_GetStr(pResult : 'words[4]') = 'Æbeltoft');
    nox_delete(pResult);

    // 5. The interface as JSON - e.g. to describe a service -------------------------
    // { "<library>": { "service": { "ISSUE0158S": { "CONVERT": { "parms": [...] }, "SPLIT": ... } } } }
    pMeta = nox_ApplicationMeta('*LIBL' : 'ISSUE0158S' : '*ALL');
    nox_WriteJsonStmf(pMeta : '/tmp/issue0158-meta.json' : 1208 : *off);
    pSrv = nox_GetChild(nox_GetChild(nox_GetChild(pMeta)));
    nox_Assert('meta has both procedures' :
        nox_Has(pSrv : 'CONVERT') and nox_Has(pSrv : 'SPLIT'));
    nox_delete(pMeta);

    // 6. Errors: *null and the reason in nox_Message() -------------------------------
    pResult = nox_CallProgram('*LIBL' : 'NOSUCH0158' : '{}');
    nox_Assert('missing program gives *null' : pResult = *null);
    nox_Assert('and a message' : nox_Message() <> '');
    pResult = nox_CallProcedure('*LIBL' : 'ISSUE0158S' : 'NOSUCHPROC' : '{}');
    nox_Assert('missing procedure gives *null' : pResult = *null);

    nox_Assert('no memory leak' : not nox_MemLeak());
    nox_Assert('End issue0158');
end-proc;
