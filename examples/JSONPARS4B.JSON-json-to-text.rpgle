**free
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
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') main(main);
/include qrpgleRef,noxdb

// ------------------------------------------------------------------------------------
// main
// ------------------------------------------------------------------------------------
dcl-proc main;

   Dcl-S pJson              Pointer;
   Dcl-S pNode              Pointer;
   Dcl-S pArr               Pointer;
   Dcl-S msg                VarChar(50);
   Dcl-S tag                VarChar(50);
   Dcl-S value              VarChar(50);
   Dcl-S jsonText           VarChar(32768);
   Dcl-S jsonText16M         like(VARCHAR16M);
   Dcl-S n                  Packed(15:2);

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
      Return;
   EndIf;

   json_WriteJsonStmf(pJson : '/prj/noxdb/testout/josn_to_text.json' : 1208 : *OFF);


   // up to 32K
   jsonText= json_asJsonText(pJson);

   // 16MEG
   jsonText16M= json_AsJsonText16M(pJson);



   return;

on-exit;
   json_delete(pJson);

end-proc;
