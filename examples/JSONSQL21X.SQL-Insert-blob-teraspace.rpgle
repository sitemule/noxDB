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



       //  CALL QSYS/QP0WUSRT parm('-l 2' '-c 0' 'xxxxxx')

       //  or

       //  trace: CHGCPATRC JOBNUMBER(*CURRENT) SEV(*INFO)
       //         DSPCPATRC

       //  http://www-03.ibm.com/systems/power/software/i/db2/support/tips/clifaq.html
       // ------------------------------------------------------------- *
     H*BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QTERASPACE')
     H*STGMDL(*TERASPACE)
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S err                    Ind;
       Dcl-S pNote1             Pointer;
       Dcl-S pNote2             Pointer;
       Dcl-S pRow               Pointer;
       Dcl-S id                 int(10);
       Dcl-S text1                 Char(32766);
       Dcl-S text2                 Char(32766) based(pNote2);


        // Advanced: - update using json object as a row
        // This also works for BLOBS and CLOB columns

          text1 = *all'x';
          %subst (text1    : 1 : 15    )  = 'First blob';
          %subst (text1    : 32000: 1  )  = x'00';
          pNote1 = %addr(text1);

          // With alloc
          pNote2 = %alloc(66000);
          text2 = *all'y';
          %subst (text2    : 1 : 15    )  = 'Next blob';
          %subst (text2    : 32000 : 1 )  = x'00';
          pRow  = json_newObject();

          json_setStr(pRow:  'NTFSBJ'   : 'My first note');
          json_setPtr(pRow:  'NTFMSG'   : pNote2);

          err = json_sqlInsert  (
             'basdevdb/WSHNTFTR00'
             :pRow
          );
          id = json_sqlGetInsertId();
          DeAlloc pNote2  ;

          // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
          json_delete(pRow);
          json_sqlDisconnect();

          // That's it..
          *inlr = *on;
