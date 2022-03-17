**free
   // -------------------------------------------------------------
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
   
   // Run the SQL script icproduct.sql and icproduce_procedure.sql 
   // from the examples/sql in ACS before,
   // to have some test data

   // -------------------------------------------------------------
   // Using SQL cursors. Row by row is one solution

   // -------------------------------------------------------------
   Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
   /include qrpgleRef,noxdb
   Dcl-S pRows              Pointer;
   Dcl-S sql                VarChar(512);


   // return an simple array with all rows
   sql   = 'call  noxdbdemo.icproduct ( manufaturer => ''OLYMPUS'')';
   pRows = json_sqlResultSet(sql);

   // Produce a JSON stream file in the root of the IFS
   json_writeJsonStmf(pRows  :
      '/prj/noxdb/testout/procedure-output.json' : 1208 :*OFF
   );

   // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
   json_delete(pRows);
   json_sqlDisconnect();

   // That's it..
   *inlr = *on;
