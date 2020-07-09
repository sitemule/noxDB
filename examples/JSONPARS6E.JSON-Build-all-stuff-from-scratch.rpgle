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
       Dcl-S pTemp              Pointer;
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

          // If you do above by hand,
          // remember to "move" it  otherwise it will set a clone and leve pNewObj dangeling
          // Add an object into the to a new array element:
          pNewObj = json_ParseString('{x:456,y:"More text"}');
          json_SetValue ( pArr  : '[]' : pNewObj :json_OBJMOVE);

          // Now: Build a new object and copy it into the temp array
          // After pNewObj still have all elements
          pTemp = json_NewObject();
          json_SetValue ( pTemp : 'a' : 'A value ');
          json_SetValue ( pTemp : 'b' : 'B value ');
          json_SetValue ( pTemp : 'c' : 'C value ');
          json_SetValue ( pArr  : '[]' : pTemp  );

          // Always move object
          json_SetValue ( pJson : 'anObject': pTemp : json_OBJMOVE);

          // You can copy / clone it into an other object:
          json_SetValue ( pJson : 'emptyObject': pTemp);

          json_WriteJsonStmf  (pJson: '/prj/noxdb/testdata/build-up-6e.json':1208:*OFF);
          json_dump(pJson);
          json_delete(pJson);    // All objects created must be closed
          json_delete(pNewObj);  // All objects created must be closed
          json_delete(pTemp  );  // All objects created must be closed
          *inlr = *on;
