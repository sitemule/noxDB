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

       // Parse Strings

       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S root               Pointer;
       Dcl-S a                  Pointer;
       Dcl-S b                  Pointer;
       Dcl-S c                  Pointer;
          *inlr = *on;

          // My root json
          root = json_newObject();

          a   = json_newObject();
          json_SetValue  (a  : 'a'  : 'a has a value');

          b   = json_newObject();
          json_SetValue  (b  : 'b'  : 'b has a value');

          c   = json_newObject();
          json_SetValue  (c  : 'c'  : 'c has a value');

          json_MoveObjectInto(root : 'e1' : a);
          json_MoveObjectInto(root : 'e2' : b);
          json_MoveObjectInto(root : 'e3' : c);

          // result in:
          //  {
          //     e1:{
          //        a : 'a has a value'
          //     }
          //     e2:{
          //        b : 'b has a value'
          //     }
          //     e3:{
          //        b : 'b has a value'
          //     }
          //  }
          //

          // Write it out:
          json_WriteJsonStmf (root  :
             '/prj/noxdb/testdata/abc-object1.json':1208:*OFF
          );


          // Always close  - p1 contains everything after the move
          json_delete(root );

