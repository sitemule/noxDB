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
       Dcl-S pJson1             Pointer;
       Dcl-S pJson2             Pointer;
       Dcl-S pNode              Pointer;
       Dcl-S pO                 Pointer;
       Dcl-S pR                 Pointer;
       Dcl-S pRcv               Pointer;
       Dcl-S pArr               Pointer;
       Dcl-S msg                VarChar(50);
       Dcl-S tag                VarChar(50);
       Dcl-S value              VarChar(50);
       Dcl-S n                   Packed(15:2);
          *inlr = *on;
          pJson1 = json_ParseString ('{a:[1,2]}');
          pJson2 = json_ParseString ('{b:[8,9]}');

          json_WriteJsonStmf (pJson1:'/prj/noxdb/testdata/json_out1.json':1208:*OFF);
          json_WriteJsonStmf (pJson2:'/prj/noxdb/testdata/json_out2.json':1208:*OFF);

          json_merge (pJson1 : pJson2 : json_DONTREPLACE);
          json_WriteJsonStmf (pJson1:'/prj/noxdb/testdata/json_merge.json':1208:*OFF);
          json_delete(pJson1);
          json_delete(pJson2);
