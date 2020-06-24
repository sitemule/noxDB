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
       Dcl-S pNode              Pointer;
       Dcl-S pO                 Pointer;
       Dcl-S pR                 Pointer;
       Dcl-S pRcv               Pointer;
       Dcl-S pArr               Pointer;
       Dcl-S pKey               Pointer;
       Dcl-S msg                VarChar(50);
       Dcl-S tag                VarChar(50);
       Dcl-S value              VarChar(50);
       Dcl-S n                   Packed(15:2);

          pJson = json_ParseString (
               '{                      '+
               '  a:123,               '+
               '  b:"text",            '+
               '  c:"More text"        '+
               '}'
                 : '');
          If json_Error(pJson) ;
             msg = json_Message(pJson);
             json_dump(pJson);
             json_delete(pJson);
             Return;
          EndIf;
          pRcv  = json_newObject();

          pO = json_SetValue(pRcv : '/row' : pJson: json_OBJREPLACE);

          pKey  = json_ParseString ('{ key: "123" }');
          pO = json_SetValue(pRcv : '/key' : pKey : json_OBJREPLACE);

          json_dump(pRcv );
          json_WriteJsonStmf(pRcv:'/noxdb/json_out.json':1208:*OFF);
          json_delete(pJson);
          json_delete(pKey );
          json_delete(pRcv );
          *inlr = *on;
