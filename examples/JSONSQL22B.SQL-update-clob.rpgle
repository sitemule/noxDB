       // ------------------------------------------------------------- *
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
       //
       // When using noxDB you need two things:
       //  A: Bind you program with "NOXDB" Bind directory
       //  B: Include the noxDB prototypes from QRPGLEREF member NOXDB
       //
       // ------------------------------------------------------------- *
       // Using SQL. Resultsets
       //
       //
       //  CALL QSYS/QP0WUSRT parm('-l 2' '-c 0' 'xxxxxx')
       //
       //  or
       //
       //  trace: CHGCPATRC JOBNUMBER(*CURRENT) SEV(*INFO)
       //         DSPCPATRC
       //
       //  http://www-03.ibm.com/systems/power/software/i/db2/support/tips/clifaq.html
       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S err                    Ind;
       Dcl-S pRow               Pointer;
       Dcl-S id                 int(10);
       Dcl-S x                  int(10);
       Dcl-S i                  int(10);
       Dcl-S text               Char(100000);
       Dcl-S msg                VarChar(256);


       text  = *all'*';
       x = 1;
       For i = 1 to 8000;
          %subst (text     : x : 10    )  = x'0d25' + %char(i);
          x += 10;
       EndFor;

       pRow  = json_newObject();
       id = 2;
       json_setInt(pRow:  'SDTTKN'   : id   );
       json_setStr(pRow:  'SDTDSC'   : 'Loan Document 1');
       json_setStr(pRow:  'SDTFPPDF' : '' );
       json_setInt(pRow:  'SDTCBY'   : 161  );
       json_setStr(pRow:  'SDTCTS'   : '2018-07-31-15.25.34.724244');
       json_setStr(pRow:  'SDTTXT'   : text );

       err = json_sqlUpdate  (
          'qgpl.samples'
          :pRow
          :'SDTTKN = ' + %char(id)
       );
       If err;
          msg = json_Message(*NULL);
          json_delete(pRow);
          json_sqlDisconnect();
       EndIf;

       // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
       json_delete(pRow);
       json_sqlDisconnect();

       // That's it..
       *inlr = *on;
