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

       // Parse json string and play with it

       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S pJson              Pointer;
       Dcl-S abc                VarChar(256);
       Dcl-S b                  VarChar(256);
       Dcl-S c                  VarChar(256);

          pJson = json_ParseString (
               '{  +
                   "a.b.c":"Text for a.b.c." +
                }'
             );

          // Not found - since the '.' is ne notation for "member of"
          abc  = json_getStr(pJson: 'a.b.c');

          // Now replace the  '.' notation with a |
          json_setDelimiters('/\@[] |');

          // Works  !!
          abc  = json_getStr(pJson: 'a.b.c');

          // Done
          json_delete(pJson);
          *inlr = *on;
