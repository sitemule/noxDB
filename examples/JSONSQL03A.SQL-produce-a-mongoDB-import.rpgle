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
       Dcl-S text               VarChar(4096);
       Dcl-S i                  Int(10);


       // Open our SQL cursor. Use a simple select
       sql = ('-
          Select -
             ILGILGTKN,  -
             ILGITMTKN,  -
             ILGLNGCOD,  -
             ILGSEOURL,  -
             replace ( ILGPROP , '':.0'' , '':0.0'') as prop -
          from sqlbson/WSHILGET00  -
       ');

       sqlhnd  = json_sqlOpen(sql);

       // Now iterate on each row in the resultset
       pRow = json_sqlFetchNext(sqlhnd) ;
       DoW (pRow <> *NULL and i < 10000000);
          // Do stuff:
          text = json_asJsonText(pRow);
          json_delete(pRow);
          pRow = json_sqlFetchNext(sqlhnd) ;
          i += 1;
       EndDo;


       // Cleanup: Close the SQL cursor, dispose the row and the array
       json_sqlClose(sqlhnd);
       json_delete(rows);

       // That's it..
       *inlr = *on;
