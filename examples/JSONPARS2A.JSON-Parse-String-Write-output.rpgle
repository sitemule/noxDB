       // ------------------------------------------------------------- *
       // noxDB - Not only XML. JSON, SQL and XML made easy for RPG
       // Company . . . : System & Method A/S - Sitemule
       // Design  . . . : Niels Liisberg
       //
       // Unless required by applicable law or agreed to in writing, software
       // distributed under the License is distributed on an "AS IS" BASIS,
       // WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
       //
       // Look at the header source file "QRPGLEREF" member "NOXDB"
       // for a complete description of the functionality
       //
       // When using noxDB you need two things:
       //  A: Bind you program with "NOXDB" Bind directory
       //  B: Include the noxDB prototypes from QRPGLEREF member NOXDB
       //
       // Parse json  sring and play with it
       //
       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S pJson              Pointer;
       Dcl-S pNode              Pointer;
       Dcl-S pArr               Pointer;
       Dcl-S msg                VarChar(50);
       Dcl-S tag                VarChar(50);
       Dcl-S value              VarChar(50);
       Dcl-S n                  Packed(15:2);

       pJson = json_ParseString (
            '{                                             '+
            '   "e"  :"Quote\"line1\nline2\rtab\ttabed",   '+
            '   "123":"Key can be numeric"             ,   '+
            '   "ÆØÅ":"And with national chars"            '+
            '}'
       );

       If json_Error(pJson) ;
          msg = json_Message(pJson);
          json_dump(pJson);
          json_delete(pJson);
          Return;
       EndIf;

       json_WriteJsonStmf(pJson:'/noxdb/json/dump-payload.json':1208:*OFF);
       pNode = json_locate(pJson: '/e');
       value = json_getStr  (pNode);

       // Get value for at numeric key
       value = json_getStr  (pJson: %char(123));

       // Get value for at national chars
       value = json_getStr  (pJson: 'ÆØÅ');

       json_delete(pJson);
       *inlr = *on;
