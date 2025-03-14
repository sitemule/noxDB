**free
//  ------------------------------------------------------------------------------------
//  noxDB - Not only XML. JSON, SQL and XML made easy for RPG
//
//  Document builder functions
//
//  Company . . . : System & Method A/S - Sitemule
//  Design  . . . : Niels Liisberg
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
//  Look at the header source file "QRPGLEREF" member "NOXDB"
//  for a complete description of the functionality
//  When using noxDB you need two things:
//   A: Bind you program with "NOXDB" Bind directory
//   B: Include the noxDB prototypes from QRPGLEREF member NOXDB
//  ------------------------------------------------------------------------------------
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') main(main);
/include qrpgleRef,noxdb
// ------------------------------------------------------------------------------------
// main
// ------------------------------------------------------------------------------------
dcl-proc main;

   Dcl-S pJson              Pointer;

// This will come soon !!
//   pJson = json_Arr (
//      json_Obj (
//         'name' : 'John' :
//         'age'  : json_int(35)
//      ):
//      json_Obj (
//         'name' : 'Mihael' :
//         'age'  : json_int(53)
//      )
//   );

   // Integer array
   pJson = json_Arr (
      json_int(1):
      json_int(2):
      json_int(3)
   );
   json_WriteJsonStmf(pJson:'/prj/noxdb/testout/doc-builder-int.json':1208:*OFF);
   json_delete(pJson);


   // Defaults to char string
   pJson = json_Arr ('A':'B':'C') ;
   json_WriteJsonStmf(pJson:'/prj/noxdb/testout/doc-builder-str.json':1208:*OFF);
   json_delete(pJson);

   // Mixture of int and char string
   pJson = json_Arr (
      'A':
      json_int(1):
      'B':
      json_int(2):
      'C':
      json_int(3)
   );
   json_WriteJsonStmf(pJson:'/prj/noxdb/testout/doc-builder-mix.json':1208:*OFF);
   json_delete(pJson);


end-proc;
