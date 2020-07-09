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
       Dcl-S pRows              Pointer;
       Dcl-S sql                VarChar(512);
       Dcl-S start                  Int(10:0);
       Dcl-S limit                  Int(10:0);


        // return a object with all rows
          sql   = ('-
                  Select (select prodkey  from product where 1=2) , product.* -
                        from product -
                  ');

                start = 1;
                limit = json_ALLROWS;
               pRows = json_sqlResultSet(sql:start:limit:json_META+json_FIELDS);

               // Produce a JSON stream file in the root of the IFS
                json_writeJsonStmf(pRows  :
                   '/prj/noxdb/testdata/resultset-object-1.json' : 1208 : *ON
                );

                // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
                json_delete(pRows);
                json_sqlDisconnect();

                // That's it..
                *inlr = *on;
