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
       Dcl-S msg                VarChar(50);
       Dcl-S value              VarChar(40);
       Dcl-DS list                     likeds(json_iterator);

        // List elements:
          pList = json_ParseString('["a","b","c"]');

          // Using an iterator
          list = json_setIterator(pList);
          DoW json_ForEach(list);
             value = json_GetStr (list.this );
          EndDo;

          json_delete(pList);
          *inlr = *on;
