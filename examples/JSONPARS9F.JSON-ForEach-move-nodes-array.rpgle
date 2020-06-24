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
       Dcl-S pList              Pointer;
       Dcl-S pB                 Pointer;
       Dcl-S msg                VarChar(50);
       Dcl-S res                VarChar(1024);
       Dcl-S name               VarChar(10);
       Dcl-S value              VarChar(40);
       Dcl-DS list                     likeds(json_iterator);
        // Move elemet "b" out into a new object
          pList = json_ParseString('[{a:1}, {b:2}, {c:3 }]');

          If json_Error(pList) ;
             msg = json_Message(pList);
             json_dump(pList);
             json_delete(pList);
             Return;
          EndIf;

          list = json_setIterator(pList);
          DoW json_ForEach(list);
             name = json_GetName(json_locate(list.this:'[0]'));
             If name  = 'b';
                pB = json_newObject();
                json_MoveObjectInto (pb : 'AsNewB' : list.this);
             EndIf;
          EndDo;

          // res - without "b"
          res  = json_asJsonText(pList);

          // res - with then new "b"
          res  = json_asJsonText(pB   );

          json_delete(pList);
          *inlr = *on;
