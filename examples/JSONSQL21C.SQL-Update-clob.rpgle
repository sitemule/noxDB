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
       //       text2  clob             not null with default
       //    )

       //  trace:
       //  CALL QSYS/QP0WUSRT parm('-l 2' '-c 0' 'xxxxxx')

       //  or

       //  CHGCPATRC JOBNUMBER(*CURRENT) SEV(*INFO)
       //  DSPCPATRC

       //  http://www-03.ibm.com/systems/power/software/i/db2/support/tips/clifaq.html
       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S err                    Ind;
       Dcl-S pNote1             Pointer;
       Dcl-S pNote2             Pointer;
       Dcl-S pRow               Pointer;
       Dcl-S id                 int(10);
       Dcl-S text1                 Char(32766) dim(10);
       Dcl-S text2                 Char(32766) dim(10);
     d*text1           s          32766
     d*text2           s          32766


        // Advanced: - update using json object as a row
        // This also works for BLOBS and CLOB columns

          text1 = *all'x';
          %subst (text1(1) : 1 : 15   )  = 'First clob';
          %subst (text1(10) : 1    : 1 )  = x'00';
          pNote1 = %addr(text1);

          text2 = *all'y';
          %subst (text2(1) : 1 : 15   )  = 'Next clob';
          %subst (text2(10) : 1    :  1 )  = x'00';
          pNote2 = %addr(text2);
          pRow  = json_newObject();

          json_setStr(pRow:  'title'    : 'My first note');
          json_setPtr(pRow:  'text1'    : pNote1);
          json_setPtr(pRow:  'text2'    : pNote2);

          err = json_sqlInsert  (
             'qgpl/note2'
             :pRow
          );

          id = json_sqlGetInsertId();

          // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
          json_delete (pRow);
          json_sqlDisconnect();

          // That's it..
          *inlr = *on;
