**free
// ------------------------------------------------------------------------------------
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

// ------------------------------------------------------------------------------------
// Using SQL resultset rturning simple array
// This also demonstrate the use of limit and position in the resultset 
// ------------------------------------------------------------------------------------
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
/include qrpgleRef,noxdb

   // Run the examples
   example1();
   example2();
   example3();
   example4();
   example5();

   // Final Cleanup: Close the SQL cursors and disconnect
   json_sqlDisconnect();

   // That's it..
   *inlr = *on;

// ------------------------------------------------------------------------------------
// example1 all rows
// ------------------------------------------------------------------------------------
dcl-proc example1;

   Dcl-S pRows              Pointer;

   // return an simple array with rows
   pRows = json_sqlResultSet(
      'Select * from noxdbdemo.icproduct'
   );

   // Produce a JSON stream file in the IFS
   json_writeJsonStmf(pRows  :
      '/prj/noxdb/testout/resultset-array1.json' : 1208 :*OFF
   );

   // Cleanup: dispose the rows in the array
   json_delete(pRows);

end-proc;
// ------------------------------------------------------------------------------------
// example2
// Number of rows and limit
// Given by parameters 
// ------------------------------------------------------------------------------------
dcl-proc example2;

   Dcl-S pRows              Pointer;

   // return an simple array with rows
   pRows = json_sqlResultSet(
      'Select * from noxdbdemo.icproduct':
      10: // from and including row 10 
      5   // max 5 rows
   );

   // Produce a JSON stream file in the IFS
   json_writeJsonStmf(pRows  :
      '/prj/noxdb/testout/resultset-array2.json' : 1208 :*OFF
   );

   // Cleanup: dispose the rows in the array
   json_delete(pRows);

end-proc;
// ------------------------------------------------------------------------------------
// example3
// Number of rows and limit
// given by the SQL statement 
// ------------------------------------------------------------------------------------
dcl-proc example3;

   Dcl-S pRows              Pointer;

   // return an simple array with rows
   pRows = json_sqlResultSet(
      'Select * from noxdbdemo.icproduct -
      offset 10 rows fetch first 5 rows only'
   );

   // Produce a JSON stream file in the IFS
   json_writeJsonStmf(pRows  :
      '/prj/noxdb/testout/resultset-array3.json' : 1208 :*OFF
   );

   // Cleanup: dispose the rows in the array
   json_delete(pRows);

end-proc;
// ------------------------------------------------------------------------------------
// example4
// Number of rows and limit
// given by the SQL statement alternive syntax 
// Note!! Then spcial syntax of combined LIMIT X,Y is not supported !!
// ------------------------------------------------------------------------------------
dcl-proc example4;

   Dcl-S pRows              Pointer;

   // return an simple array with rows
   pRows = json_sqlResultSet(
      'Select * from noxdbdemo.icproduct -
      limit 5 offset 10 '
   );

   // Produce a JSON stream file in the IFS
   json_writeJsonStmf(pRows  :
      '/prj/noxdb/testout/resultset-array4.json' : 1208 :*OFF
   );

   // Cleanup: dispose the rows in the array
   json_delete(pRows);

end-proc;

// ------------------------------------------------------------------------------------
// example5
// Number of rows and limit
// precedence 
// given by the SQL statement ignors the parameters 
// ------------------------------------------------------------------------------------
dcl-proc example5;

   Dcl-S pRows              Pointer;

   // return an simple array with rows
   pRows = json_sqlResultSet(
      'Select * from noxdbdemo.icproduct -
      offset 10 rows fetch first 5 rows only':
      1 :  // from row  !! will be ignored since given in the sql statement
      100 // numberof rows !! will be ignored since given in the sql statement
   );

   // Produce a JSON stream file in the IFS
   json_writeJsonStmf(pRows  :
      '/prj/noxdb/testout/resultset-array5.json' : 1208 :*OFF
   );

   // Cleanup: dispose the rows in the array
   json_delete(pRows);

end-proc;
