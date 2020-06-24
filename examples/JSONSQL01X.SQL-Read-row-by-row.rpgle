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
       Dcl-S sql                VarChar(512);
       Dcl-S text               VarChar(512);
       Dcl-S ints                   Int(10:0);
       Dcl-S numbers             Packed(11:2);
       Dcl-S dates                 Date;
       Dcl-S msg                VarChar(512);

        // Open our SQL cursor. Use a simple select
          sqlhnd  = json_sqlOpen('-
               Select * from faxudvdb/snq00  -
                  ');

                // Was there a problem ?
                If json_Error(sqlhnd);
                   msg = json_Message(sqlhnd);
                   json_sqlDisconnect();
          return;  // You can return, however the rest of the routines a roubust enough to just con
                EndIf;

                // Now iterate on each row in the resultset
                pRow = json_sqlFetchNext(sqlhnd);
                DoW (pRow <> *NULL );
                   ints    = json_getNum (pRow : 'PRODKEY');
                   text    = json_getStr (pRow : 'PRODID');
                   text    = json_getStr (pRow : 'DESC');
                   text    = json_getStr (pRow : 'MANUID');
                   numbers = json_getNum (pRow : 'PRICE');
                   ints    = json_getNum (pRow : 'STOCKCNT');
                   dates   = %date(json_getStr (pRow : 'STOCKDATE'));
                   json_NodeDelete(pRow); // Always dispose it before get the next - IMPORTANT
                   pRow = json_sqlFetchNext(sqlhnd);
                EndDo;


                // Finaly and always !! close the SQL cursor and dispose the json row object
                json_sqlClose(sqlhnd);
                json_sqlDisconnect();

                // That's it..
                *inlr = *on;


