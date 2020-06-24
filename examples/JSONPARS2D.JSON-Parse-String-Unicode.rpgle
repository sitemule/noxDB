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

       // Parse json  string and play with it

       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S pJson              Pointer;
       Dcl-S a                  VarChar(256);
       Dcl-S b                  VarChar(256);
       Dcl-S c                  VarChar(256);

        // u00b5 is "Micro sign" and exists in ebcdic
        // u2318 is "sight of interest" icon and have no equvalent in ebedic so
        // \u2318 will be un touched in the input string
          pJson = json_ParseString (
               '{  +
                   a:"A native unicode \u00b5 string",    +
                   b:"A not native unicode \u2318 string",  +
                   c:"Escaped \\ string \"  data "        +
                }'
             );

          a  = json_getStr(pJson: 'a');
          b  = json_getStr(pJson: 'b');
          c  = json_getStr(pJson: 'c');
          json_WriteJsonStmf( pJson:
              '/noxdb/json/unicode-strings.json': 1208 : *OFF);
          json_delete(pJson);
          *inlr = *on;
