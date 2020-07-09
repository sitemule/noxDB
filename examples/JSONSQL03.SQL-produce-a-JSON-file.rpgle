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
       Dcl-S pRow               Pointer;
       Dcl-S rows               Pointer;
       Dcl-S sqlHnd             Pointer;
       Dcl-S sql                VarChar(512);


        // The destination object for our SQL result row
        // and the array to contain the rows
          rows    = json_newArray ();

          // Open our SQL cursor. Use a simple select
          sql = 'Select * from product';
          sqlhnd  = json_sqlOpen(sql);

          // Now iterate on each row in the resultset
          pRow = json_sqlFetchNext(sqlhnd) ;
          DoW (pRow <> *NULL );
             // Append the row to the end of the result array. Note ArrayPush will
             // by default move the object ( not copy) to the bottom of the array.
             json_ArrayPush(rows : pRow);
             pRow = json_sqlFetchNext(sqlhnd) ;
          EndDo;

          // Produce a JSON stream file in the root of the IFS
          json_writeJsonStmf(rows : '/prj/noxdb/testdata/demo.json' : 1208 :*OFF);

          // Cleanup: Close the SQL cursor, dispose the row and the array
          json_delete(rows);
          json_sqlClose(sqlhnd);
          json_sqlDisconnect();

          // That's it..
          *inlr = *on;
