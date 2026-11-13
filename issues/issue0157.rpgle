**FREE
// -------------------------------------------------------------
// noxDB - Not only XML. JSON, SQL and XML made easy for RPG

// Company . . . : System & Method A/S - Sitemule
// Design  . . . : Niels Liisberg

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

// Issue 157: Db2 for i CLI resources were scoped to the noxDB service
// program. When an exported procedure returned and the service program left
// the stack, an open cursor could be lost before the next exported procedure
// re-entered the service program.
//
// This test deliberately opens a cursor in one noxDB call and fetches its
// rows through later noxDB calls. Each call crosses the service-program
// boundary. SQL_ATTR_INVOKING_PGM keeps the CLI resources scoped to this top
// program while the service program leaves and re-enters the stack.
//
// Run it in a CCSID(500) job and look for "ASSERT FAILED" in the joblog -
// none means OK.
// -------------------------------------------------------------
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') main(main);
/include qrpgleRef,noxdb

dcl-proc main;

    dcl-s pSql pointer;
    dcl-s pRow pointer;
    dcl-s expected int(10);

    pSql = json_sqlOpen(
        'select c from (values 1, 2, 3) t(c) order by c');
    assert('cursor opened' : pSql <> *null);

    for expected = 1 to 3;
        // json_sqlOpen and every fetch are separate service-program calls.
        pRow = json_sqlFetchNext(pSql);
        assert('cursor survives service-program re-entry' : pRow <> *null);
        if pRow <> *null;
            assert('fetched row has expected value' :
                json_getInt(pRow : 'C' : -1) = expected);
            json_delete(pRow);
        endif;
    endfor;

    pRow = json_sqlFetchNext(pSql);
    assert('cursor reaches end of data' : pRow = *null);

    json_sqlClose(pSql);
    json_sqlDisconnect();
    json_joblog('issue0157 done');

end-proc;

dcl-proc assert;

    dcl-pi *n;
        text varchar(256) value;
        ok   ind value;
    end-pi;

    if not ok;
        json_joblog('ASSERT FAILED: ' + text);
    endif;
end-proc;
