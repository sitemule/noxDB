**FREE
// -------------------------------------------------------------
// noxDB - Not only XML. JSON, SQL and XML made easy for RPG

// Company . . . : System & Method A/S - Sitemule
// Design  . . . : Niels Liisberg

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

// This test, issue0126, is regression test
// the graph in this "classic" noxdb is stores unicode
// as json exscapes i.e. u\1234 for unmappable chars to
// the jobs curren CCSID SBCS.
// meaning ÆØÅ is mappable to the current job ccsid SBCS i.e. in ccsid 277
// whereas Αθήνα will be escaped into unicode sequence
// \uCE88\uCEB8\uCEB8\uCE86\uCEBD\uCEB1\uCEB9
// This has to work when parsing XML, JSON og retriving data from db2, strings og IFS files
// and serialising it back into db2, strings and IFS files
//
// The whole test (doTest) is run twice - once per job CCSID (500 and 277),
// switched at runtime with CHGJOB. Per design.md, noxDB only reads the job
// CCSID once, the first time the service program is invoked in a job - a
// later CHGJOB is never discovered. Running doTest() twice like this is what
// actually exercises/proves that documented limitation, rather than just
// describing it.
// -------------------------------------------------------------
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') main(main);
/include qrpgleRef,noxdb

Dcl-Pr QCMDEXC extpgm('QCMDEXC');
    command   char(3000) const;
    length    packed(15:5) const;
End-Pr;

// Current CHGJOB CCSID pass - set by doTest() on entry, used only to tag
// ASSERT FAILED messages so failures in the joblog can be told apart.
dcl-s gPass varchar(20);


dcl-proc main;

    chgJobCcsid(500);
    doTest('ccsid500');

    chgJobCcsid(277);
    doTest('ccsid277');

end-proc;

// ------------------------------------------------------------------------------------
// Change the job CCSID at runtime via QCMDEXC (RPG's equivalent of a shell "system"
// call for CL commands).
// ------------------------------------------------------------------------------------
dcl-proc chgJobCcsid;
    dcl-pi *n;
        ccsid int(10) value;
    end-pi;

    dcl-s cmd varchar(100);

    cmd = 'CHGJOB CCSID(' + %char(ccsid) + ')';
    QCMDEXC(cmd : %len(%trim(cmd)));
end-proc;

// ------------------------------------------------------------------------------------
// doTest - the full regression pass. Called once per job CCSID from main().
// ------------------------------------------------------------------------------------
dcl-proc doTest;
    dcl-pi *n;
        pass varchar(20) value;
    end-pi;

    dcl-s pInput  pointer;
    dcl-s pRowIn  pointer;
    dcl-s pRowOut pointer;
    dcl-s pCheck  pointer;
    dcl-s err     ind;
    dcl-s toParseA   varchar(256) ccsid(1208);
    dcl-s toParseE   varchar(256);
    dcl-s toParseC   varchar(256) ccsid(500);
    dcl-s Athens  varchar(256) ccsid(1208);
    dcl-s Danish  varchar(256) ;
    dcl-s Danish500  varchar(256) ccsid(500);

    dcl-ds xmlBugBufds qualified;
        varcharbuf  varchar(960000:4);
        len  int(10) pos(1);
        buf char(960000) pos(5);
    end-ds;

    gPass = pass;

    json_sqlConnect();

    // Simple sql
    err =json_sqlExec(
        'create schema noxdbdemo'
    );
    if err and json_sqlcode() <> -601; // already exists is ok
        json_joblog(json_message());
        return;
    EndIf;

    // Create the table
    err = json_sqlExec(
        'create or replace table noxdbdemo.test_utf8 ( +
            text1 clob ccsid 1208, +
            text2 varchar(30) ccsid 1208, +
            text3 clob,       +
            text4 varchar(30) +
        ) on replace delete rows'
    );

    if err;
        json_joblog(json_message());
        return;
    EndIf;


    pRowIn  = json_newObject();
    json_setStr(pRowIn: 'text1': '\uCE88\uCEB8\uCEB8\uCE86\uCEBD\uCEB1\uCEB9');
    json_setStr(pRowIn: 'text2': '\uCE88\uCEB8\uCEB8\uCE86\uCEBD\uCEB1\uCEB9');
    json_setStr(pRowIn: 'text3': 'Smørrebrødspålæg');
    json_setStr(pRowIn: 'text4': 'Smørrebrødspålæg');

    // Insert a mult-charset text:
    // UTF-8 will convert and single bytes will keep the escape
    err = json_sqlInsert (
        'noxdbdemo.test_utf8'
        :pRowIn
    );

    if err;
        json_joblog(json_message());
        return;
    EndIf;

    pRowOut = json_sqlResultRow ('+
        select * +
        from noxdbdemo.test_utf8 +
    ');

    assert ( 'text1' : json_getstr(pRowIn  : 'text1')
                     = json_getstr(pRowOut : 'text1') );
    assert ( 'text2' : json_getstr(pRowIn  : 'text2')
                     = json_getstr(pRowOut : 'text2') );
    assert ( 'text3' : json_getstr(pRowIn  : 'text3')
                     = json_getstr(pRowOut : 'text3') );
    assert ( 'text4' : json_getstr(pRowIn  : 'text4')
                     = json_getstr(pRowOut : 'text4') );

    json_WriteJsonStmf(pRowOut:'/prj/noxdb/testout/issue0126-1.json':1208:*OFF);
    json_WriteXmlStmf (pRowOut:'/prj/noxdb/testout/issue0126-1.xml' :1208:*OFF);

    // Read both back and confirm the stream files round-trip the same values
    pCheck = json_parseFile('/prj/noxdb/testout/issue0126-1.json');
    assert ( 'json stmf text1' : json_getstr(pRowOut : 'text1') = json_getstr(pCheck : 'text1'));
    assert ( 'json stmf text2' : json_getstr(pRowOut : 'text2') = json_getstr(pCheck : 'text2'));
    assert ( 'json stmf text3' : json_getstr(pRowOut : 'text3') = json_getstr(pCheck : 'text3'));
    assert ( 'json stmf text4' : json_getstr(pRowOut : 'text4') = json_getstr(pCheck : 'text4'));
    json_delete(pCheck);

    pCheck = json_parseFile('/prj/noxdb/testout/issue0126-1.xml');
    assert ( 'xml stmf text1' : json_getstr(pRowOut : 'text1') = json_getstr(pCheck : 'text1'));
    assert ( 'xml stmf text2' : json_getstr(pRowOut : 'text2') = json_getstr(pCheck : 'text2'));
    assert ( 'xml stmf text3' : json_getstr(pRowOut : 'text3') = json_getstr(pCheck : 'text3'));
    assert ( 'xml stmf text4' : json_getstr(pRowOut : 'text4') = json_getstr(pCheck : 'text4'));
    json_delete(pCheck);


    // Test the XML - UTF-8 input - Athens in greek letters
    Athens = x'CE88CEB8CEB8CE86CEBDCEB1CEB9';
    toParseA = '<test>' + Athens + '</test>' + x'00';
    pInput = json_parseString ( %addr(toParseA:*data));
    xmlBugBufds.len = json_asXmlTextMem(pInput : %addr(xmlBugBufds.buf));

    // Unmappable Greek characters are serialised as XML numeric character references
    assert ( 'xml1a' : xmlBugBufds.varcharbuf = '<test>&#x0388;&#x03B8;&#x03B8;&#x0386;&#x03BD;&#x03B1;&#x03B9;</test>');

    // Same call, but pinned to ccsid 500 explicitly - the whole point of the
    // new targetCcsid parameter: this must match the (ccsid500-compiled)
    // expected literal on every pass, regardless of which ccsid the job
    // itself is actually running under right now (unlike the plain 'xml1a'
    // assert above, which is job-ccsid-dependent by design - see design.md
    // finding #6).
    xmlBugBufds.len = json_asXmlTextMem(pInput : %addr(xmlBugBufds.buf) : 500);
    assert ( 'xml1a ccsid500 pinned' : xmlBugBufds.varcharbuf = '<test>&#x0388;&#x03B8;&#x03B8;&#x0386;&#x03BD;&#x03B1;&#x03B9;</test>');

    json_WriteXmlStmf (pInput:'/prj/noxdb/testout/issue0126-2.xml':1208:*OFF);
    json_delete(pInput);

    pInput = json_parseFile ('/prj/noxdb/testout/issue0126-2.xml');
    xmlBugBufds.len = json_asXmlTextMem(pInput : %addr(xmlBugBufds.buf));
    assert ( 'xml1b' : xmlBugBufds.varcharbuf = '<test>&#x0388;&#x03B8;&#x03B8;&#x0386;&#x03BD;&#x03B1;&#x03B9;</test>');

    xmlBugBufds.len = json_asXmlTextMem(pInput : %addr(xmlBugBufds.buf) : 500);
    assert ( 'xml1b ccsid500 pinned' : xmlBugBufds.varcharbuf = '<test>&#x0388;&#x03B8;&#x03B8;&#x0386;&#x03BD;&#x03B1;&#x03B9;</test>');
    json_delete(pInput);


    // ---

    // Test the XML - SBCS strings
    Danish = 'Smørrebrødspålæg';
    toParseE = '<test>' + Danish + '</test>';
    pInput = json_ParseString (toParseE);
    xmlBugBufds.len = json_asXmlTextMem(pInput : %addr(xmlBugBufds.buf));

    assert ( 'xml2a' : toParseE = xmlBugBufds.varcharbuf);

    json_WriteXmlStmf (pInput:'/prj/noxdb/testout/issue0126-3.xml':1208:*OFF);
    json_delete(pInput);

    pInput = json_parseFile ('/prj/noxdb/testout/issue0126-3.xml');
    xmlBugBufds.len = json_asXmlTextMem(pInput : %addr(xmlBugBufds.buf));
    assert ( 'xml2b' : toParseE = xmlBugBufds.varcharbuf);
    json_delete(pInput);


    // Test the JSON  - UTF-8 input - only works if job runs in ccsid 500 as compiled obj
    Athens = x'CE88CEB8CEB8CE86CEBDCEB1CEB9';
    toParseA = '{"test":"' + Athens + '"}' + x'00';
    pInput = json_parseString ( %addr(toParseA:*data));
    xmlBugBufds.len = json_asJsonTextMem(pInput : %addr(xmlBugBufds.buf));

    // Unmappable Greek characters are serialised as JSON unicode escapes
    assert ( 'json1' : xmlBugBufds.varcharbuf = '{"test":"\u0388\u03B8\u03B8\u0386\u03BD\u03B1\u03B9"}');

    xmlBugBufds.len = json_asJsonTextMem(pInput : %addr(xmlBugBufds.buf) : %size(xmlBugBufds.buf) : 500);
    assert ( 'json1 ccsid500 pinned' : xmlBugBufds.varcharbuf = '{"test":"\u0388\u03B8\u03B8\u0386\u03BD\u03B1\u03B9"}');
    json_delete(pInput);


    // Test the JSON - SBCS strings
    Danish = 'Smørrebrødspålæg';
    toParseE = '{"test":"' + Danish + '"}';
    pInput = json_ParseString (toParseE);
    xmlBugBufds.len = json_asJsonTextMem(pInput : %addr(xmlBugBufds.buf));
    assert ( 'json2' : toParseE = xmlBugBufds.varcharbuf);

    // toParseE is built from ccsid500-compiled literal fragments ('{"test":"'
    // / '"}') concatenated with Danish, a plain job-ccsid variable - but RPG
    // doesn't reconvert either the literal fragments OR Danish's own content
    // to the job's ccsid after a later CHGJOB, so toParseE is genuinely still
    // ccsid500-encoded throughout when this parses, even though the job is
    // really at 277. This corrupts *parsing*, not just serialisation: å in
    // the compiled ccsid500 literal happens to be byte 71, which is ccsid
    // 277's closing brace `}` - so json_ParseString(toParseE), scanning under
    // job ccsid 277, misreads that å as the object's closing brace and
    // truncates parsing right there (confirmed - both the pinned and
    // unpinned serialisations of the SAME pInput come back short, proving
    // the tree itself is already truncated before either serialise call
    // runs). Pinning the serialiser's target ccsid can't fix a tree that's
    // already wrong - see design.md finding #7 (corrected 2026-09-22).
    xmlBugBufds.len = json_asJsonTextMem(pInput : %addr(xmlBugBufds.buf) : %size(xmlBugBufds.buf) : 500);
    assert ( 'json2 ccsid500 pinned' : xmlBugBufds.varcharbuf = '{"test":"Smørrebrødspålæg"}');
    json_delete(pInput);


    // Test the JSON - SBCS strings, explicit source ccsid
    // 'Smørrebrødspålæg' is baked into the object code using the *compile*
    // CCSID (500, see the issues/Makefile). If the job runs under a different
    // CCSID at runtime (e.g. 277), a plain job-ccsid variable would silently be
    // auto-converted from 500 to the job's ccsid the moment we assign into it -
    // so to actually exercise json_parseStringCcsid we keep the bytes tagged
    // ccsid(500) all the way (Danish500/toParseC), and explicitly tell the
    // parser the real ccsid, so it works regardless of the job's own ccsid.
    Danish500 = 'Smørrebrødspålæg';
    toParseC = '{"test":"' + Danish500 + '"}' + x'00';
    pInput = json_parseStringCcsid( %addr(toParseC:*data) : 500);
    // Pin the serialise side to ccsid 500 too, to match the parse side -
    // otherwise this comes back out in whatever ccsid the job is running
    // under right now, undoing the point of parsing at an explicit ccsid.
    // Parsing here is NOT affected by json2's bug below (json_parseStringCcsid
    // (...:500) correctly iconv-converts Danish500's ccsid500 bytes to the
    // job's real ccsid during parsing, since InputCcsid 500 != OutputCcsid
    // 277 - so the stored value ends up genuinely, correctly ccsid277-
    // encoded, not truncated). It still fails under the ccsid277 pass, but
    // for the plain, already-documented reason: the pinned serialiser only
    // repins the *punctuation* to ccsid500, not this now-ccsid277 value
    // content, so the output is a ccsid500/277 mix that won't byte-match a
    // pure-ccsid500 literal - exactly the scope note on jx_AsJsonTextMem
    // above already says it won't.
    xmlBugBufds.len = json_asJsonTextMem(pInput : %addr(xmlBugBufds.buf) : %size(xmlBugBufds.buf) : 500);
    json_delete(pInput);
    assert ( 'json3 ccsid500' : xmlBugBufds.varcharbuf = '{"test":"Smørrebrødspålæg"}');


    // Test loading + serialising test data files covering ccsid 1208, ccsid
    // 1252 and Unicode big/little endian, each with and without a BOM. All
    // seven files hold the same document: <A><B C="CCC">Smørrebrødspålæg</B></A>
    checkTestFile ('ccsid1208 +bom' : '/prj/noxdb/testdata/ccsid1208-bom.xml');
    checkTestFile ('ccsid1208 -bom' : '/prj/noxdb/testdata/ccsid1208-nobom.xml');
    checkTestFile ('ccsid1252'      : '/prj/noxdb/testdata/ccsid1252.xml');
    checkTestFile ('unicodeBE +bom' : '/prj/noxdb/testdata/unicodeBE.xml');
    checkTestFile ('unicodeBE -bom' : '/prj/noxdb/testdata/unicodeBE-nobom.xml');
    checkTestFile ('unicodeLE +bom' : '/prj/noxdb/testdata/unicodeLE.xml');
    checkTestFile ('unicodeLE -bom' : '/prj/noxdb/testdata/unicodeLE-nobom.xml');


on-exit;
    json_delete(pInput);
    json_delete(pRowIn);
    json_delete(pRowOut);
    json_sqlDisconnect();
end-proc;

// ------------------------------------------------------------------------------------
// checkTestFile - load a testdata file, confirm the value read back is correct, then
// serialise it back to XML in memory, re-parse *that*, and confirm the value survived
// the round trip too.
// ------------------------------------------------------------------------------------
dcl-proc checkTestFile;
    dcl-pi *n;
        label varchar(20) value;
        path  varchar(256) value;
    end-pi;

    dcl-s pDoc   pointer;
    dcl-s pDoc2  pointer;
    dcl-s val    varchar(256);
    // json_getStr() returns node value content in the current job ccsid, so
    // comparing it against a plain literal has the same job-ccsid-dependency
    // problem as the serializer asserts (design.md finding #6). Tried tagging
    // the *comparison side* ccsid(500) instead (same trick as Danish500/
    // toParseC above) to sidestep it without touching json_getStr() itself -
    // that does NOT work for 'load' (still fails under ccsid277 - RPG isn't
    // reconverting either side to match after the CHGJOB, tagged variable or
    // not). It's kept anyway since it's still more honest than an untagged
    // literal, and it's what makes 'serialise' below pass (there, both sides
    // of the final comparison go through the now-fixed, explicitly-pinned
    // serialiser instead of relying on this trick to do the work).
    dcl-s expected varchar(256) ccsid(500);

    dcl-ds fileBufds qualified;
        varcharbuf  varchar(60000:4);
        len  int(10) pos(1);
        buf char(60000) pos(5);
    end-ds;

    expected = 'Smørrebrødspålæg';

    pDoc = json_parseFile(path);
    val  = json_getStr(pDoc : '/A/B');
    assert ( label + ' load' : val = expected);

    // Pin both the serialise step and the re-parse of its output to ccsid
    // 500, so the whole round trip stays internally consistent regardless
    // of the job's own ccsid.
    fileBufds.len = json_asXmlTextMem(pDoc : %addr(fileBufds.buf) : 500);
    pDoc2 = json_parseStringCcsid(fileBufds.varcharbuf : 500);
    val   = json_getStr(pDoc2 : '/A/B');
    assert ( label + ' serialise' : val = expected);

    json_delete(pDoc2);
    json_delete(pDoc);
end-proc;

// ------------------------------------------------------------------------------------
// Inline unit test
// ------------------------------------------------------------------------------------
dcl-proc assert;

    dcl-pi *n;
        text varchar(256) value;
        ok   ind value;
    end-pi;

    if not ok;
        json_joblog( 'ASSERT FAILED [' + gPass + ']: ' + text);
    endif;
end-proc;
