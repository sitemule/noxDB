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
       Dcl-S pJsonTemp          Pointer;
       Dcl-S msg                VarChar(50);
          *inlr = *on;
          pJson  = json_NewObject();

          pJsonTemp = json_ParseString (
            '{"__cid__":1,"backgroundcolor":"#4400FF","design":"rl"}');
          json_merge (pJson  : pJsonTemp : json_DONTREPLACE);
          json_delete(pJsonTemp);

          pJsonTemp = json_ParseString (
            '{"__cid__":13,"name":"Den første stakside"}');
          json_merge (pJson  : pJsonTemp : json_DONTREPLACE);
          json_delete(pJsonTemp);


          json_WriteJsonStmf (pJson:'/noxdb/json/json_merge2.json':1208:*OFF);
          json_delete(pJson);
