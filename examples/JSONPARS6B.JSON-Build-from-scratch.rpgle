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
       Dcl-S pNode              Pointer;
       Dcl-S pO                 Pointer;
       Dcl-S pR                 Pointer;
       Dcl-S pRcv               Pointer;
       Dcl-S pArr               Pointer;
       Dcl-S msg                VarChar(50);
       Dcl-S tag                VarChar(50);
       Dcl-S value              VarChar(50);
       Dcl-S n                   Packed(15:2);
          pJson = json_newObject();
          json_SetValue ( pJson : '/o/a[0]': '10');
          json_SetValue ( pJson : '/o/a[1]': '20');

          po = json_Locate   ( pJson : '/o/a') ;  // The array it self
          value = json_getStr ( po : '[UBOUND]');
          json_SetValue ( po    : '[3]': '30');
          value = json_getStr ( po : '[UBOUND]');
          json_SetValue ( po    : '[UBOUND]': '40'); // This will not work !!!
          value = json_getStr ( po : '[UBOUND]'); // So UBOUND is still 3
          json_WriteJsonStmf (pJson: '/noxdb/json_out.json' : 1208 : *OFF);
          json_dump(pJson);
          json_delete(pJson);
          *inlr = *on;
