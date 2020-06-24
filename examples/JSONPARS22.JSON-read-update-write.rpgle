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

       // Parse json file and play with it

       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S pJson              Pointer;
       Dcl-S msg                VarChar(50);
       // >>>>> Not converted: Conversion not currently supported.
       //==========================================================================================
       // Start of moved field definitions.
       //==========================================================================================
       Dcl-S file                  Char(128);
       Dcl-S text                  Char(64);
       Dcl-S origin                Char(3);
       //==========================================================================================
       // End of moved field definitions.
       //==========================================================================================
     C     *entry        plist
       // >>>>> Not converted: Conversion not currently supported.
     C                   parm                    file            128
       // >>>>> Not converted: Conversion not currently supported.
     C                   parm                    text             64
       // >>>>> Not converted: Conversion not currently supported.
     C                   parm                    origin            3

          pJson = json_ParseFile   ( file);
          If json_Error(pJson) ;
             msg = json_Message(pJson);
             json_delete(pJson);
             Return;
          EndIf;

          json_SetValue(pJson : '/session/preset/text'  : Text);
          json_SetValue(pJson : '/session/preset/origin': Origin);

          json_WriteJsonStmf  (pJson : file  : 1208 : *OFF);
          json_delete(pJson);
          *inlr = *on;
