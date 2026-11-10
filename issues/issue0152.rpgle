**FREE
// Issue 152: NOX_GRACEFUL_ERROR must return the error object - also for errors at
//            fetch time and from nox_sqlValues - and the error object carries the
//            job log messages behind the error ("joblog"); nox_sqlErrorObject gives
//            the same object for functions that only return an indicator (nox_sqlExec)
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
    dcl-s text     varchar(32000);   // job CCSID: %scan with literals

    nox_Assert ('Start issue0152') ;
    MemStart = nox_memUse();
    pCon = nox_sqlConnect();

    // Error at fetch time - open works, the row fails (SQL0420)
    pRes = nox_sqlResultSet(pCon : 'select int(c) c from (values ''1'',''x'') t(c)'
                                 : *null : NOX_GRACEFUL_ERROR);
    nox_Assert ('resultSet: error object'  : pRes <> *null and nox_GetStr(pRes : 'success') = 'false');
    text = nox_GetStr(pRes : 'msg');
    nox_Assert ('resultSet: msg is text'   : %scan('CAST' : text) > 0);
    text = nox_AsJsonText(pRes);
    nox_Assert ('resultSet: joblog SQL0420': %scan('SQL0420' : text) > 0);
    nox_delete(pRes);

    pRes = nox_sqlResultRow(pCon : 'select int(c) c from (values ''x'') t(c)'
                                 : *null : NOX_GRACEFUL_ERROR);
    nox_Assert ('resultRow: error object'  : pRes <> *null and nox_GetStr(pRes : 'success') = 'false');
    nox_delete(pRes);

    pRes = nox_sqlValues(pCon : 'int(''x'')' : *null : NOX_GRACEFUL_ERROR);
    nox_Assert ('values: error object'     : pRes <> *null and nox_GetStr(pRes : 'success') = 'false');
    nox_delete(pRes);

    // Error at open time
    pRes = nox_sqlResultRow(pCon : 'select * from nolib_x.notable_x' : *null : NOX_GRACEFUL_ERROR);
    nox_Assert ('open error: error object' : pRes <> *null and nox_GetStr(pRes : 'success') = 'false');
    nox_delete(pRes);

    // Good results stay good: the statement's own fetch first is larger than the limit
    pRes = nox_sqlResultSet(pCon : 'select c from (values 1,2,3,4,5) t(c) fetch first 5 rows only'
                                 : *null : NOX_GRACEFUL_ERROR : 1 : 2);
    nox_Assert ('limit: two rows, no error': nox_GetLength(pRes) = 2
                                             and nox_GetInt(nox_GetNext(nox_GetChild(pRes)) : 'c' : -1) = 2
                                             and nox_GetStr(pRes : 'success' : '-') = '-');
    nox_delete(pRes);

    pRes = nox_sqlValues(pCon : '1+1' : *null : NOX_GRACEFUL_ERROR);
    nox_Assert ('values: 2'                : nox_GetInt(pRes : '' : -1) = 2);
    nox_delete(pRes);

    pRes = nox_sqlResultRow(pCon : 'select c from (values 7) t(c) where c = 0' : *null : NOX_GRACEFUL_ERROR);
    nox_Assert ('no row: null'             : pRes = *null);

    // nox_sqlErrorObject: the same error object after nox_sqlExec, success after a good one
    nox_sqlExec(pCon : 'selec nonsense');
    pRes = nox_sqlErrorObject(pCon);
    nox_Assert ('errorObject: failed'      : nox_GetStr(pRes : 'success') = 'false');
    text = nox_GetStr(pRes : 'stmt');
    nox_Assert ('errorObject: stmt'        : text = 'selec nonsense');
    text = nox_AsJsonText(nox_Locate(pRes : 'joblog'));
    nox_Assert ('errorObject: SQL0104'     : %scan('SQL0104' : text) > 0);
    nox_delete(pRes);

    nox_sqlExec(pCon : 'set path = *libl');
    pRes = nox_sqlErrorObject(pCon);
    nox_Assert ('errorObject: success'     : nox_GetStr(pRes : 'success') = 'true'
                                             and nox_Locate(pRes : 'joblog') = *null);
    nox_delete(pRes);

    return;

on-exit;

    nox_sqlDisconnect(pCon);
    MemNow  = nox_memUse();
    nox_Assert ( 'Mem leak' : MemNow = MemStart);

    nox_Assert ('End issue0152') ;

end-proc;
