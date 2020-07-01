**free
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
         // Basic features example: build, save, load manipulate JSON
         // Not will only compile on >= 7.4 
         //
         // Step 1)
         // When using noxDB you need two things:
         //  A: Bind you program with "NOXDB" Bind directory
         //  B: Include the noxDB prototypes from QRPGLEREF member NOXDB
         //
         // Step 2)
         // Include the prototypes for noxDB and bind with bibddir NOXDB
         //
         // Step 3)
         // Now you can use all the JSON, SQL and XML features
         //
         // Step 4)
         // Finally remember to cleanup otherwise you will have a memory leak
         // ------------------------------------------------------------- *
         Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
         /include qrpgleRef,noxdb

         Dcl-S pJson       Pointer;
         // ------------------------------------------------------------- *
         *inlr = *on;

         // First list build a simple JSON file
         // Let start with an object: 
         pJson = json_newObject();

         // Now lets place some elements in that object:
         // Note: we use all the basic datatype in RPG
         // The "Set" procedure is "overloaded" to all types:
         json_set(pJson: 'name' : 'John');
         json_set(pJson: 'age' : 23);
         //json_set(pJson: 'birthDate' : d'1997-02-16');
         json_set(pJson: 'income' : 2345.67);
         json_set(pJson: 'updated' : %timestamp());
         json_set(pJson: 'isMale' : *ON);

         // Write to the IFS, 
         json_WriteJsonStmf(pJson:'/prj/noxdb/testdata/simple0.json':1208:*OFF);

         // And always remember to cleanup
         json_delete (pJson);
