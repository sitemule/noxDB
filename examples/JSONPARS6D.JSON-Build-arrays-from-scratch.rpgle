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

       // Produce json from scratch


       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S pJson              Pointer;
       Dcl-S pArr               Pointer;
       Dcl-S pNewObj            Pointer;
       Dcl-S msg                VarChar(50);
          pJson = json_NewObject();
          json_SetValue ( pJson : 'items[]': '10'); // add to the tail of items
          json_SetValue ( pJson : 'items[]': '20'); // add to the tail of items
          json_SetValue ( pJson : 'items[]': '30'); // add to the tail of items

          // Now add relative
          pArr = json_locate(pJson : 'items');
          json_SetValue ( pArr  : '[]': '40'); // add to the tail of items
          json_SetValue ( pArr  : '[]': '50'); // add to the tail of items

          // Evaluate a json string into a new array element:
         json_SetValue ( pArr  : '[]' :  // Empty array causes a new element to be added in the end
             '{a:123,b:"Some text"}' :    // A JSON object string
             json_EVAL                    // add to the tail of items
          );

          // Add an object into the to a new array element:
          pNewObj = json_ParseString('{x:456,y:"More text"}');
          json_SetValue ( pArr  : '[]' : pNewObj);

       // Add a object with a numeric value. This can lead to confusion since each SetValue makes a
          json_SetValue     ( pJson  : 'otherArray[].name': 'John');
          json_SetValue     ( pJson  : 'otherArray[].name': 'Albert');

          json_WriteJsonStmf (pJson  : '/prj/noxDB_out.json' : 1208 : *OFF);
          json_dump(pJson);
          json_delete(pJson);    // All objects created must be closed
          json_delete(pNewObj);  // All objects created must be closed
          *inlr = *on;
