       // -------------------------------------------------------------
       // noxDB - Not only XML. JSON, SQL and XML made easy for RPG
       //
       // Company . . . : System & Method A/S - Sitemule
       // Design  . . . : Niels Liisberg
       //
       // Unless required by applicable law or agreed to in writing, software
       // distributed under the License is distributed on an "AS IS" BASIS,
       // WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
       //
       // Look at the header source file "QRPGLEREF" member "NOXDB"
       // for a complete description of the functionality
       // ------------------------------------------------------------- *
       //
       // Using SQL cursors
       //
       //  on a table like this:
       //    create table QGPL/NOTES (
       //       id     int generated always as Identity,
       //       title  varchar(256)     not null with default,
       //       text1  blob             not null with default,
       //       text2  blob             not null with default
       //    )
       //
       //  trace: CHGCPATRC JOBNUMBER(*CURRENT) SEV(*INFO)
       //         DSPCPATRC
       //
       //  http://www-03.ibm.com/systems/power/software/i/db2/support/tips/clifaq.html
       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('JSONPARSER') dftactgrp(*NO) ACTGRP('QILE' );

       Dcl-S err                    Ind;
       Dcl-S pNote1             Pointer;
       Dcl-S pNote2             Pointer;
       Dcl-S pRow               Pointer;
       Dcl-S id                 int(10);

      /include qrpgleRef,noxdb

        // Advanced: - update using json object as a row
        // This also works for BLOBS and CLOB columns

          pRow  = json_newObject();
          json_setStr(pRow:  'title'    : 'My first note');
          json_setStr(pRow:  'text1'    : '{a:123}');

          err = json_sqlInsert  (
             'qgpl/notes'
             :pRow
          );
          id = json_sqlGetInsertId();

          // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
          json_delete(pRow);
          json_sqlDisconnect();

          // That's it..
          *inlr = *on;
