**free
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
// Return a reultset as an array
// ------------------------------------------------------------- *
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') option(*nodebugio: *srcstmt);
/include qrpgleRef,noxdb
Dcl-S pRows              Pointer;
Dcl-S sql                VarChar(512);


// return an simple array with all rows
   sql   = 'Select * from noxdbdemo.icproduct';
   pRows = json_sqlResultSet(sql);

   // Produce a JSON stream file in the root of the IFS
   json_writeJsonStmf(pRows  :
      '/prj/noxdb/testout/resultset-array.json' : 1208 :*OFF
   );

   // Cleanup: delete the object
   json_delete(pRows);

   // Optinal - disconnect or let the connection live on
   // json_sqlDisconnect();

   // That's it..
   *inlr = *on;
