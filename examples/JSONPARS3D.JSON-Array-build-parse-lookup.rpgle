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

// This sample shows array handling

// The example uses ccsid 500. Set that 
// accordingly to your ccsid on your source files  

// ------------------------------------------------------------- *
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') ;
/include qrpgleRef,noxdb

   // Always set your ccsid for constants: 
   json_setDelimitersByCcsid(500);

   example1();
   example2();
   *inlr = *on;

// ------------------------------------------------------------------------------------
// example1
// ------------------------------------------------------------------------------------
dcl-proc example1;

   Dcl-S pArr               Pointer;
   Dcl-S pRes               Pointer;
   Dcl-S pB                 Pointer;      
   Dcl-S pC                 Pointer;
   Dcl-S pD                 Pointer;

   Dcl-S len                Int(5:0);
   Dcl-S t                  VarChar(512);

   pArr = json_parseString('["a","b","c"]');
   pB   = json_lookupValue(pArr :  'B' : JSON_IGNORE_CASE);
   pC   = json_lookupValue(pArr :  'c' : JSON_SAME_CASE);
   pC   = json_lookupValue(pArr :  'c' ); // Same case is default
   pD   = json_arrayPush(pArr : 'd');
   len  = json_getLength(pArr);

   t =   json_asJsonText(pArr);
   json_joblog(t);

   json_delete(pArr);


end-proc;
// ------------------------------------------------------------------------------------
// example2
// Glue two arrays together
// ------------------------------------------------------------------------------------
dcl-proc example2;

   Dcl-S pa1                Pointer;
   Dcl-S pa2                Pointer;
   Dcl-S pa3                Pointer;
   Dcl-S pa4                Pointer;
   Dcl-S pRes               Pointer;
   Dcl-S pB                 Pointer;
   Dcl-S pC                 Pointer;
   Dcl-S pD                 Pointer;

   Dcl-S len                Int(5:0);
   Dcl-S t                  VarChar(512);

   // Append to an existing array. The contents of 
   // pa2 will be empty after since it "moves" the content.
   // if you need the pa2 to be untouched the use JSON_COPY_CLONE
   pa1  = json_parseString('["a","b","c"]');
   pa2  = json_parseString('["d","e","f"]');
   pRes  = json_arrayAppend(pa1 : pa2 : JSON_MOVE_UNLINK);
   
   t =   json_asJsonText(pRes);
   json_joblog(t);

   // Now take b,c   out  of a,b,c,d,e,f
   // Note the first element is = 0  sp a=0, b=1, c=2 etc.
   pa3 = json_arraySlice(pRes : 1:3 : JSON_MOVE_UNLINK);
   
   t = json_asJsonText(pa3);
   json_joblog(t);

   // Now take a copy of the rest d,e,f from a,d,e,f  out of a,b,c,d,e,f
   // -1 Is to the end of the array
   pa4 = json_arraySlice(pRes : 1: -1 : JSON_COPY_CLONE);
   
   t = json_asJsonText(pa4);  // we got     [d,e,f]
   json_joblog(t);

   t = json_asJsonText(pRes); // Still have [a,d,e,f]
   json_joblog(t);

   // Done!! Clean up 
   json_delete(pa1);
   json_delete(pa2);
   json_delete(pa3);
   json_delete(pa4);
   json_delete(pRes);

end-proc;
