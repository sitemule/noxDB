**free
// ------------------------------------------------------------------------------------
// noxDB - Not only XML. JSON, SQL and XML made easy for RPG
//
// Company . . . : System & Method A/S - Sitemule
// Design  . . . : Niels Liisberg
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// Look at the header source file "QRPGLEREF" member "NOXDB"
// for a complete description of the functionality
//
//
// ------------------------------------------------------------------------------------
// The aim is to produce a JSON from scratch using UTF-8
// ------------------------------------------------------------------------------------
ctl-opt main(main);
ctl-opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') ;
ctl-opt copyright('Sitemule.com (C), 2023-2025');
ctl-opt decEdit('0,') datEdit(*YMD.);
ctl-opt debug(*yes);

/include qrpgleRef,noxdb
dcl-proc main;

    // Set your delimiter according to your CCSID of your source file if you parse any strings.
    // Note the "makefile" is set to international - ccsid 500 for all source files in the examples
    json_setDelimitersByCcsid(500);
    buildAndWrite();

end-proc;

// ------------------------------------------------------------------------------------
dcl-proc buildAndWrite;

    Dcl-S pJson      Pointer;
    Dcl-S china      VarChar(50) CCSID(*UTF8);

    // Create a new JSON object
    pJson = json_newObject();

    // Add some values to the JSON object
    json_setStr(pJson: 'name': 'Zhang San');
    json_setStrUtf8(pJson: 'china': u'5F204E09');
    json_setInt(pJson: 'age': 30);
    json_setBool(pJson: 'isActive': *ON);

    // Dump the result and to IFS JSON stream file
    // Write the JSON object to a stream file in UTF-8 encoding
    json_joblog(pJson);
    json_WriteJsonStmf(pJson:'/prj/noxdb/testout/jsonutf10a.UTF-8-Build-from-scratch-out1.json':1208:*OFF);

on-exit;
    // Always clean up
    json_delete (pJson);

end-proc;
