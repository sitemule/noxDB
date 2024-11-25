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

// Using iterator to travers arrays and objects:
// Parse Strings

// ------------------------------------------------------------- *
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
/include qrpgleRef,noxdb

   // Always set your ccsid for constants:
   json_setDelimitersByCcsid(500);

   example1();
   example2();
   example3();
   example4();
   *inlr = *ON;

// ------------------------------------------------------------------------------------
// example1
// Use iterator to travers an array
// ------------------------------------------------------------------------------------
dcl-proc example1;

   Dcl-S  pRows              Pointer;
   Dcl-S  t                  VarChar(512);
   Dcl-DS list               likeds(json_iterator);

   // return an simple array with rows
   pRows = json_sqlResultSet('-
      Select *                 -
      from noxdbdemo.icproduct -
      where manuid = ''NIKON''  -
   ');

   If json_Error(pRows) ;
      json_joblog(json_Message(pRows));
      json_delete(pRows);
      Return;
   EndIf;

   // Now print each item from the list;
   // here just the product id.
   // Note: 'this' in the iterator is the current element
   list = json_setIterator(pRows);
   DoW json_ForEach(list);
      t = json_getStr(list.this : 'prodid');
      json_joblog(t);
   EndDo;

   // Cleanup: dispose the rows in the array
   json_delete(pRows);

end-proc;
// ------------------------------------------------------------------------------------
// example2
// traverse an object.
// ------------------------------------------------------------------------------------
dcl-proc example2;

   Dcl-S pJson              Pointer;
   Dcl-S msg                VarChar(50);
   Dcl-S n                  VarChar(50);
   Dcl-S v                  VarChar(50);
   Dcl-DS list              likeds(json_iterator);

   pJson = json_ParseString ('{-
      "a" : 123,               -
      "b" : "text",            -
      "c" : "More text"        -
   }');

   If json_Error(pJson) ;
      json_joblog(json_Message(pJson));
      json_delete(pJson);
      Return;
   EndIf;

   // print the name (n) and the value(v)
   list = json_setIterator(pJson);
   DoW json_ForEach(list);
      n = json_GetName (list.this);
      v = json_getStr  (list.this);
      json_joblog('Name:' + n + ' value: ' + v );
   EndDo;

   json_delete(pJson);

end-proc;
// ------------------------------------------------------------------------------------
// example3
// Use iterators for looking up values;
// Note: The SQL where clause is more efficient, but this is for an example:
// ------------------------------------------------------------------------------------
dcl-proc example3;

   Dcl-S  pRows              Pointer;
   Dcl-S  t                  VarChar(512);
   Dcl-DS list               likeds(json_iterator);

   // return an simple array with rows
   pRows = json_sqlResultSet(
      'Select * from noxdbdemo.icproduct'
   );

   If json_Error(pRows) ;
      json_joblog(json_Message(pRows));
      json_delete(pRows);
      Return;
   EndIf;

   // "Lookup" done by iterator.
   // Note the usage of the "break"; if set the iterator stops the loop
   // and "this" contains the node where "break" was set.
   list = json_setIterator(pRows);
   DoW json_ForEach(list);
      if   json_getStr (list.this:'manuid') = 'OLYMPUS'
      and  json_getNum (list.this:'price')  > 2000;
         list.break= *ON;  // Found !! ( break the loop and dont't continue)
      endif;
   EndDo;

   // Only when "break" is *ON, the list contains "this" specific value.
   if list.break = *ON;  // Found;
      t = json_getStr(list.this : 'prodid');
      json_joblog(t);
   endif;


   // Now try somthing that does not exists
   list = json_setIterator(pRows);
   DoW json_ForEach(list);
      if   json_getStr (list.this:'manuid') = 'IBM'
      and  json_getNum (list.this:'price')  > 2000;
         list.break= *ON;  // Found !! ( break the loop and dont't continue)
      endif;
   EndDo;

   // This time it will not be *ON ( it actually will be *OFF or *NULL)
   if list.break = *ON;  // Found;
      t = json_getStr(list.this : 'prodid');
      json_joblog(t);
   endif;


   // Cleanup: dispose the rows in the array
   json_delete(pRows);

end-proc;
// ------------------------------------------------------------------------------------
// example4
// Use iterators for nested results
// ------------------------------------------------------------------------------------
dcl-proc example4;

   Dcl-S  pManufacturer      Pointer;
   Dcl-S  pProducts          Pointer;
   Dcl-s  dollar             char(1) inz(x'67');
   Dcl-DS manufacturereList  likeds(json_iterator);

   // return an simple array with rows
   pManufacturer = json_sqlResultSet(
      'Select * from noxdbdemo.icManufacturer'
   );

   // Test errors:
   If json_Error(pManufacturer) ;
      json_joblog(json_Message(pManufacturer));
      Return;
   EndIf;

   manufacturereList = json_setIterator(pManufacturer);
   DoW json_ForEach(manufacturereList  );

      pProducts = json_sqlResultSet(
         'Select * from noxdbdemo.icProduct where manuid = ' + dollar + 'manuid':
         1:  // first row
         -1: // all rows
         0:  // simple array
         manufacturereList.this  // from where to pick the key
      );
      json_MoveObjectInto (manufacturereList.this   : 'products' : pProducts );
   EndDo;

   json_WriteJsonStmf(pManufacturer:'/prj/noxdb/testout/nested.json':1208:*OFF);


on-exit;
   // Cleanup: dispose the rows in the array
   json_delete(pManufacturer);

end-proc;
