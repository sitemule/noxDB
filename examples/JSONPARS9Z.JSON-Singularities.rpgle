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
       // Singularities for the parser is:

       //    json_parseString('');                -> null pointer
       //    json_parseString('null');            -> null value
       //    json_parseString('true');            -> true
       //    json_parseString('false');           -> false
       //    json_parseString('{}');              -> Empty object
       //    json_parseString('[]');              -> Empty Array
       //    json_parseString('12345');           -> digits
       //    json_parseString('"A string "');     -> string
       //    json_parseString('12345 - abc');     -> string

       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S p0                 Pointer;
       Dcl-S p1                 Pointer;
       Dcl-S p2                 Pointer;
       Dcl-S p3                 Pointer;
       Dcl-S p4                 Pointer;
       Dcl-S p5                 Pointer;
       Dcl-S p6                 Pointer;
       Dcl-S p7                 Pointer;
       Dcl-S p8                 Pointer;
       // ------------------------------------------------------------- *
          *inlr = *on;
          p0 = json_parseString('12345 - abc');
          p1 = json_parseString('"A string "');
          p2 = json_parseString('');
          p3 = json_parseString('{}');
          p4 = json_parseString('[]');
          p5 = json_parseString('null');
          p6 = json_parseString('true');
          p7 = json_parseString('false');
          p8 = json_parseString('12345');

          json_WriteJsonStmf(p1:'/noxdb/json/limits0.json':1208:*OFF);
          json_WriteJsonStmf(p1:'/noxdb/json/limits1.json':1208:*OFF);
          json_WriteJsonStmf(p2:'/noxdb/json/limits2.json':1208:*OFF);
          json_WriteJsonStmf(p3:'/noxdb/json/limits3.json':1208:*OFF);
          json_WriteJsonStmf(p4:'/noxdb/json/limits4.json':1208:*OFF);
          json_WriteJsonStmf(p5:'/noxdb/json/limits5.json':1208:*OFF);
          json_WriteJsonStmf(p6:'/noxdb/json/limits6.json':1208:*OFF);
          json_WriteJsonStmf(p7:'/noxdb/json/limits7.json':1208:*OFF);
          json_WriteJsonStmf(p8:'/noxdb/json/limits8.json':1208:*OFF);

          json_delete(p1);
          json_delete(p2);
          json_delete(p3);
          json_delete(p4);
          json_delete(p5);
          json_delete(p6);
          json_delete(p7);
          json_delete(p8);

