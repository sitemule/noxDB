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

    // Call stored procedures
    callUsingNoxNodes();


    // That's it..
    *inlr = *on;

// ------------------------------------------------------------------------------------
// performance  - inout parameter usecase 
// 
// Create the procedure from ACS. Maybe change the schema location 
// 
// create or replace procedure qgpl.inc (
//     inout a int
// ) 
// begin 
//     set a = a + 1;
// end;
// call inc (a=>123);
// ------------------------------------------------------------------------------------
dcl-proc callUsingNoxNodes ;

    dcl-s p1            pointer;
    dcl-s p2            pointer;
    dcl-s err	        ind;
    dcl-s msg           char(50);
    
    // Build parameter objects
    p1  = json_newObject();
    json_SetStr(p1: 'name': 'John');
    json_SetInt(p1: 'age' : 25);
 
    p2  = json_newObject();
    json_SetBool (p2: 'success': *ON);

    // Caling procedures using nox nodes 
    // Let you use the noxDb object graph in SQL procedures 
    err = json_sqlCallNode ('qgpl.noxtest' : p1: p2);

    If err;
        msg = json_Message();
        dsply msg;
    EndIf;

    json_WriteJsonStmf(p2:'/prj/noxdb/testdata/procparms.json':1208:*OFF);
    json_delete(p1);
    json_delete(p2);

end-proc;
