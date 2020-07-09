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

       // Parse json string and play with it

       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S pData              Pointer;
       Dcl-S a                  Pointer;
       Dcl-S c                  Pointer;
       Dcl-S len                    Int(5:0);

          pData = json_ParseString (
               '{                      '+
               '  delete_me: {         '+
               '     del1:1,           '+
               '     del2:2            '+
               '  },                   '+
               '  clear_me: {          '+
               '     clr1:1,           '+
               '     clr2:2            '+
               '  },                   '+
               '  clear_array: [1,2,3] '+
               '}'
            );
          // remove "delete me"
          json_delete( json_locate(pData : 'delete_me'));

          // remove all contet ( children) of "clear_me"
          json_clear ( json_locate(pData : 'clear_me'));

          // Works also for arrays:
          json_clear  ( json_locate(pData : 'clear_array'));
          len = json_getLength ( json_locate(pData : 'clear_array'));

          // Now it contains:
          //  {
          //      "clear_me":{
          //      },
          //      "clear_array": []
          //  }

          // write a,b,c,d in this order:
          json_WriteJsonStmf(pData:
            '/prj/noxdb/testdata/clear_delete.json':1208:*OFF
          );

          // At this point you can use close and delete since pData has the complete tree:
          // Use "close" if you want to traverse up and delete everything in the tree
       // Use "delete" if you just want the current element and is children ( not parent / not sibl
          json_delete(pData );
          *inlr = *on;
          Return;

