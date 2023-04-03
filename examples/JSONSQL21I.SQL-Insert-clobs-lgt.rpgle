**FREE
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
// Using SQL. Resultsets

//  on a table like this:
//    create table noxdbdemo.NOTES3(
//       id     int generated always as Identity unique,
//       title  varchar(256)     not null with default,
//       text1  clob             not null with default,
//       text2  clob             not null with default
//    )


//  CALL QSYS/QP0WUSRT parm('-l 2' '-c 0' 'xxxxxx')

//  or

//  trace: CHGCPATRC JOBNUMBER(*CURRENT) SEV(*INFO)
//         DSPCPATRC

//  http://www-03.ibm.com/systems/power/software/i/db2/support/tips/clifaq.html
// ------------------------------------------------------------- *
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO);
Ctl-Opt actgrp('QTERASPACE') stgmdl(*TERASPACE);

/include qrpgleRef,noxdb

Dcl-S err              Ind;
Dcl-S pRow             pointer;
Dcl-S id               int(20);
Dcl-S i                int(20);
Dcl-S mem              int(20);
Dcl-s pRes             pointer;
Dcl-s pPayload         pointer;
Dcl-s pPayWork         pointer;
Dcl-S payload          Char(1000) based(pPayWork);
Dcl-S payloadChar      Char(1)    based(pPayWork);

   // Example of storing 16M clob data

   json_sqlExec ('-
      create or replace table noxdbdemo.clobs ( -
         id       int generated always as Identity primary key, -
         payload  clob (16M) -
      ) -
   ');
   json_sqlExec ('truncate  noxdbdemo.clobs');

   pRow     = json_newObject();

   // Get 16M of memory ( its hard to work on that size with 7.2)
   mem = 1000000000;
   pPayload  = %alloc(mem);
   for i= 1 to mem by 1000;
      pPayWork = pPayload + (i -1);
      payload = *All'x';
   endfor;
   pPayWork = pPayload + (mem -1);
   payloadChar = x'00';

   json_setStr   (pRow   :'payload': pPayload);

   err = json_sqlInsert  (
      'noxdbdemo.clobs'
      :pRow
   );

   // What is the size written?
   pRes = json_sqlResultRow ('-
      Select id, length(payload) length_of_clob -
      from noxdbdemo.clobs -
   ');

   json_joblog(pRes);
   json_delete(pRes);

   // update the row with all "y"
   // Get 16M of memory ( its hard to work on that size with 7.2)
   mem = 1000000000;
   for i= 1 to mem by 1000;
      pPayWork = pPayload + (i -1);
      payload = *All'y';
   endfor;
   pPayWork = pPayload + (mem -1);
   payloadChar = x'00';

   json_setStr   (pRow   :'payload': pPayload);

   json_sqlUpdate(
      'noxdbdemo.clobs':
      pRow:
      '1=1' // Update always need a where clause
   );

   // Save the data CLOB to stream file in JSON format:
   pRes = json_sqlResultRow ('-
      Select payload  -
      from noxdbdemo.clobs -
   ');

   json_WriteJsonStmf(pRes: '/prj/noxdb/testout/hugeclob.json':1208:*OFF);

   // Done - cleanup
   json_sqlExec ('drop table noxdbdemo.clobs');

   // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
   DeAlloc pPayload  ;
   json_delete(pRow);
   json_delete(pRes);
   json_sqlDisconnect();

   // That's it..
   *inlr = *on;
