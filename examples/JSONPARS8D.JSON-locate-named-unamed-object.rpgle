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
       Dcl-S p                  Pointer;
       Dcl-S msg                VarChar(50);
       Dcl-S s                  VarChar(50);
       Dcl-S n                  VarChar(50);
       Dcl-S i                      Int(10:0);

        // First demo: find attribues which contains objects where attibutes has a value
          pJson = json_ParseString ('{e:{ -
              "a": { "x":1 , "y":"11"}, -
              "b": { "x":2 , "y":"22"}, -
              "c": { "x":3 , "y":"33"}  -
            }}');

          If json_Error(pJson) ;
             msg = json_Message(pJson);
             json_dump(pJson);
             json_delete(pJson);
             Return;
          EndIf;

          // Get the object in the array where the "x" attribute has the value of 2
          p = json_locate  (pJson : '/e[x=2]');
          n = json_getName(p); // the is the "b" object
          s = json_getStr      (p : 'y' );

          json_delete(pJson);
          // Next demo: find attribues in arrays where attibutes has a value
          pJson = json_ParseString ('{e:[ -
            { "x":1 , "y":"11"}, -
            { "x":2 , "y":"22"}, -
            { "x":3 , "y":"33"}  -
          ]}');

          If json_Error(pJson) ;
             msg = json_Message(pJson);
             json_dump(pJson);
             json_delete(pJson);
             Return;
          EndIf;

          // Get the object in the array where the "x" attribute has the value of 2
          p = json_locate  (pJson : '/e[x=2]');
          n = json_getName(p); // This object has no name since it is an element of an array
          s = json_getStr      (p : 'y' );

          *inlr = *on;
