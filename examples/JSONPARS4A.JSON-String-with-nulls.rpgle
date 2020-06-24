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
       Dcl-S msg                VarChar(50);
       Dcl-S tag                VarChar(50);
       Dcl-S value              VarChar(50);
       Dcl-S n                   Packed(15:2);
          pJson = json_ParseString (
               '{  u:"This is a unicode \u00b5 string"  ,   '+
               '   "s":null                             ,   '+
               '   a:[1,2,3],                   ' +
               '   o:{           ' +
               '     n:123   , ' +
               '     a:[10 , 20 , 30 ],                ' +
               '     m:"yyyy"  ' +
               '   }         '+
               '}'
                 : '');
          If json_Error(pJson) ;
             msg = json_Message(pJson);
             json_dump(pJson);
             json_delete(pJson);
             Return;
          EndIf;

          pNode = json_locate(pJson: '/o/n');
          n     = json_getNum     (pNode);

          pNode = json_locate(pJson: '/a[1]');
          n     = json_getNum     (pNode);

          pNode = json_locate(pJson: '/s');
          value = json_getStr(pNode);

          pNode = json_locate(pJson: '/u');
          value = json_getStr(pNode);

          pNode = json_locate(pJson: '/o/a[2]');
          n     = json_getNum     (pNode);

          // Loop on the array
          pArr  = json_locate(pJson: '/o/a[0]'); // First array element
          DoW (pArr <> *NULL) ;
             n     = json_getNum     (pArr);
             pArr  = json_getNext(pArr);
          EndDo;

          // Get Value directly
          value = json_getStr(pJson : '/u');

          // Get Value directly relative
          pNode = json_locate(pJson: '/o');
          value = json_getStr(pNode : 'n');   // This is "n" in "o"
          json_delete(pJson);
          *inlr = *on;
