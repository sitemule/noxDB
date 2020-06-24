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
       // Using SQL - disconnect


       //  trace:
       //  CALL QSYS/QP0WUSRT parm('-l 2' '-c 0' 'xxxxxx')

       //  or

       //  CHGCPATRC JOBNUMBER(*CURRENT) SEV(*INFO)
       //  DSPCPATRC

       //  http://www-03.ibm.com/systems/power/software/i/db2/support/tips/clifaq.html
       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
       Dcl-S pConnect           Pointer;
      /include qrpgleRef,noxdb

          pConnect = json_sqlConnect();

          // Note !! When you use noxDB in IceBreak, please note that icebreak delivers a
          // connection, so if you disconnect - you disconnects all subsequent
          // icebreak jobs - so handle with care and avoid disconnecting
          json_sqlDisconnect();

          // That's it..
          *inlr = *on;
