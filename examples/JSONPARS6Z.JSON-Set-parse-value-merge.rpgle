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
       Dcl-S pJson              Pointer;
          *inlr = *on;

          // My root json
          pJson  = json_ParseString ( '{ a:99, b:77 }');

          // Set by location name (paramter 2) .. set c to 3
          json_SetInt    (pJson : 'c'  : 3 );

          // Merge object into  the root ( note the location is blank )
          // Note: value from a is replaced and d is added since modifier is "MO_MERGE_REPLACE"
          json_SetValue  (pJson : '' : '{a:1,d:4}' :json_EVAL+MO_MERGE_REPLACE);

          // Merge object into  the root ( note the location is blank )
       // Note: value from b is unchaned but e is set with "MO_MERGE_NEW" , since b exists and e do
         json_SetValue  (pJson : '' : '{b:88,e:5}' :json_EVAL+MO_MERGE_NEW    );

         // Merge object into  the root ( note the location is blank )
         // Note: value from b is changed  but f is not merged since it does not exists
         json_SetValue  (pJson : '' : '{b:2,f:66}' :json_EVAL+MO_MERGE_MATCH  );

         // Finally - add an new array to the root with two object
          json_SetValue  (pJson : 'arr1:[]' : '{x:1,y:2}' : json_EVAL);
          json_SetValue  (pJson : 'arr1:[]' : '{x:3,y:4}' : json_EVAL);

          // Write it out:
          json_WriteJsonStmf (pJson  :
             '/noxdb/json/json_out-set-By-Parse.json':1208:*OFF
          );

          // Always close
          json_delete(pJson);

