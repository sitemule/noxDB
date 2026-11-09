**FREE
// -------------------------------------------------------------
// noxDB - Not only XML. JSON, SQL and XML made easy for RPG

// Company . . . : System & Method A/S - Sitemule
// Design  . . . : Niels Liisberg

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

// This test, issue0150, is regression test
// json_AsJsonText16M(node) - without the optional targetCcsid - writes
// { } [ ] in the job CCSID. The prototype is RTNPARM: the return value is
// a hidden first parameter, so a call with only the node has two
// parameters, and since #126 (ddce225) a targetCcsid that was not passed
// was read - whatever was left in that storage. Here a call with 277 is
// made first, so the storage holds 277 when the omitted call comes.
//
// Run it in a CCSID(500) job (see issues/Makefile) and look for
// "ASSERT FAILED" in the joblog - none means OK.
// -------------------------------------------------------------
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') main(main);
/include qrpgleRef,noxdb

dcl-proc main;

    dcl-s pNode   pointer;
    dcl-s txt     varchar(256);
    dcl-s i       int(10);

    pNode = json_parseString('{"a":[1,2]}');
    assert ('parse' : pNode <> *NULL);

    for i = 1 to 3;
        // explicit 277: { is x'9C' there
        txt = json_AsJsonText16M(pNode : 277);
        assert ('explicit 277 {' : %subst(txt : 1 : 1) = x'9C');

        // omitted: the job CCSID - this source and the job are 500
        txt = json_AsJsonText16M(pNode);
        assert ('omitted is the job ccsid {' : %subst(txt : 1 : 1) = '{');
        assert ('omitted is the job ccsid [' : %scan('[' : txt) > 0);
        assert ('omitted is the job ccsid }' : %subst(txt : %len(txt) : 1) = '}');

        // explicit 0: the job CCSID
        txt = json_AsJsonText16M(pNode : 0);
        assert ('explicit 0 {' : %subst(txt : 1 : 1) = '{');
    endfor;

    json_delete(pNode);
    json_joblog('issue0150 done');

end-proc;

dcl-proc assert;

    dcl-pi *n;
        text varchar(256) value;
        ok   ind value;
    end-pi;

    if not ok;
        json_joblog( 'ASSERT FAILED: ' + text);
    endif;
end-proc;
