**FREE
// -------------------------------------------------------------
// noxDB - Not only XML. JSON, SQL and XML made easy for RPG

// Company . . . : System & Method A/S - Sitemule
// Design  . . . : Niels Liisberg

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

// This test, issue0138, is regression test
// An empty string ends with ONE null - an RPG varchar passed with
// options(*string) gets only one. Whatever follows that null is not part of
// the string and must not be parsed: json_parseString returns *NULL.
// Since #126 a lone null was taken as the high byte of a BOM-less big-endian
// Unicode character, the scan went on into the bytes after it, and an IceCap
// job looped in jx_ParseXml.
// A string with nothing to parse - only blanks, or plain text - is empty too:
// it gave the parser a NULL buffer, and jx_ParseXml looped.
// BOM-less big-endian Unicode files (#126) are tested by issue0126.
//
// Run it in a CCSID(500) job (see issues/Makefile) and look for
// "ASSERT FAILED" in the joblog - none means OK.
// -------------------------------------------------------------
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') main(main);
/include qrpgleRef,noxdb

dcl-proc main;

    dcl-s pDoc    pointer;
    dcl-s empty   varchar(256);
    dcl-ds junk   qualified;
        buf char(64);
    end-ds;

    // Empty RPG varchar - options(*string) adds one null
    empty = '';
    pDoc = json_parseString(empty);
    assert ('empty varchar' : pDoc = *NULL);
    json_delete(pDoc);

    // One null, then EBCDIC XML that is not part of the string
    junk.buf = x'00' + 'x<a>b</a>' + x'00';
    pDoc = json_parseString(%addr(junk.buf));
    assert ('null + EBCDIC junk' : pDoc = *NULL);
    json_delete(pDoc);

    // One null, then ASCII "<a>" that is not part of the string
    junk.buf = x'003C613E00';
    pDoc = json_parseString(%addr(junk.buf));
    assert ('null + ASCII junk' : pDoc = *NULL);
    json_delete(pDoc);

    // One null, then ASCII "{" that is not part of the string
    junk.buf = x'007B226122' + x'00';
    pDoc = json_parseString(%addr(junk.buf));
    assert ('null + ASCII json junk' : pDoc = *NULL);
    json_delete(pDoc);

    // Only blanks - looped in jx_ParseXml before the fix
    pDoc = json_parseString('   ');
    assert ('blanks only' : pDoc = *NULL);
    json_delete(pDoc);

    // Plain text, nothing to parse - looped in jx_ParseXml before the fix
    pDoc = json_parseString('abc');
    assert ('plain text' : pDoc = *NULL);
    json_delete(pDoc);

    // Still parsed: leading blanks before the document
    pDoc = json_parseString('  {"a":"b"}');
    assert ('blanks + json' : json_getStr(pDoc : 'a') = 'b');
    json_delete(pDoc);

    pDoc = json_parseString('  <a>b</a>');
    assert ('blanks + xml' : json_getStr(pDoc : '/a') = 'b');
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
        json_joblog( 'ASSERT FAILED: ' + text);
    endif;
end-proc;
