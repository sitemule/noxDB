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

       // Parse Strings

       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S pJson              Pointer;
       Dcl-S msg                VarChar(50);
       Dcl-S n                  VarChar(50);
       Dcl-S v                  VarChar(50);
       Dcl-DS list                     likeds(json_iterator);
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

          list = json_setIterator(pJson);
          DoW json_ForEach(list);
             n = json_GetName (list.this);
             v = json_getStr  (list.this);
          EndDo;

          json_delete(pJson);
          *inlr = *on;
