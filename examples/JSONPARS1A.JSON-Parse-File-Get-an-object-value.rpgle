        // ------------------------------------------------------------- *
        // noxDB - Not only XML. JSON, SQL and XML made easy for RPG
        //
        // Company . . . : System & Method A/S - Sitemule
        // Design  . . . : Niels Liisberg
        //
        // Unless required by applicable law or agreed to in writing, software
        // distributed under the License is distributed on an "AS IS" BASIS,
        // WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
        //
        // Look at the header source file "QRPGLEREF" member "NOXDB"
        // for a complete description of the functionality
        //
        // Build JSON from scratch
        //
        // Step 1)
        // When using noxDB you need two things:
        //  A: Bind you program with "NOXDB" Bind directory
        //  B: Include the noxDB prototypes from QRPGLEREF member NOXDB
        //
        // Step 2)
        // Include the prototypes for noxDB and bind with bibddir NOXDB
        //
        // Step 3)
        // Parse your JSONfile by caling the "json_ParseFile" function. It returns
        // logical a pointer to an JSON object tree.
        // Examine if the parser ran ok with json_Error() which return *ON if an
        // error did occur. In that case you can examine the reason with
        // the function "json_GetMsg()" to retrive the error and/or
        // use the function "json_Dump()"   to display the xml-tree contents
        //
        // Step 4)
        // Locate each element node by the function "json_Locate".
        // the location can be relative or from the root by prefixinig the location
        // with an "/". Each level is separated by a "/" e.g.
        // "/MyRoot/MyElement"  is "myelement" found within "myroot"
        // You can use either / or . as expresion delimiter
        //
        // Step 5)
        // When a element node is sucessfully fetched, you can write
        // a new JSON document with this element as a root element.
        // Use the json_WriteJsonStmf(pElm: FileName : Ccsid)  to produce that task
        // the ccsid can be other than the source JSON document. it will
        // convert it to the selected ccsid. Note: Comments not reproduced.
        //
        // Step 6)
        // Last - remember to close the JSON tree with "json_delete"
        //
        //
        // ------------------------------------------------------------- *
        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
        /include qrpgleRef,noxdb
        Dcl-S pJson              Pointer;
        Dcl-S pNode              Pointer;
        Dcl-S msg                VarChar(50);
        Dcl-S tag                VarChar(50);
        Dcl-S value              VarChar(50);
        Dcl-S price              Packed(15:2);
        Dcl-S id                 Int(20:0);
        Dcl-S desc               VarChar(50);
        Dcl-S text               VarChar(50);
        Dcl-S country1           VarChar(50);
        Dcl-S country2           VarChar(50);
        Dcl-S mem1               Int(20:0);
        Dcl-S mem2               Int(20:0);
        // ------------------------------------------------------------- *

        *inlr = *on;
        // Current memory use for leakdetection
        mem1 = json_memUse();

        // Parse the JSON file
        pJson = json_ParseFile ('/prj/noxdb/testdata/simple.json');

        If json_Error(pJson) ;
           msg = json_Message(pJson);
           json_dump(pJson);
           json_delete(pJson);
           Return;
        EndIf;

        // Locate and return the value:
        pNode = json_Locate(pJson: 'price');
        price = json_GetNum(pNode);

        // Or in one go:
        price = json_GetNum(pJson: 'price');
        text  = json_GetStr(pJson: 'text');

        // Or in one go - with deafults if not found
        id    = json_GetInt(pJson: 'id'  : -1 );
        text  = json_GetStr(pJson: 'desc': 'N/A');

        // Use either / or . as you like. It is the same..
        country1   = json_GetStr(pJson: 'anObject/country': 'N/A');
        country2   = json_GetStr(pJson: 'anObject.country': 'N/A');

        json_delete(pJson);

        // For debugging purposes, always do a leak detection:
        mem2 = json_memUse();
        If mem1 <> mem2;
           json_MemStat();
        EndIf;
