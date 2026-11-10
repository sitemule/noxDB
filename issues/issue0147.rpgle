**FREE
// Issue 147: nox_sqlOpen, nox_sqlExec, nox_sqlValues ... built the statement in a
//            fixed 32 KB stack buffer - a longer statement (or one that grows past
//            32 KB when the template values are filled in) overran the stack.
//            Same for the "where" of nox_sqlUpdate (1 KB / 4 KB), the "default"
//            markers of nox_sqlInsert (4 KB) and the count statement of nox_sqlRows.
//            Db2 CLI (UTF-8 mode, 7.3) itself takes statements up to 64 KB: a longer one
//            is an SQL error (cut off), returned as the error object.
//            Also: nox_sqlDisconnect left pLastConnnection behind, and the activation
//            group end freed that connection a second time (MCH6902 in the job log)
ctl-opt main( main )
             option(*srcstmt : *nodebugio: *showcpy : *expdds: *nounref)
             extbinint(*yes)
             decedit(',')
             bnddir( 'NOXDBUTF8/NOXDBUTF8' )
             ccsid(*char:*jobrun);

/include noxdbutf8/qrpgleref,noxdbutf8

// Note: no [ ] in paths or literals here - this source compiles in any job CCSID.
// The template markers ${ } are variant characters too: they come from hex (UTF-8)
dcl-s mStart varchar(2) ccsid(*utf8) inz(x'247B');  // ${
dcl-s mEnd   varchar(1) ccsid(*utf8) inz(x'7D');    // }


dcl-proc main;

    dcl-s MemStart int(20);
    dcl-s MemNow   int(20);
    dcl-s pCon     pointer;
    dcl-s pRes     pointer;
    dcl-s pParms   pointer;
    dcl-s pRow     pointer;
    dcl-s pSQL     pointer;
    dcl-s stmt     like(NOX_UTF8);
    dcl-s value    like(NOX_UTF8);
    dcl-s i        int(10);
    dcl-s size     int(10);
    dcl-s sizes    int(10) dim(4);
    dcl-s ok       ind;

    nox_Assert ('Start issue0147') ;
    MemStart = nox_memUse();
    pCon = nox_sqlConnect();

    nox_sqlExec(pCon : 'declare global temporary table session.issue147 (n int) '
                     + 'with replace on commit preserve rows not logged');

    // Plain statements around and far over 32 KB - result set, with limit / offset
    sizes(1) = 32600;
    sizes(2) = 32800;
    sizes(3) = 40000;
    sizes(4) = 65000;
    for i = 1 to 4;
        size = sizes(i);
        stmt = 'select c from (values 1,2,3) t(c) /* ' + pad(size) + ' */ order by c';
        pRes = nox_sqlResultSet(pCon : stmt : *null : NOX_GRACEFUL_ERROR);
        nox_Assert ('resultSet ' + %char(%len(stmt)) + ' bytes: 3 rows'
                   : nox_GetStr(pRes : 'success' : '-') = '-' and nox_GetLength(pRes) = 3);
        nox_delete(pRes);

        pRes = nox_sqlResultSet(pCon : stmt : *null : NOX_GRACEFUL_ERROR : 2 : 1);
        nox_Assert ('resultSet ' + %char(%len(stmt)) + ' bytes, offset+limit: row 2'
                   : nox_GetLength(pRes) = 1
                     and nox_GetInt(nox_GetChild(pRes) : 'c' : -1) = 2);
        nox_delete(pRes);
    endfor;

    // Over the 64 KB Db2 CLI takes: an error object, nothing worse
    stmt = 'select c from (values 1,2,3) t(c) /* ' + pad(200000) + ' */';
    pRes = nox_sqlResultSet(pCon : stmt : *null : NOX_GRACEFUL_ERROR);
    nox_Assert ('resultSet 200 KB: error object' : nox_GetStr(pRes : 'success' : '-') = 'false');
    nox_delete(pRes);

    // Short template, long statement once the values are filled in (quotes doubled)
    pParms = nox_NewObject();
    value = '';
    for i = 1 to 2500;
        value += '''a';
    endfor;
    nox_SetStr(pParms : 'v' : value);
    stmt = 'select length(' + mStart + 'v' + mEnd + ') as l from sysibm.sysdummy1 /* ' + pad(30000) + ' */';
    pRes = nox_sqlResultRow(pCon : stmt : pParms : NOX_GRACEFUL_ERROR);
    nox_Assert ('template grows past 32 KB: value intact' : nox_GetInt(pRes : 'l' : -1) = 5000);
    nox_delete(pRes);

    // A marker name longer than the marker buffer: not found, so ''
    stmt = 'select length(' + mStart + pad(200) + mEnd + ') as l from sysibm.sysdummy1';
    pRes = nox_sqlResultRow(pCon : stmt : pParms : NOX_GRACEFUL_ERROR);
    nox_Assert ('long marker name: empty string' : nox_GetInt(pRes : 'l' : -1) = 0);
    nox_delete(pRes);

    // nox_sqlExec - with and without template values
    stmt = 'insert into session.issue147 values(1) /* ' + pad(40000) + ' */';
    nox_Assert ('exec 40 KB' : not nox_sqlExec(pCon : stmt));
    nox_SetInt(pParms : 'n' : 2);
    stmt = 'insert into session.issue147 values(' + mStart + 'n' + mEnd + ') /* ' + pad(40000) + ' */';
    nox_Assert ('exec 40 KB with template' : not nox_sqlExec(pCon : stmt : pParms));
    pRes = nox_sqlResultRow(pCon : 'select count(*) as n, sum(n) as s from session.issue147');
    nox_Assert ('exec: rows inserted' : nox_GetInt(pRes : 'n' : -1) = 2
                                        and nox_GetInt(pRes : 's' : -1) = 3);
    nox_delete(pRes);

    // nox_sqlValues
    stmt = 'length(''abc'') /* ' + pad(40000) + ' */';
    pRes = nox_sqlValues(pCon : stmt : *null : NOX_GRACEFUL_ERROR);
    nox_Assert ('values 40 KB' : nox_GetInt(pRes : '' : -1) = 3);
    nox_delete(pRes);

    // nox_sqlRows builds a count statement from the open one - and leaves that intact
    stmt = 'select c from (values 1,2,3) t(c) /* ' + pad(40000) + ' */ order by c desc';
    pSQL = nox_sqlOpen(pCon : stmt);
    nox_Assert ('rows 40 KB: 3' : nox_sqlRows(pSQL) = 3);
    pRow = nox_sqlFetchNext(pSQL);
    nox_Assert ('rows: cursor still ordered' : nox_GetInt(pRow : 'c' : -1) = 3);
    nox_delete(pRow);
    nox_sqlClose(pSQL);

    // nox_sqlUpdate: a "where" without the word "where" (was a 1 KB buffer) and over 4 KB
    pRow = nox_NewObject();
    nox_SetInt(pRow : 'n' : 5);
    value = 'n = 1 and ''' + pad(6000) + ''' <> ''''';
    ok = not nox_sqlUpdate(pCon : 'session.issue147' : pRow : value);
    nox_Assert ('update, 6 KB where' : ok);
    nox_delete(pRow);
    pRes = nox_sqlResultRow(pCon : 'select sum(n) as s from session.issue147');
    nox_Assert ('update: one row changed' : nox_GetInt(pRes : 's' : -1) = 7);
    nox_delete(pRes);

    // nox_sqlInsert: 600 blank columns become 600 ",default" markers (was a 4 KB buffer)
    stmt = 'declare global temporary table session.issue147w (';
    for i = 1 to 600;
        if i > 1;
            stmt += ',';
        endif;
        stmt += 'c' + %char(i) + ' int default 7';
    endfor;
    stmt += ') with replace on commit preserve rows not logged';
    nox_Assert ('wide table' : not nox_sqlExec(pCon : stmt));
    pRow = nox_NewObject();
    for i = 1 to 600;
        nox_SetStr(pRow : 'c' + %char(i) : '');
    endfor;
    ok = not nox_sqlInsert(pCon : 'session.issue147w' : pRow);
    nox_Assert ('insert, 600 default columns' : ok);
    nox_delete(pRow);
    pRes = nox_sqlResultRow(pCon : 'select c1 + c600 as s from session.issue147w');
    nox_Assert ('insert: defaults' : nox_GetInt(pRes : 's' : -1) = 14);
    nox_delete(pRes);

    return;

on-exit;

    nox_delete(pParms);
    nox_sqlExec(pCon : 'drop table session.issue147');
    nox_sqlExec(pCon : 'drop table session.issue147w');
    nox_sqlDisconnect(pCon);
    MemNow  = nox_memUse();
    nox_Assert ( 'Mem leak' : MemNow = MemStart);

    nox_Assert ('End issue0147') ;

end-proc;

// About "size" bytes of plain ASCII filler
dcl-proc pad;
    dcl-pi *n like(NOX_UTF8);
        size int(10) value;
    end-pi;
    dcl-s s like(NOX_UTF8);

    dow %len(s) + 10 <= size;
        s += '0123456789';
    enddo;
    return s;
end-proc;
