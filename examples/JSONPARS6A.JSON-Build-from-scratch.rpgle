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

       // Build a json object with primitive types and write
       // is as astream file to the IFS in UTF-8 format

       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S pJson              Pointer;

        // Creat a empty root object
          pJson = json_NewObject();

          // add new elements to the object
          json_SetInt    (pJson : 'a'  : 1 );
          json_SetDec    (pJson : 'b'  : 12.34);
          json_SetDec    (pJson : 'c'  : 123);
          json_SetDec    (pJson : 'pi' : 22/7); // 3.147.... infinit
          json_SetBool   (pJson : 'ok' : 2>1);  // true
          json_SetStr    (pJson : 's'  : 'Hello world');  // String

          // Write it out:
          json_WriteJsonStmf (pJson  :
             '/prj/noxdb/testdata/Simple-1.json':1208:*OFF
          );
          json_delete(pJson);
          *inlr = *on;
