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
       // Using SQL cursors. Resultsets

       //  on a table like this:
       //    create table QGPL/NOTE2 (
       //       id     int generated always as Identity,
       //       title  varchar(256)     not null with default,
       //       text1  clob             not null with default,
       //       text2  clob             not null with default,
       //       canBeNull char(1)
       //    )

       //  CALL QSYS/QP0WUSRT parm('-l 2' '-c 0' 'xxxxxx')

       //  or

       //  trace: CHGCPATRC JOBNUMBER(*CURRENT) SEV(*INFO)
       //         DSPCPATRC

       //  http://www-03.ibm.com/systems/power/software/i/db2/support/tips/clifaq.html
       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S err                    Ind;
       Dcl-S row                VarChar(32766);
       Dcl-S pRow               Pointer;
       Dcl-S id                 int(10);


        // insert - not subsequent object a serialized into the blobs / clobs
          pRow = json_parseString ('{-
               title: "tesing",                             -
               text1: {da:"Dansk Tekst" , en:"English"}     -
            }');

          err = json_sqlInsert  (
             'qgpl/note2'
             :pRow
          );

          json_delete(pRow);

          // get ret unique ID generated
          id = json_sqlGetInsertId();

        // now get that row: here we use the a stringed object to build the where statement via the
          pRow = json_sqlResultRow (('  -
                Select * from qgpl/note2  -
                      where id = $id           -
                   ')
                   :'{id:' + %char(id) +'}'
                );

                // manipulate data:
                json_setStr(pRow : 'text1.fr' : 'aussi en français');
                err = json_sqlUpdate(
                   'qgpl/note2'
                   :pRow                // the text object is updated with a extra tag
           :'where  id = $id'   // the where uses atemplate to the id, and the ide is retrived from
                   :pRow
                );

                // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
                json_delete(pRow);
                json_sqlDisconnect();

                // That's it..
                *inlr = *on;
