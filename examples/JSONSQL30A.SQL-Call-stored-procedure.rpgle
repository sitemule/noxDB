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
        //  Use this procedure from acs 

        // create or replace procedure qgpl.add (
        //     in  a int,
        //     in  b int,
        //     out c dec(5,2)
        // ) 
        // begin 
        //     set c = (a + b) / 100.0;
        // end;
        // call add (a=>123, b=>456 , c=>?);

       // ------------------------------------------------------------- *
     H*BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QTERASPACE')
     H*STGMDL(*TERASPACE)
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S err                    Ind;
       Dcl-S pIn                    Pointer;
       Dcl-S pOut                   Pointer;


          // Call stored procedures

          // Build input parameter object
          pIn  = json_newObject();
          json_SetInt(pIn: 'a': 123);
          json_SetInt(pIn: 'b': 456);


          // Build output parameter object
          pOut  = json_newObject();
          json_SetInt(pOut: 'c': 0);

          // Call the procedure
          err = json_sqlCall ('add' : pOut : pIn);
          
          // Dump the result
          json_joblog(pOut);  

          json_delete(pIn);
          json_delete(pOut);

          // That's it..
          *inlr = *on;
