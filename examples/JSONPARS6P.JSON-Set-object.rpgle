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
       Dcl-S pText              Pointer;
          *inlr = *on;

          // My root json
          pJson  = json_ParseString (' -
              { text: { da: "Danish" , en: "English" }, -
                 abc: "123"   -
              }  -
          ');
          json_SetValue  (pJson : 'mix'  : 'Yes');

          pText  = json_ParseString ( '{ sv: "Swe"                 }');

          // Set by location name
          json_SetValue  (pJson : 'text'  : pText : json_OBJCOPY );


          // Write it out:
          json_WriteJsonStmf (pJson  :
             '/noxdb/json/json_out-set-value-to-object.json':1208:*OFF
          );

          // Write it out:
          json_WriteJsonStmf (pText  :
             '/noxdb/json/json_out-ptext.json':1208:*OFF
          );

          // Always close
          json_delete(pText);
          json_delete(pJson);

