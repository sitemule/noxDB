       // ------------------------------------------------------------- *
       // noxDB - Not only XML. JSON, SQL and XML made easy for RPG
       //
       // Company . . . : System & Method A/S - Sitemule
       // Design  . . . : Niels Liisberg
       //
       // Unless required by applicable law or agreed to in writing, software
       // distributed under the License is distributed on an "AS IS" BASIS,
       // WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
       //
       // Look at the header source file "QRPGLEREF" member "NOXDB"
       // for a complete description of the functionality
       //
       // When using noxDB you need two things:
       //  A: Bind you program with "NOXDB" Bind directory
       //  B: Include the noxDB prototypes from QRPGLEREF member NOXDB
       //
       // ------------------------------------------------------------- *
       // Using SQL cursors. Row by row is one solution

       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S pRows              Pointer;
       Dcl-S sql                VarChar(512);
       Dcl-S i                  int(10);

       // return an simple array with all rows
       sql   = 'Select dec(0 , 9 , 2 ) as a from qsrc';
       pRows = json_sqlResultSet(sql);
       json_WriteJsonStmf(pRows:'/noxdb/json/dump-payload.json':1208:*OFF);
       json_delete(pRows);


       // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
       json_sqlDisconnect();

       // That's it..
       *inlr = *on;
