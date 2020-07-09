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
         Dcl-S err                Ind;
         Dcl-S priceJsStr         VarChar(8000);
         Dcl-S priceObj           Pointer;


         // Set the delimiters used to access the graph selector
         json_setDelimiters ('/\@[] .{}''"$');
         
         // Simple update
         err = json_sqlExec(
            'update product set price = price * 1.01'
         );

         // update using json string used in template
         priceJsStr  = '{ newprice : 1.03 }';
         err = json_sqlExec(
            'update product set price = price * $newprice'
            :priceJsStr
         );

         // update using json object used in template
         priceObj    = json_parseString ('{ newprice : 1.04 }');
         err = json_sqlExec(
            'update product set price = price * $newprice'
            :priceObj
         );

         // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
         json_delete(priceObj);
         json_sqlDisconnect();

         // That's it..
         *inlr = *on;
