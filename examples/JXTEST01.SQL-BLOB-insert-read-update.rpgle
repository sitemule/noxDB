       //  -------------------------------------------------------------
       //  noxDB - Not only XML. JSON, SQL and XML made easy for RPG
       //
       //  Company . . . : System & Method A/S - Sitemule
       //  Design  . . . : Niels Liisberg
       //
       //  Unless required by applicable law or agreed to in writing, software
       //  distributed under the License is distributed on an "AS IS" BASIS,
       //  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
       //
       //  Look at the header source file "QRPGLEREF" member "NOXDB"
       //  for a complete description of the functionality
       // ------------------------------------------------------------- *
       //
       // Using SQL cursors
       //
       //  on a table like this:
       //    create table QGPL/NOTE2 (
       //       id     int generated always as Identity primary key,
       //       title  varchar(16)      not null with default,
       //       text1  clob with default,
       //       text2  clob with default,
       //       num    int not null with default,
       //       mydate  date not null with default
       //    )
       //
       //  trace: CHGCPATRC JOBNUMBER(*CURRENT) SEV(*INFO)
       //         DSPCPATRC
       //
       //  http://www-03.ibm.com/systems/power/software/i/db2/support/tips/clifaq.html
       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('JSONPARSER') dftactgrp(*NO) ACTGRP('QILE' );

       Dcl-S err                    Ind;
       Dcl-S row                VarChar(32766);
       Dcl-S pRow               Pointer;
       Dcl-S id                 int(10);

       /include qrpgleRef,noxdb


       // insert - note: subsequent object a serialized into the blobs / clobs
       row = ('{ -
            title: "testing",                             -
            text1: {da:"Dansk Tekst" , en:"English"}     -
         }');

       err = json_sqlInsert  (
          'qgpl/note2'
          :row
       );

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
       json_setInt(pRow : 'num'      : 123.56 );
       err = json_sqlUpdate(
          'qgpl/note2'
          :pRow                // the text object is updated with a extra tag
          :'where  id = $id'   // the where uses a template to the id, and the id is retrived from
          :pRow
       );

       // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
       json_delete(pRow);
       json_sqlDisconnect();

       // That's it..
       *inlr = *on;
