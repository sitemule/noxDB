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

       // Parse json string and save it in different formats

       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb

       Dcl-S pJson              Pointer;

          pJson = json_ParseString('[           -
              {a:"Hello",b:1,c:22.7},             -
              {a:"Yes\" you can",b:2,c:3.14}      -
            ]');

          json_WriteJsonStmf(pJson: '/json_xml/out1.json': 1208: *OFF);
          json_WriteXmlStmf (pJson: '/json_xml/out1.xml' : 1208: *OFF);
          json_WriteCsvStmf (pJson: '/json_xml/out1.csv' : 1208: *OFF :
            '{ decPoint:",",  delimiter:";",  headers:true}'
          );

          json_delete(pJson);
          *inlr = *on;
