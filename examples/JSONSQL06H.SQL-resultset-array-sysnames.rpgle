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
// Using SQL cursors. Row by row is one solution

// ------------------------------------------------------------- *
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
/include qrpgleRef,noxdb
dcl-s pRows1      Pointer;
dcl-s pRows2      Pointer;
dcl-s pRows3      Pointer;
dcl-s err	      ind;

   // Create a test database
   err = json_sqlExec(
      'create schema noxdbdemo'
   );

   // Run a "normal SQL" to create the test case 
   err = json_sqlExec(
      'create or replace table noxdbdemo.table_using_systemnames  for system name sysnames  ( -
         id  bigint not null generated always as identity primary key, -
         customer_name for cstnam varchar(64) -
      ) rcdfmt sysnamesR'
   );

   pRows1 = json_newObject();
   json_setStr (pRows1: 'customer_name' : 'John');

   err = json_sqlInsert  (
      'noxdbdemo.table_using_systemnames'
      :pRows1
   );

   // returns the default output - SQL names
   pRows2 = json_sqlResultSet(
      'select * -
       from noxdbdemo.table_using_systemnames' 
       :1               // From from 
       :JSON_ALLROWS    // Number of rows 
       :JSON_ROWARRAY   // format of output
   );

   // Produce a JSON stream file in the IFS
   json_writeJsonStmf(pRows2 :
      '/prj/noxdb/testdata/system-names1.json' : 1208 :*OFF
   );

   // returns the output - system (short) names
   pRows3 = json_sqlResultSet(
      'select * -
       from noxdbdemo.table_using_systemnames' 
       :1            // From from 
       :JSON_ALLROWS // Number of rows 
       :JSON_ROWARRAY + JSON_SYSTEM_NAMES  // format of output - Using system (short) names
   );

   // Produce a JSON stream file in the IFS
   json_writeJsonStmf(pRows3 :
      '/prj/noxdb/testdata/system-names2.json' : 1208 :*OFF
   );

   // Cleanup: delete the object
   json_delete(pRows1);
   json_delete(pRows2);
   json_delete(pRows3);
   json_sqlDisconnect();

   // That's it..
   *inlr = *on;
