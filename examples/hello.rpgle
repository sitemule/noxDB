**free
// ------------------------------------------------------------- *
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
// Basic features example: build, save, load manipulate JSON
// ill only compile on >= 7.4 because of using overloads
//
// Step 1)
// When using noxDB you need two things:
//  A: Bind you program with "NOXDB" Bind directory
//  B: Include the noxDB prototypes from QRPGLEREF member NOXDB
//
// Step 2)
// Include the prototypes for noxDB and bind with bibddir NOXDB
//
// Step 3)
// Now you can use all the JSON, SQL and XML features
//
// Step 4)
// Finally remember to cleanup otherwise you will have a memory leak
// ------------------------------------------------------------- *
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) actgrp('QILE') option(*nodebugio:*srcstmt:*nounref) main(main);
/include qrpgleRef,noxdb

// ------------------------------------------------------------------------------------
// main
// ------------------------------------------------------------------------------------
dcl-proc main;

    Dcl-S pJson pointer;
    Dcl-S text  varchar(256);

    // Always set your ccsid for constants in your program source:
    // noxDb sample source are in ccsid 500 - multinational
    json_setDelimitersByCcsid(500);

    // Create a "hello world" object - and serialize it to the joblog
    pJson = json_newObject();
    json_setStr (pJson: 'text' : 'Hello world');
    json_joblog(pJson);


    // Now go and get the text from that object, and log the text:
    text = json_getStr  (pJson: 'text');
    json_joblog(Text);

    json_WriteJsonStmf(pJson:'/prj/noxdb/testout/hello.json':1208:*OFF);

    json_delete(pJson);


end-proc;