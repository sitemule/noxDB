**FREE
// ------------------------------------------------------------- *
// noxDB - Not only XML. JSON, SQL and XML made easy for RPG

// Company . . . : System & Method A/S - Sitemule
// Design  . . . : Niels Liisberg

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

// Look at the header source file "QRPGLEREF" member "NOXDB"
// for a complete description of the functionality

// When using noxDB you need two things:
//  A: Bind you program with "NOXDB" Bind directory
//  B: Include the noxDB prototypes from QRPGLEREF member NOXDB

// ------------------------------------------------------------- *


// ------------------------------------------------------------- *
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

    // getTheMeta and getTheMetaJson is not needed, but show what we got
    // and can be used to generate the openAPI.json
    getTheMeta();
    getTheMetaJson();

    callByObject();
    callByJsonString();

on-exit;
    // Reset you delimiters to default:
    json_setDelimitersByCcsid(0);

end-proc;
// ------------------------------------------------------------------------------------
// getTheMeta - is not need but show the PCML we have in the noxDb graph
// ------------------------------------------------------------------------------------
dcl-proc getTheMeta;

    Dcl-S pMeta      Pointer;

    // Get meta info from a ILE program:
    // Note - this will be in PCML format a.k.a XML, but in the object graph
    pMeta = json_ProgramMeta ('*LIBL' : 'JSONPGM00A');

    // Just dump the result since it is XML by nature:
    json_WriteXMLStmf(pMeta:'/prj/noxdb/testout/jsonpgm00a-meta.xml':1208:*OFF);

on-exit;
    // Always clean up
    json_delete(pMeta);

end-proc;
// ------------------------------------------------------------------------------------
// getTheMeta as JSON - is not need but show the nested JSON-like graph
// This is based on the PCML, but put in a nested JSON-like graph for easy
// use and works for both service programs and "normal" programs.
// ------------------------------------------------------------------------------------
dcl-proc getTheMetaJson;

    dcl-s pMeta      pointer;

    // Get meta info from a ILE program:
    // Note - this is based on the PCML, but put in a nested JSON-like graph for easy use
    // and works for both service programs and "normal" programs.
    pMeta = json_ApplicationMeta ('*LIBL' : 'JSONPGM00A': '*PGM');

    // Just dump the result to IFS JSON stream file since it is JSON by nature:
    json_WriteJsonStmf(pMeta:'/prj/noxdb/testout/jsonpgm00a-meta.json':1208:*OFF);

// Always clean up
on-exit;
    json_delete(pMeta);

end-proc;

// ------------------------------------------------------------------------------------
// callByObject
// ------------------------------------------------------------------------------------
dcl-proc callByObject;

    Dcl-S pIn        Pointer;
    Dcl-S pOut       Pointer;
    Dcl-s msg        char(50);

    // Setup an object and call
    pIn = json_newObject();
    json_setStr (pIn: 'name': 'John');
    json_setInt (pIn: 'age' : 25);


    pOut  = json_CallProgram  ('*LIBL' : 'JSONPGM00A' : pIn);
    If json_Error(pOut) ;
        msg = json_Message(pOut);
        dsply msg;
        return ; // Exit if error
    EndIf;

    // Dump the result and to IFS JSON stream file
    json_joblog(pOut);
    json_WriteJsonStmf(pOut:'/prj/noxdb/testout/jsonpgm00a-out1.json':1208:*OFF);


on-exit;
    // Always clean up
    json_delete(pIn);
    json_delete (pOut);

end-proc;

// ------------------------------------------------------------------------------------
// call By Json String
// ------------------------------------------------------------------------------------
dcl-proc callByJsonString;

    Dcl-S pOut       Pointer;
    Dcl-s msg        char(50);

    // here we let the call parse he string and do the cleanup of it
    pOut  = json_CallProgram  ( '*LIBL':'JSONPGM00A' :
        '{ -
            "name":"Niels", -
            "age" : 25 -
        }'
    );

    If json_Error(pOut) ;
        msg = json_Message(pOut);
        dsply msg;
        return; // Exit if error
    EndIf;

    // Dump the result and to IFS JSON stream file
    json_joblog(pOut);
    json_WriteJsonStmf(pOut:'/prj/noxdb/testout/jsonpgm00a-out2.json':1208:*OFF);

on-exit;
    // Always clean up
    json_delete (pOut);

end-proc;