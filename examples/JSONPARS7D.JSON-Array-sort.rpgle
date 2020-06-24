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

       // Join an array and return is as string

       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S pJson              Pointer;

          *inlr = *on;

          // Simple - on column
          pJson = json_ParseString ('                          -
               [                                               -
                  { key: "d" , value : 4 },                    -
                  { key: "c" , value : 3 },                    -
                  { key: "b" , value : 2 },                    -
                  { key: "a" , value : 1 }                     -
               ]                                               -
          ');

          // Sort the array after the key field
          json_arraySort(pJson : 'key' );

          // save as new file
          json_WriteJsonStmf(pJson : '/json_xml/sample7D1.json' : 1208 : *OFF);

          json_delete(pJson);

          // Multiple keys
          pJson = json_ParseString ('                          -
               [                                               -
                  { keya: "b" , keyb:  2  , value : 5 },        -
                  { keya: "b" , keyb:  1  , value : 4 },        -
                  { keya: "a" , keyb:  -5 , value : 3 },        -
                  { keya: "a" , keyb:  0  , value : 2 },        -
                  { keya: "a" , keyb:  2  , value : 1 }         -
               ]                                               -
          ');

          // Sort the array after the key field
          json_arraySort(pJson : 'keya:ASC,keyb:DESC' );

          // save as new file
          json_WriteJsonStmf(pJson : '/json_xml/sample7D2.json' : 1208 : *OFF);

          json_delete(pJson);

       // Multiple keys: Numeric in strings and in locale format, formattet and with leading blanks
          // use the jx_setDecpoint to setup the locale for decimal point
          json_SetDecPoint(',');
          pJson = json_ParseString ('                          -
               [                                               -
                  {  key :  " 2.000,55"  , value : 5 },        -
                  {  key :  " 1000 "     , value : 4 },        -
                  {  key :  " -5 "       , value : 1 },        -
                  {  key :  " 0 "        , value : 2 },        -
                  {  key :  7            , value : 3 }         -
               ]                                               -
          ');

          // Sort the array after the key field
          json_arraySort(pJson : 'key:ASC'  : json_USE_LOCALE  );

          // save as new file
          json_WriteJsonStmf(pJson : '/json_xml/sample7D3.json' : 1208 : *OFF);

          json_delete(pJson);
