**FREE
// Issue 154: SQL error messages with national letters: the message text comes from Db2 CLI in UTF-8
//            (the connection is in UTF-8 mode), but was converted to jxMessage with the
//            1252 table stra2e - "Token æ" became "Token Ã¦" in nox_Message and the job
//            log. The error object's "msg" was right only because stre2a undid it
ctl-opt main( main )
             option(*srcstmt : *nodebugio: *showcpy : *expdds: *nounref)
             extbinint(*yes)
             decedit(',')
             bnddir( 'NOXDBUTF8/NOXDBUTF8' )
             ccsid(*char:*jobrun);

/include noxdbutf8/qrpgleref,noxdbutf8

// Note: no [ ] in paths or literals here - this source compiles in any job CCSID.
// The national letters come from hex (UTF-8): the source CCSID does not matter
dcl-s ae      varchar(2) ccsid(*utf8) inz(x'C3A6');     // æ
dcl-s aeTwice varchar(4) ccsid(*utf8) inz(x'C383C2A6'); // Ã¦ - æ converted twice


dcl-proc main;

    dcl-s MemStart int(20);
    dcl-s MemNow   int(20);
    dcl-s pCon     pointer;
    dcl-s pRes     pointer;
    dcl-s msg      like(NOX_UTF8);
    dcl-s aeJob    varchar(2);       // æ in the job CCSID
    dcl-s jobMsg   varchar(1024);

    nox_Assert ('Start issue0154') ;
    MemStart = nox_memUse();
    pCon = nox_sqlConnect();
    aeJob = ae;

    // Db2 repeats the invalid token in its message: SQL0104 "Token æ was not valid"
    pRes = nox_sqlResultSet(pCon : 'select ' + ae + ' from sysibm.sysdummy1' : *null : NOX_GRACEFUL_ERROR);
    msg = nox_GetStr(pRes : 'msg' : '');
    nox_Assert ('error object: msg has the letter'   : %scan(ae : msg) > 0);
    nox_Assert ('error object: not converted twice'  : %scan(aeTwice : msg) = 0);
    nox_delete(pRes);

    jobMsg = nox_Message();
    nox_Assert ('nox_Message: the letter in the job CCSID' : %scan(aeJob : jobMsg) > 0);

    pRes = nox_GetMessageObject();
    msg = nox_GetStr(pRes : 'msg' : '');
    nox_Assert ('nox_GetMessageObject: msg has the letter' : %scan(ae : msg) > 0);
    nox_delete(pRes);

    // nox_sqlExec: the message goes to the job log too
    nox_sqlExec(pCon : 'update ' + ae + ' set x = 1');
    pRes = nox_sqlErrorObject(pCon);
    msg = nox_GetStr(pRes : 'msg' : '');
    nox_Assert ('sqlErrorObject: msg has the letter' : %scan(ae : msg) > 0
                                                     and %scan(aeTwice : msg) = 0);
    nox_delete(pRes);

    return;

on-exit;

    nox_sqlDisconnect(pCon);
    MemNow  = nox_memUse();
    nox_Assert ( 'Mem leak' : MemNow = MemStart);

    nox_Assert ('End issue0154') ;

end-proc;
