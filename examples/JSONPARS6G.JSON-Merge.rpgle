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
       Dcl-S p1                 Pointer;
       Dcl-S p2                 Pointer;
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
          *inlr = *on;

          p1  = json_ParseString ('  -
              {  a: 1,               -
                 b: 2                -
              }                      -
          ');
          p2  = json_ParseString ('  -
              {  c: 3,               -
                 d: 4                -
              }                      -
          ');

          json_mergeObjects (p1 : p2 : json_DONTREPLACE);
          json_WriteJsonStmf(p1:'/prj/noxdb/testdata/json-merge1.json':1208:*ON);
          json_delete(p1   );
          json_delete(p2   );


          // Yet more advanced
          pJson = json_ParseString (
             '{  u:"This is a unicode \u00b5 string"  ,   '+
             '   "s":"abc"                            ,   '+
             '   a:[1,2,3],                   ' +
             '   o:{           ' +
             '     n:123   , ' +
             '     a:[10 , 20 , 30 ],                ' +
             '     b:[10 , 20 , 30 ],                ' +
             '     c:[[1,2],[3,4]],                ' +
             '     m:"yyyy", ' +
             '     o2:{           ' +
             '      x:345   , ' +
             '      y:345     ' +
             '     }         '+
             '   }         '+
             '}'
               : '');
          If json_Error(pJson) ;
             msg = json_Message(pJson);
             json_dump(pJson);
             json_delete(pJson);
             Return;
          EndIf;
          pRcv  = json_ParseString (
             '{  r: {                                     '+
             '     o: {                                     '+
             '       n:"Do not overwrite me"    ' +
             '     }' +
             '   }' +
             '}'
               : '');
          If json_Error(pRcv ) ;
             msg = json_Message(pRcv );
             json_dump(pRcv );
             json_delete(pRcv );
             Return;
          EndIf;

          pO    = json_locate(pJson: '/o');
          pR    = json_locate(pRcv : '/r');
          json_merge (pR : pO : json_DONTREPLACE);
          json_dump(pRcv );
          json_WriteJsonStmf(pR:'/prj/noxdb/testdata/json_out.json':1208:*OFF);
          json_delete(pJson);
          json_delete(pRcv );
