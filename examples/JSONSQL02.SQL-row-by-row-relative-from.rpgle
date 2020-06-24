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
       Dcl-S sqlHnd             Pointer;
       Dcl-S text               VarChar(512);
       Dcl-S ints                   Int(10:0);
       Dcl-S numbers             Packed(11:2);
       Dcl-S dates                 Date;
       Dcl-S msg                VarChar(512);
       Dcl-S cols                   Int(10:0);
       Dcl-S rows                   Int(10:0);

        // Open our SQL cursor. Use a simple select
          sqlhnd  = json_sqlOpen(
               'Select * from product'
            );

          // Was there a problem ?
          If json_Error(sqlhnd);
             msg = json_Message(sqlhnd);
          // return;  You can return, however the rest of the routines a roubust enough to just con
          EndIf;

          // Need some statisics ?
       rows = json_sqlRows(sqlhnd);    // Note this will produce a "select count(*)" and can be a l
          cols = json_sqlColumns(sqlhnd); // This is costs nothing

          // Now iterate on each row in the resultset
          // NOTE!! Start from row 10 and read ahead
          pRow  = json_sqlFetchRelative(sqlhnd: 10);
          DoW (pRow <> *NULL) ;
             ints    = json_getNum (pRow : 'PRODKEY');
             text    = json_getStr (pRow : 'PRODID');
             text    = json_getStr (pRow : 'DESC');
             text    = json_getStr (pRow : 'MANUID');
             numbers = json_getNum (pRow : 'PRICE');
             ints    = json_getNum (pRow : 'STOCKCNT');
             dates   = %date(json_getStr (pRow : 'STOCKDATE'));

            // When done with the row then always dispose it. Otherwise you will have a memory leak
             // Remember that "Fetch" will produce a new row object
             json_NodeDelete(pRow);

             // .. Now we are ready for that nex row
             pRow  = json_sqlFetchNext(sqlhnd);
          EndDo;


          // Finaly close the SQL cursor and dispose the json row object
          json_sqlClose(sqlhnd);
          json_sqlDisconnect();

          // That's it..
          *inlr = *on;


