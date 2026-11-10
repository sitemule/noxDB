**FREE
// Issue 155: GRAPHIC / VARGRAPHIC / NCHAR / NVARCHAR columns (UTF-16) were converted to UTF-8 into a
//            fixed 32 KB stack buffer when a row was fetched. UTF-8 takes up to 3 bytes for
//            what UTF-16 has in 2, so a long value overran the stack: 16000 x U+20AC (euro)
//            is 32000 bytes in UTF-16 and 48000 in UTF-8
ctl-opt main( main )
             option(*srcstmt : *nodebugio: *showcpy : *expdds: *nounref)
             extbinint(*yes)
             decedit(',')
             bnddir( 'NOXDBUTF8/NOXDBUTF8' )
             ccsid(*char:*jobrun);

/include noxdbutf8/qrpgleref,noxdbutf8

// Note: no [ ] in paths or literals here - this source compiles in any job CCSID.
// The euro sign comes from hex (UTF-8): the source CCSID does not matter
dcl-s euro varchar(3) ccsid(*utf8) inz(x'E282AC');


dcl-proc main;

    dcl-s MemStart int(20);
    dcl-s MemNow   int(20);
    dcl-s pCon     pointer;
    dcl-s pRes     pointer;
    dcl-s value    like(NOX_UTF8);
    dcl-s expect   like(NOX_UTF8);
    dcl-s i        int(10);

    nox_Assert ('Start issue0155') ;
    MemStart = nox_memUse();
    pCon = nox_sqlConnect();

    expect = '';
    for i = 1 to 16000;
        expect += euro;
    endfor;

    // VARGRAPHIC (SQL_VARGRAPHIC / SQL_WVARCHAR) - 48000 bytes UTF-8
    pRes = nox_sqlResultRow(pCon : 'select cast(repeat(ux''20AC'', 16000) as vargraphic(16000) ccsid 1200) as g,'
                                 + ' 7 as after from sysibm.sysdummy1' : *null : NOX_GRACEFUL_ERROR);
    value = nox_GetStr(pRes : 'g' : '');
    nox_Assert ('vargraphic 16000 euro: 48000 bytes' : %len(value) = 48000);
    nox_Assert ('vargraphic 16000 euro: the value'   : value = expect);
    nox_Assert ('vargraphic: next column intact'     : nox_GetInt(pRes : 'after' : -1) = 7);
    nox_delete(pRes);

    // GRAPHIC (fixed length, SQL_GRAPHIC / SQL_WCHAR)
    pRes = nox_sqlResultRow(pCon : 'select cast(repeat(ux''20AC'', 16000) as graphic(16000) ccsid 1200) as g'
                                 + ' from sysibm.sysdummy1' : *null : NOX_GRACEFUL_ERROR);
    value = nox_GetStr(pRes : 'g' : '');
    nox_Assert ('graphic 16000 euro: the value' : value = expect);
    nox_delete(pRes);

    // A short one still right, with the blanks of a fixed length column cut
    pRes = nox_sqlResultRow(pCon : 'select cast(ux''20AC0041'' as graphic(5) ccsid 1200) as g'
                                 + ' from sysibm.sysdummy1' : *null : NOX_GRACEFUL_ERROR);
    value = nox_GetStr(pRes : 'g' : '');
    nox_Assert ('graphic(5): euro and A' : value = euro + 'A');
    nox_delete(pRes);

    return;

on-exit;

    nox_sqlDisconnect(pCon);
    MemNow  = nox_memUse();
    nox_Assert ( 'Mem leak' : MemNow = MemStart);

    nox_Assert ('End issue0155') ;

end-proc;
