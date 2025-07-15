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

    getTheMeta();
    callByObject();
    callByJsonString();

    // That's it..
    *inlr = *on;


// ------------------------------------------------------------------------------------
// getTheMeta
// ------------------------------------------------------------------------------------
dcl-proc getTheMeta;

    Dcl-S pMeta      Pointer;

    // Get meta info from a ILE program:
    // Note - this will be in PCML format a.k.a XML, but in the object graph
    pMeta = json_ProgramMeta ('*LIBL' : 'JSONPGM00A');

    // Just dump the result since it is XML by nature:
    json_WriteXMLStmf(pMeta:'/prj/noxdb/testout/pgmmeta.xml':1208:*OFF);

    // Always clean up
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
    EndIf;

    // Dump the result
    json_joblog(pOut);

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

   // Set your delimiter according to your CCSID of your source file if you parse any strings.
   // Note the "makefile" is set to international - ccsid 500 for all source files in the examples
   json_setDelimitersByCcsid(500);

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
    EndIf;

    // Dump the result
    json_joblog(pOut);

    // Always clean up
    json_delete (pOut);

   // Reset you delimiters to default:
   json_setDelimitersByCcsid(0);

end-proc;