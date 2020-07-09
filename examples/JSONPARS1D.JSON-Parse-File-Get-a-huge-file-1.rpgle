       // ------------------------------------------------------------- *
       // noxDB - Not only XML. JSON, SQL and XML made easy for RPG
       // Company . . . : System & Method A/S - Sitemule
       // Design  . . . : Niels Liisberg

       // Unless required by applicable law or agreed to in writing, software
       // distributed under the License is distributed on an "AS IS" BASIS,
       // WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

       // Look at the header source file "QRPGLEREF" member "NOXDB"
       // for a complete description of the functionality

       // Build JSON from scratch

       // Step 1)
       // When using noxDB you need two things:
       //  A: Bind you program with "NOXDB" Bind directory
       //  B: Include the noxDB prototypes from QRPGLEREF member NOXDB

       // Step 2)
       // Include the prototypes for the JSONparser found in member "NOXDB"
       // in the source file "QRPGLEREF" in the IceBreak   library

       // Step 3)
       // Parse your JSONfile by caling the "json_ParseFile" function. It returns
       // logical a pointer to an JSON object tree.
       // Examine if the parser ran ok with json_Error() which return *ON if an
       // error did occur. In that case you can examine the reason with
       // the function "json_GetMsg()" to retrive the error and/or
       // use the function "json_Dump()"   to display the xml-tree contents

       // Step 4)
       // Locate each element node by the function "json_Locate".
       // the location can be relative or from the root by prefixinig the location
       // with an "/". Each level is separated by a "/" e.g.
       // "/MyRoot/MyElement"  is "myelement" found within "myroot"
       // You can use either / or . as expresion delimiter

       // Step 5)
       // When a element node is sucessfully fetched, you can write
       // a new JSON document with this element as a root element.
       // Use the json_WriteJsonStmf(pElm: FileName : Ccsid)  to produce that task
       // the ccsid can be other than the source JSON document. it will
       // convert it to the selected ccsid. Note: Comments not reproduced.

       // Step 6)
       // Last - remember to close the JSON tree with "json_delete"


       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S pJson              Pointer;
       Dcl-S msg                VarChar(256);
       Dcl-S n                  VarChar(50);
       // ------------------------------------------------------------- *

          *inlr = *on;
          pJson = json_ParseFile ('/prj/noxdb/testdata/simple.json');

          If json_Error(pJson) ;
             msg = json_Message(pJson);
             json_dump(pJson);
             json_delete(pJson);
             Return;
          EndIf;

          // save as new file
          json_WriteJsonStmf(pJson:
             '/prj/noxdb/testdata/simple-out.json':1208:*OFF
          );

          json_delete(pJson);

