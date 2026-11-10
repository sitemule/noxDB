**FREE
// Issue 153: nox_sqlOpen appended "with ur" (and "limit") to every statement:
//            an UPDATE sent through nox_sqlResultSet then runs under commitment
//            control and stays uncommitted (on a table that is not journaled -
//            here in QTEMP - it fails with SQL7008), and "... for update" got
//            "limit 1" behind it (SQL0199)
ctl-opt main( main )
             option(*srcstmt : *nodebugio: *showcpy : *expdds: *nounref)
             extbinint(*yes)
             decedit(',')
             bnddir( 'NOXDBUTF8/NOXDBUTF8' )
             ccsid(*char:*jobrun);

/include noxdbutf8/qrpgleref,noxdbutf8

// Note: no [ ] in paths or literals here - this source compiles in any job CCSID


dcl-proc main;

    dcl-s MemStart int(20);
    dcl-s MemNow   int(20);
    dcl-s pCon     pointer;
    dcl-s pRes     pointer;

    nox_Assert ('Start issue0153') ;
    MemStart = nox_memUse();
    pCon = nox_sqlConnect();

    nox_sqlExec(pCon : 'declare global temporary table session.issue153 (n int) with replace');
    nox_sqlExec(pCon : 'insert into session.issue153 values(1)');

    // An UPDATE through a result set function: runs as written, gives no rows - no error
    pRes = nox_sqlResultSet(pCon : 'update session.issue153 set n = 2' : *null : NOX_GRACEFUL_ERROR);
    nox_Assert ('update: no error object' : nox_GetStr(pRes : 'success' : '-') = '-');
    nox_Assert ('update: sqlcode 0'       : nox_sqlCode(pCon) = 0);
    nox_delete(pRes);

    pRes = nox_sqlResultRow(pCon : 'select n from session.issue153');
    nox_Assert ('update: done'            : nox_GetInt(pRes : 'n' : -1) = 2);
    nox_delete(pRes);

    // Trailing clauses stay last: limit / offset go before them
    pRes = nox_sqlResultRow(pCon : 'select n from session.issue153 for update' : *null : NOX_GRACEFUL_ERROR);
    nox_Assert ('for update: row'         : nox_GetInt(pRes : 'n' : -1) = 2);
    nox_delete(pRes);

    pRes = nox_sqlResultSet(pCon : 'select c from (values 1,2,3) t(c) optimize for 1 row'
                                 : *null : NOX_GRACEFUL_ERROR : 2 : 1);
    nox_Assert ('optimize for: offset+limit' : nox_GetLength(pRes) = 1
                                               and nox_GetInt(nox_GetChild(pRes) : 'c' : -1) = 2);
    nox_delete(pRes);

    pRes = nox_sqlResultSet(pCon : 'select c from (values 1,2,3) t(c) with cs'
                                 : *null : NOX_GRACEFUL_ERROR : 1 : 2);
    nox_Assert ('with cs: limit'          : nox_GetLength(pRes) = 2);
    nox_delete(pRes);

    return;

on-exit;

    nox_sqlExec(pCon : 'drop table session.issue153');
    nox_sqlDisconnect(pCon);
    MemNow  = nox_memUse();
    nox_Assert ( 'Mem leak' : MemNow = MemStart);

    nox_Assert ('End issue0153') ;

end-proc;
