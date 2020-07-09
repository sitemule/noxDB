**FRE
        //  -------------------------------------------------------------
        //  noxDB - Not only XML. JSON, SQL and XML made easy for RPG
        //
        //  Company . . . : System & Method A/S - Sitemule
        //  Design  . . . : Niels Liisberg
        //
        //  Unless required by applicable law or agreed to in writing, software
        //  distributed under the License is distributed on an "AS IS" BASIS,
        //  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
        //
        //  Look at the header source file "QRPGLEREF" member "NOXDB"
        //  For a complete description of the functionality
        //
        //      When using noxDB you need two things:
        //       A: Bind you program with "NOXDB" Bind directory
        //       B: Include the noxDB prototypes from QRPGLEREF member NOXDB
        //
        //  ------------------------------------------------------------- *
        //  Using SQL cursors. Row by row is one solution
        //
        //  -------------------------------------------------------------
          Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');

          /include qrpgleRef,noxdb
          Dcl-S pRows pointer;
          Dcl-S sql   varchar(512);

          // return an simple array with all rows
          json_sqlSetOptions ('{ hexSort : true }');
          sql = 'Select * from product where manuid= ''ACER'' order by prodid';
          pRows = json_sqlResultSet(sql);

          // Produce a JSON stream file in the root of the IFS
          json_writeJsonStmf(pRows  :
             '/prj/noxdb/testdata/resultset-array1.json' : 1208 :*OFF
          );

          // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
          json_delete(pRows);

          // return an simple array with all rows
          json_sqlSetOptions ('{ hexSort : true }');
          sql= 'Select * from product where manuid = ''ACER'' order by prodid';
          pRows = json_sqlResultSet(sql);

          // Produce a JSON stream file in the root of the IFS
          json_writeJsonStmf(pRows  :
             '/prj/noxdb/testdata/resultset-array2.json' : 1208 :*OFF
          );

          // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
          json_delete(pRows);
          json_sqlDisconnect();

          // That's it..
          *inlr = *on;
