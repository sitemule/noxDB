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

       // Parse json string and save it in different formats

       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S p1                 Pointer;
       Dcl-S p2                 Pointer;
       Dcl-S p3                 Pointer;

       p1 = json_newObject();
       p2 = json_ParseFile ('/prj/noxdb/testdata/resultset1.json');
       p3 = %alloc(1000000);
       json_AsJsonTextMem(p2 : p3 : 1000000);

       // to have a stringigfied json in the json
       // json_setPtr(p1 : 'json_InJson' : p3 : *ON);

       // This is already a serialized JSON string, so we can print it as it is:
       json_setPtr(p1 : 'json_InJson' : p3 : *OFF);

       json_WriteJsonStmf(p1 :'/prj/noxdb/testdata/json_in_json_.json':1208:*OFF);

       json_delete(p1);
       json_delete(p2);
       DeAlloc p3;
       *inlr = *on;
