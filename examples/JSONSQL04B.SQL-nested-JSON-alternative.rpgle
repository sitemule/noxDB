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
       Dcl-S prodRow            Pointer;
       Dcl-S resultArray        Pointer;
       Dcl-S resultObj          Pointer;
       Dcl-S manuHnd            Pointer;
       Dcl-S prodHnd            Pointer;
       Dcl-S sql                VarChar(512);


        json_MemStat();

        // The destination object for our SQL result row
        // and the array to contain the rows
          resultArray  = json_newArray ();

          prodRow    = json_newObject ();
          json_setValue(prodRow :'n' : 'abc'  );

          json_MemStat();
          json_setValue(resultArray: '[]' : prodRow: json_OBJMOVE);
          json_MemStat();
          json_delete(resultArray);

          json_MemStat();

          // That's it..
          *inlr = *on;
