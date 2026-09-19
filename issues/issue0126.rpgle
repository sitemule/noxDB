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

// -------------------------------------------------------------
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') main(main);
/include qrpgleRef,noxdb


dcl-proc main;

    dcl-s pInput  pointer;
    dcl-s pRowIn  pointer;
    dcl-s pRowOut pointer;
    dcl-s pCheck  pointer;
    dcl-s err     ind;
    dcl-s toParseA   varchar(256) ccsid(1208);
    dcl-s toParseE   varchar(256);
    dcl-s Athens  varchar(256) ccsid(1208);
    dcl-s Danish  varchar(256) ;

    dcl-ds xmlBugBufds qualified;
        varcharbuf  varchar(960000:4);
        len  int(10) pos(1);
        buf char(960000) pos(5);
    end-ds;


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

    json_WriteXmlStmf (pInput:'/prj/noxdb/testout/issue0126-2.xml':1208:*OFF);
    json_delete(pInput);

    pInput = json_parseFile ('/prj/noxdb/testout/issue0126-2.xml');
    xmlBugBufds.len = json_asXmlTextMem(pInput : %addr(xmlBugBufds.buf));
    assert ( 'xml1b' : xmlBugBufds.varcharbuf = '<test>&#x0388;&#x03B8;&#x03B8;&#x0386;&#x03BD;&#x03B1;&#x03B9;</test>');
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
    json_delete(pInput);

    // Unmappable Greek characters are serialised as JSON unicode escapes
    assert ( 'json1' : xmlBugBufds.varcharbuf = '{"test":"\u0388\u03B8\u03B8\u0386\u03BD\u03B1\u03B9"}');


    // Test the JSON - SBCS strings
    Danish = 'Smørrebrødspålæg';
    toParseE = '{"test":"' + Danish + '"}';
    pInput = json_ParseString (toParseE);
    xmlBugBufds.len = json_asJsonTextMem(pInput : %addr(xmlBugBufds.buf));
    json_delete(pInput);
    assert ( 'json2' : toParseE = xmlBugBufds.varcharbuf);


on-exit;
    json_delete(pInput);
    json_delete(pRowIn);
    json_delete(pRowOut);
    json_sqlDisconnect();
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
