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
       Dcl-S manuRow            Pointer;
       Dcl-S prodArray          Pointer;
       Dcl-S resultArray        Pointer;
       Dcl-S resultObj          Pointer;
       Dcl-S manuHnd            Pointer;
       Dcl-S prodHnd            Pointer;
       Dcl-S sql                VarChar(512);


        // The destination object for our SQL result row
        // and the array to contain the rows
          resultArray  = json_newArray ();

          // Open our SQL cursor. Use a simple select
          sql = 'Select * from manufact';
          manuHnd  = json_sqlOpen(sql);

          // Now iterate on each row in the resultset
          manuRow = json_sqlFetchNext(manuHnd);
          DoW (manuRow <> *NULL);
             // Note: the SQL can be a template, we fill with values from a json row
             sql = 'Select * from product where manuid = $manuid' ;
             prodArray  = json_sqlResultSet(sql: 1 : 9999 : 0 : manuRow);
             // Append the row to the end of the result array.
             json_MoveObjectInto (manuRow   : 'products' : prodArray );
             json_ArrayPush (resultArray : manuRow );
             manuRow = json_sqlFetchNext(manuHnd) ;
          EndDo;

          // Produce a JSON stream file in the root of the IFS
          json_writeJsonStmf(resultArray  :
             '/noxdb/json/demo-nested.json' : 1208 : *OFF
          );
          json_NodeRename( resultArray : 'ROWS');
          // Give the root a name for XML
          json_writeXmlStmf(resultArray  :
             '/noxdb/xml/demo-nested.xml' : 1208 : *OFF
          );

          // Cleanup: Close the SQL cursor, dispose the row and the array
          json_delete(resultArray);
          json_sqlClose(manuHnd);
          json_sqlDisconnect();

          // If needed you can detect leaks here:
          If json_MemLeak();
             json_MemStat();
          EndIf;

          // That's it..
          *inlr = *on;
