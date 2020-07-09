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
          json_SetValue ( pJson : '/o/a[0]':
            '{x:123,y:456}': json_EVAL );
          json_SetValue ( pJson : '/o/a[1]':
            '{x:444,y:555}': json_EVAL );
          json_SetValue ( pJson : '/o/e':
            '{s:"a",t:"b"}': json_EVAL );

          json_SetValue ( pJson : '/o/arr':
            '[1,2,3,4,5,6]': json_EVAL );

          json_WriteJsonStmf(pJson:'/prj/noxDB_out.json' : 1208 : *OFF);
          json_delete(pJson);
          *inlr = *on;
