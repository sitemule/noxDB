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

// Note this code utlize the IceBreak ILOB's
// Internal Large Objects.

//  CALL QSYS/QP0WUSRT parm('-l 2' '-c 0' 'xxxxxx')

//  or

//  trace: CHGCPATRC JOBNUMBER(*CURRENT) SEV(*INFO)
//         DSPCPATRC

//  http://www-03.ibm.com/systems/power/software/i/db2/support/tips/clifaq.html
// ------------------------------------------------------------- *
Ctl-Opt BndDir('NOXDB':'ICEBREAK') dftactgrp(*NO);
Ctl-Opt actgrp('QTERASPACE') stgmdl(*TERASPACE);

/include qrpgleRef,noxdb
/include qasphdr,ilob


Dcl-S err              Ind;
Dcl-S pRow             pointer;
Dcl-S id               int(20);
Dcl-S i                int(20);
Dcl-S mem              int(20);
Dcl-s pRes             pointer;
Dcl-s pPayload         pointer;
Dcl-s pPayWork         pointer;
Dcl-s pMsgIlob         pointer;
Dcl-S payload          Char(1000) based(pPayWork);
Dcl-S payloadChar      Char(1)    based(pPayWork);
dcl-s filePath         varchar(256) inz('/prj/noxdb/testout/demo-nested.xml');

   // Example of storing 16M clob data

   json_sqlExec ('-
      create or replace table noxdbdemo.clobs ( -
         id       int generated always as Identity primary key, -
         payload  clob (16M) -
      ) -
   ');
   json_sqlExec ('truncate  noxdbdemo.clobs');

   pRow     = json_newObject();

   // Load the stream-file into a ILOB
   pMsgIlob = ilob_new();
   ilob_loadFromBinaryStream(pMsgIlob:filePath);
   if pMsgIlob = *NULL;
      json_joblog('File not found' + filePath );
      return;
   endif;

   // Data in running job CCSID
   ilob_xlate(pMsgIlob: ilob_getCcsid(pMsgIlob): 0);
   // Ensure the pMsgIlob will be a C-compatible string (zeroterminate it)
   ilob_setLength(pMsgIlob:ilob_getLength(pMsgIlob));
   // Update row with ILOB
   json_setStr(pRow : 'payload' : pMsgIlob);
   ilob_delete(pMsgIlob);

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

   // Done - cleanup
   //json_sqlExec ('drop table noxdbdemo.clobs');

   // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
   DeAlloc pPayload  ;
   json_delete(pRow);
   json_delete(pRes);
   json_sqlDisconnect();

   // That's it..
   *inlr = *on;
