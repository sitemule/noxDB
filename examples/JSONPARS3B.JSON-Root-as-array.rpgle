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
       Dcl-S pArr               Pointer;
       Dcl-S e                  Pointer;
       Dcl-S msg                VarChar(50);
       Dcl-S tag                VarChar(50);
       Dcl-S s                  VarChar(50);
       Dcl-S n                  VarChar(50);
       Dcl-S v                  VarChar(50);
       Dcl-S i                      Int(10:0);
          pJson = json_ParseFile ('/noxdb/json/demo2.json':'');

          If json_Error(pJson) ;
             msg = json_Message(pJson);
             Dsply msg;
             json_dump(pJson);
             json_delete(pJson);
             Return;
          EndIf;


          // Loop on the array
          pArr  = json_locate(pJson: '/[0]'); // First array element
          DoW (pArr <> *NULL) ;
             // Loop all elements in that array element
             e  = json_GetChild (pArr);
             DoW (e  <> *NULL) ;
                n =  json_getName  (e);
                v =  json_getStr   (e);
                e  = json_GetNext  (e);
             EndDo;
             pArr  = json_getNext(pArr);
          EndDo;

          json_dump(pJson);
          json_delete(pJson);
          *inlr = *on;
