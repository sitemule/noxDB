**free
// -------------------------------------------------------------
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

// Copy values or arrays or objects
// Move values or arrays or objects

// -------------------------------------------------------------
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') main(main);
/include qrpgleRef,noxdb

dcl-proc main;

   // Always set your ccsid for constants as your TGTCCSID, unless you use same as the job:
   // Examples source code uses CCSID 500
   json_setDelimitersByCcsid(500);

   // Copy examples
   // Note: Copy is a deep copy, so the source is not changed
   copyExample1();
   copyExample2();
   copyExample3();

   // Move examples
   moveExample1();
   moveExample2();
   moveExample3();

end-proc;

// -------------------------------------------------------------
dcl-proc copyExample1;

   Dcl-S pFrom              Pointer;
   Dcl-S pTo                Pointer;

   pFrom = json_parseString ('{ -
      "s" : "Life is a gift",   -
      "a" : [1,2,3,4],          -
      "o" : {                   -
         "x"  : 100,            -
         "y"  : 200             -
      }                         -
   }');

   // "to" is just an empty object at begining
   pTo = json_newObject();

   // copy string:
   json_copyValue ( pTo  : 'myString' : pFrom : 's');

   // copy within my own structure can address all elements both source and destination
   json_copyValue ( pTo  : 'a[4]' : pFrom   : 'o.x');

   // arrays
   json_copyValue ( pTo  : 'b' : pFrom   : 'a');

   // objects
   json_copyValue ( pTo  : 'p' : pFrom   : 'o');

   // Note: *OFF prettify the JSON
   json_WriteJsonStmf  (pTo: '/prj/noxdb/testout/copy1.json':1208:*OFF);

on-exit;
   // Clean up
   // Note: json_delete will delete the whole structure, so no need to delete each element
   json_delete(pFrom);
   json_delete(pTo);

end-proc;
// -------------------------------------------------------------
dcl-proc copyExample2;

   Dcl-S pFrom              Pointer;
   Dcl-S pTo                Pointer;

   // Copy into my self
   pFrom = json_parseString ('{      -
      "description" : {              -
         "en"  : "Life is a gift",   -
         "da"  : "Livet er en gave " -
      }                              -
   }');

   // Replacing the object node with a text string "from myself"
   json_copyValue (pFrom : 'description' : pFrom :'description.da');

   json_WriteJsonStmf  (pFrom: '/prj/noxdb/testout/copy2.json':1208:*OFF);

on-exit;
   // Clean up
   // Note: json_delete will delete the whole structure, so no need to delete each element
   json_delete(pFrom);
   json_delete(pTo);

end-proc;

// -------------------------------------------------------------
dcl-proc copyExample3;

   Dcl-S pFrom              Pointer;
   Dcl-S pTo                Pointer;

   pFrom = json_parseString ('{ -
      "s" : "Life is a gift",   -
      "a" : [1,2,3,4],          -
      "o" : {                   -
         "x"  : 100,            -
         "y"  : 200             -
      }                         -
   }');

   // "to" is just an empty object at begining
   pTo = json_newObject();

   // copy all elements: This is deep copy
   json_copyValue ( pTo  : '' : pFrom : '');
   json_WriteJsonStmf  (pFrom: '/prj/noxdb/testout/copy3.json':1208:*OFF);

on-exit;
   // Clean up
   // Note: json_delete will delete the whole structure, so no need to delete each element
   json_delete(pFrom);
   json_delete(pTo);

end-proc;
// -------------------------------------------------------------
dcl-proc moveExample1;

   Dcl-S pFrom              Pointer;
   Dcl-S pTo                Pointer;

   pFrom = json_parseString ('{ -
      "s" : "Life is a gift",   -
      "a" : [1,2,3,4],          -
      "o" : {                   -
         "x"  : 100,            -
         "y"  : 200             -
      }                         -
   }');

   // "to" is just an empty object at begining
   pTo = json_newObject();


   // Move string:
   json_moveValue ( pTo  : 'myString' : pFrom : 's');

   // Move within my own structure can address all elements both source and destination
   json_moveValue ( pTo  : 'a[4]' : pFrom    : 'o.x');


   // arrays
   json_moveValue ( pTo  : 'b' : pFrom   : 'a');

   // objects
   json_moveValue ( pTo  : 'p' : pFrom   : 'o');


   // Note: *OFF prettify the JSON
   json_WriteJsonStmf  (pTo: '/prj/noxdb/testout/move1.json':1208:*OFF);

on-exit;
   // Clean up
   // Note: json_delete will delete the whole structure, so no need to delete each element
   json_delete(pFrom);
   json_delete(pTo);

end-proc;
// -------------------------------------------------------------
dcl-proc moveExample2;

   Dcl-S pFrom              Pointer;
   Dcl-S pTo                Pointer;

   // Move into my self
   // Replacing the object node with a text string
   pFrom = json_parseString ('{      -
      "description" : {              -
         "en"  : "Life is a gift",   -
         "da"  : "Livet er en gave " -
      }                              -
   }');

   // Replacing the object node with a text string "from myself"
   json_moveValue (pFrom : 'description' : pFrom :'description.da');

   json_WriteJsonStmf  (pFrom: '/prj/noxdb/testout/move2.json':1208:*OFF);

on-exit;
   // Clean up
   // Note: json_delete will delete the whole structure, so no need to delete each element
   json_delete(pFrom);
   json_delete(pTo);

end-proc;
// -------------------------------------------------------------
dcl-proc moveExample3;

   Dcl-S pFrom              Pointer;
   Dcl-S pTo                Pointer;

   pFrom = json_parseString ('{ -
      "s" : "Life is a gift",   -
      "a" : [1,2,3,4],          -
      "o" : {                   -
         "x"  : 100,            -
         "y"  : 200             -
      }                         -
   }');

   // "to" is just an empty object at begining
   pTo = json_newObject();

   // Move all elements: This is deep Move
   json_moveValue ( pTo  : '' : pFrom : '');
   json_WriteJsonStmf  (pFrom: '/prj/noxdb/testout/move3.json':1208:*OFF);

on-exit;
   // Clean up
   // Note: json_delete will delete the whole structure, so no need to delete each element
   json_delete(pFrom);
   json_delete(pTo);
end-proc;