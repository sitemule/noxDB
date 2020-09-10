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
        // Using SQL: Direct sql command

        // ------------------------------------------------------------- *
        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
        /include qrpgleRef,noxdb
        Dcl-S pRow       Pointer;
        Dcl-S err         ind;
        // ------------------------------------------------------------- *
        
        // Dont use the cycle
        *inlr = *on;
        
        json_sqlConnect();

        // Simple sql
        err =json_sqlExec(
            'create schema deleteme'
        );
        if err and json_sqlcode() <> -601; // already exists is ok  
            json_joblog(json_message());
            json_sqlDisconnect();
            return;
        EndIf;

        // Create the table
        err = json_sqlExec(
            'create or replace table deleteme.test (    - 
                text1 clob ccsid 1208,       -
                text2 varchar(30) ccsid 1208, -
                text3 clob,       -
                text4 varchar(30) -
            ) on replace delete rows'
        );

        if err;
            json_joblog(json_message());
            json_sqlDisconnect();
            return;
        EndIf;


        pRow  = json_newObject();
        json_setStr(pRow: 'text1': 'utf-8 data \u00c6\u00d8\u00c5');
        json_setStr(pRow: 'text2': 'utf-8 data \u00c6\u00d8\u00c5');
        json_setStr(pRow: 'text3': 'utf-8 data \u00c6\u00d8\u00c5');
        json_setStr(pRow: 'text4': 'utf-8 data \u00c6\u00d8\u00c5');

        // Insert a mult-charset text: 
        // UTF-8 will convert and single bytes will keep the escape 
        err = json_sqlInsert (
            'deleteme.test'
            :pRow
        );

        json_delete(pRow);

        if err;
            json_joblog(json_message());
            json_sqlDisconnect();
            return;
        EndIf;

        json_sqlDisconnect();
