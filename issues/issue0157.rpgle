**FREE
// Issue 157: Db2 for i CLI resources were scoped to the noxDB service
//            program. When an exported procedure returned and the service
//            program left the stack, an open cursor could be lost before the
//            next exported procedure re-entered the service program.
//
// This test deliberately opens a cursor in one noxDB call and fetches its
// rows through later noxDB calls. Each call crosses the service-program
// boundary. SQL_ATTR_INVOKING_PGM keeps the CLI resources scoped to this top
// program while the service program leaves and re-enters the stack.
ctl-opt main(main)
        option(*srcstmt : *nodebugio : *showcpy : *expdds : *nounref)
        extbinint(*yes)
        decedit(',')
        bnddir('NOXDBUTF8/NOXDBUTF8')
        ccsid(*char:*jobrun);

/include noxdbutf8/qrpgleref,noxdbutf8

dcl-proc main;

    dcl-s pCon pointer;
    dcl-s pSql pointer;
    dcl-s pRow pointer;
    dcl-s expected int(10);

    nox_Assert('Start issue0157');

    pCon = nox_sqlConnect();
    nox_Assert('connection allocated' : pCon <> *null);

    pSql = nox_sqlOpen(pCon :
        'select c from (values 1, 2, 3) t(c) order by c');
    nox_Assert('cursor opened' : pSql <> *null);

    for expected = 1 to 3;
        // nox_sqlOpen and every fetch are separate service-program calls.
        pRow = nox_sqlFetchNext(pSql);
        nox_Assert('cursor survives service-program re-entry' : pRow <> *null);
        if pRow <> *null;
            nox_Assert('fetched row has expected value' :
                nox_GetInt(pRow : 'c' : -1) = expected);
            nox_delete(pRow);
        endif;
    endfor;

    pRow = nox_sqlFetchNext(pSql);
    nox_Assert('cursor reaches end of data' : pRow = *null);

    nox_sqlClose(pSql);
    nox_sqlDisconnect(pCon);
    nox_Assert('End issue0157');

end-proc;
