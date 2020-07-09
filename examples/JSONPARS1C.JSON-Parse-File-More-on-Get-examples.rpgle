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
       Dcl-S pNode              Pointer;
       Dcl-S pArr               Pointer;
       Dcl-S msg                VarChar(50);
       Dcl-S tag                VarChar(50);
       Dcl-S value              VarChar(50);
       Dcl-S n                  Packed(15:2);

          *inlr = *on;
          pJson = json_ParseFile ('/prj/noxdb/testdata/demo.json');

          If json_Error(pJson) ;
             msg = json_Message(pJson);
             Dsply msg;
             json_dump(pJson);
             json_delete(pJson);
             Return;
          EndIf;

          pNode = json_locate(pJson: '/o/n');
          n     = json_getNum(pNode);

          pNode = json_locate(pJson: '/a[1]');
          n     = json_GetNum (pNode);

          pNode = json_locate(pJson: '/s');
          value = json_getStr(pNode);

          pNode = json_locate(pJson: '/u');
          value = json_getStr(pNode);

          pNode = json_locate(pJson: '/o/a[2]');
          n     = json_GetNum(pNode);

          // Loop on the array
          pArr  = json_locate(pJson: '/o/a[0]'); // First array element
          DoW (pArr <> *NULL) ;
             n     = json_GetNum (pArr);
             pArr  = json_GetNext(pArr);
          EndDo;

          // Loop the root: Note the  "/" will position to the first chile of the root
          pNode  = json_locate(pJson: '/'); // First array element
          DoW (pNode <> *NULL) ;
             value  = json_GetStr (pNode);
             pNode  = json_GetNext(pNode);
          EndDo;

          // Get Value directly
          value = json_GetStr    (pJson : '/u');

          // Get Value directly relative
          pNode = json_locate(pJson: '/o');
          value = json_GetStr (pNode : 'n');   // This is "n" in "o"

          // Get number of entries in arrays
          n  = json_GetNum(pJson : '/o/a[UBOUND]': -1 );

          json_dump(pJson);
          json_delete(pJson);
