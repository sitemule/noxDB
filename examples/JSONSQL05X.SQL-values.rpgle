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
// Using SQL values
// ------------------------------------------------------------------------------------
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
/include qrpgleRef,noxdb

   // Run the examples
   example1();
   example2();

   // Final Cleanup: Close the SQL cursors and disconnect
   json_sqlDisconnect();

   // That's it..
   *inlr = *on;

// ------------------------------------------------------------------------------------
// example1 simple return 2+2 = 4
// ------------------------------------------------------------------------------------
dcl-proc example1;

   Dcl-S pValues              Pointer;

   // return an simple array with rows
   pValues = json_sqlValues ('2 + 2') ;

   // Produce a JSON stream file in the IFS
   json_writeJsonStmf(pValues  :
      '/prj/noxdb/testout/values1.json' : 1208 :*OFF
   );

   // Cleanup: dispose the rows in the array
   json_delete(pValues);

end-proc;
// ------------------------------------------------------------------------------------
// example2 return an array
// ------------------------------------------------------------------------------------
dcl-proc example2;

   Dcl-S pValues              Pointer;

   // return an simple array with rows
   pValues = json_sqlValues ('1, 2, 3 , ''A'', ''B'', ''C'' ') ;

   // Produce a JSON stream file in the IFS
   json_writeJsonStmf(pValues  :
      '/prj/noxdb/testout/values2.json' : 1208 :*OFF
   );

   // Cleanup: dispose the rows in the array
   json_delete(pValues);

end-proc;
