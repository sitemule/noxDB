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
       Dcl-S pTplData           Pointer;
       Dcl-S pProp              Pointer;

          pData = json_ParseString (
               '{                      '+
               '  a:123,               '+
               '  b:"text",            '+
               '  c:"More text"        '+
               '}'
          );
          pProp = json_ParseString (
             '{                      '+
             '  name:"Company",      '+
             '  addr:"Smart city"    '+
             '}'
          );
          pTplData = json_NewObject();
          json_setValue(pTplData :'this' : pData      : json_OBJCOPY);
          json_setValue(pTplData :'site' : pProp      : json_OBJCOPY);
          json_WriteJsonStmf(pTplData:
              '/noxdb/json/props.json':1208:*OFF
          );
          json_delete(pProp    );
          json_delete(pData    );
          json_delete(pTplData );
          *inlr = *on;
          Return;

