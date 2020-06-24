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
       Dcl-S pResult            Pointer;
       Dcl-S pSelected          Pointer;
       Dcl-S sql                VarChar(512);
       Dcl-S start                  Int(10:0);
       Dcl-S limit                  Int(10:0);


        // return a object with all rows
          sql   = 'Select * from product';
          start = 1;
          limit = 10; // Give me the 10 first rows

          // The json_META constructs a resultset object with a "row" array
          // Total rows convert ( if possible ) the select to an select count(*) first
          pResult = json_sqlResultSet(sql:start:limit:
             json_META + json_TOTALROWS
          );

          // Produce an other result set - like a selected dropdownbox
          sql   = 'Select * from product where prodkey  = 160';
          pSelected = json_sqlResultRow(sql);
          json_MoveObjectInto (pResult : 'selected' : pSelected);

          // Produce a JSON stream file in the root of the IFS
          json_writeJsonStmf(pResult:
             '/noxdb/json/resultset-and-one-selected.json': 1208 : *OFF
          );

          // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
          json_delete(pResult);
          json_sqlDisconnect();

          // That's it..
          *inlr = *on;
