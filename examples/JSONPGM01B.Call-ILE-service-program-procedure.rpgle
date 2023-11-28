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
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') ;
/include qrpgleRef,noxdb
Dcl-S pMeta      Pointer;
Dcl-S pIn        Pointer;
Dcl-S pOut       Pointer;
Dcl-s msg        char(50);


    getTheMeta();
    callProcedureByObject();

    // That's it..
    *inlr = *on;


// ------------------------------------------------------------------------------------
// getTheMeta
// ------------------------------------------------------------------------------------
dcl-proc getTheMeta;

    Dcl-S pMeta      Pointer;

    // Get meta info from a ILE program:
    // Note - this will be in PCML format a.k.a XML, but in the object graph
    pMeta = json_ProcedureMeta ('*LIBL' : 'HELOSRVPGM': '*ALL');

    // Just dump the result since it is XML by nature:
    json_WriteXMLStmf(pMeta:'/prj/noxdb/testout/srvpgmmeta.xml':1208:*OFF);

    // Always clean up
    json_delete(pMeta);

end-proc;
// ------------------------------------------------------------------------------------
// callProcedureByObject
// ------------------------------------------------------------------------------------
dcl-proc callProcedureByObject;

    Dcl-S pIn        Pointer;
    Dcl-S pOut       Pointer;
    Dcl-s msg        char(50);

    // Setup an object and call
    pIn = json_newObject();
    json_setStr (pIn: 'name': 'John');
    json_setInt (pIn: 'age' : 25);


    pOut  = json_CallProcedure  ('*LIBL' : 'HELOSRVPGM' : 'NAMEAGE' : pIn : JSON_GRACEFUL_ERROR);
    If json_Error(pOut) ;
        msg = json_Message(pOut);
        dsply msg;
    EndIf;

    // Dump the result
    json_joblog(pOut);

    // Always clean up
    json_delete(pIn);
    json_delete (pOut);

end-proc;
