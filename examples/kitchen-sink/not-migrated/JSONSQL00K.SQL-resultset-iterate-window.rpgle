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

// ------------------------------------------------------------- *
// Using SQL resultsets

// ------------------------------------------------------------- *
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') main(main);
/include qrpgleRef,noxdb


// ------------------------------------------------------------------------------------
// main
// ------------------------------------------------------------------------------------
dcl-proc main;

   example1 ();
   json_sqlDisconnect();

end-proc;

// ------------------------------------------------------------------------------------
// Simple Statement
// ------------------------------------------------------------------------------------
dcl-proc example1;


   dcl-s pPointer pointer;
   dcl-s offset int(10) inz(1);
   dcl-s rowsFetched int(10) inz(0);
   dcl-s rowsToFetch int(10) inz(10);
   dcl-s forever ind inz(*off);
   dcl-s serviceName varchar(32);
   dcl-ds list likeds(json_iterator);

   dou (forever);

      pPointer = json_sqlResultSet(
         'select service_name from qsys2.services_info'
         : offset
         : rowsToFetch
      );

      // just dump the graph to alalyze
      json_writeJsonStmf(pPointer:
         '/prj/noxdb/testout/rows-in-this-window.json' 
         : 1208 
         : *ON
      );

      // SQL has done its job. Now we have all the data in the object graph - 
      // so we now query the graph directly instead 
      // of asking SQL for the numbers of rows returned.      
      rowsFetched = json_getLength (pPointer);
      
      // Do some processing with json_setIterator
      list = json_setIterator(pPointer);
      DoW json_ForEach(list);
         serviceName = json_getStr(list.this : 'service_name');
         json_joblog(serviceName);
      EndDo;

      // Always Cleanup !! 
      // Next call to json_sqlResultSet will produce a new graph !!!
      json_delete(pPointer);
      
      if (rowsFetched < rowsToFetch);
         leave;
      else;
         offset += 10;
      endif;
   enddo;

end-proc;


