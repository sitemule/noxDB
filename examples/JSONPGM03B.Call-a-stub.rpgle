**FREE
// ------------------------------------------------------------- *
// noxDB - Not only XML. JSON, SQL and XML made easy for RPG

// Company . . . : System & Method A/S - Sitemule
// Design  . . . : Niels Liisberg

// Calling a ILE service program via noxDB JSON interface
// Note: You need to have built the stub and interface first, e.g.

// call   JSONPGM03A
// CRTRPGMOD MODULE(noxdb/STUB) SRCSTMF('/prj/noxdb/testout/NOXDB-JSONPGM00C.rpgle')
// CRTSRVPGM SRVPGM(NOXDB/STUB) EXPORT(*ALL)
// call JSONPGM03B ( NOXDB STUB 'GetClaimSummary                                       ')

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
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE')  main(main);
/include qrpgleRef,noxdb

dcl-proc main;

    dcl-pi *N;
        lib     char(10) ;
        pgm     char(10) ;
        proc    char(30);
    end-pi;

    dcl-s pMeta      pointer;
    dcl-s pOut       pointer;
    dcl-s pIn        pointer;
    dcl-s msg        char(50);


    // Get meta info from a ILE program:
    // Note - this will be in PCML format a.k.a XML, but in the object graph
    pMeta = json_ProcedureMeta (lib : pgm: '*ALL');

    // Just dump the result to IFS stream file since it is XML by nature:
    json_WriteXMLStmf(pMeta:'/prj/noxdb/testout/nox-meta.pcml':1208:*OFF);

    pIn = json_parseFile ( '/prj/noxdb/testout/nox-in.json');

    pOut  = json_CallProcedure  (
        lib :
        pgm :
        %trim(proc):
        pIn:
        JSON_GRACEFUL_ERROR
    );

    json_joblog( json_Message(pOut));

    // Dump the result to both joblog and IFS stream file
    json_WriteJsonStmf(pOut:'/prj/noxdb/testout/nox-out.json':1208:*OFF);

// Always clean up
on-exit;
    json_delete (pIn);
    json_delete (pOut);
    json_delete (pMeta);

end-proc;
