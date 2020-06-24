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
       // When using noxDB you need two things:
       //  A: Bind you program with "NOXDB" Bind directory
       //  B: Include the noxDB prototypes from QRPGLEREF member NOXDB
       //
       // Parse json  string and play with it
       //
       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S pJson              Pointer;
       Dcl-S pNode              Pointer;
       Dcl-S msg                VarChar(50);
       Dcl-S tag                VarChar(50);
       Dcl-S value              VarChar(50);
       Dcl-S price               Packed(15:2);

       pJson = json_ParseString (
            '{"/rrn/product/icebreak":1,' +
            '"PRODID":"\u00b5 DIGITAL 600 ax",' +
            '"MANUID":"CASIO",' +
            '"PRICE":123.45,' +
            '"STOCKCNT":6,'+
            '"janej":"0"}'
              : ''
       );

       If json_Error(pJson) ;
          msg = json_Message(pJson);
          json_dump(pJson);
          json_delete(pJson);
          Return;
       EndIf;

       // locate a node and get is value
       // (Keys a not case sensitive)
       pNode = json_locate(pJson: 'PRICE');
       price = json_getNum(pNode);

       // Or in one line
       price = json_getNum(pJson: 'price' : 0);

       // IF the key does not exists it will return default value:
       // Here  showing with / without default paramter
       price = json_getNum       (pJson: '/priceJohn': -1);
       value = json_getStr       (pJson: '/priceJohn': 'N/A');
       price = json_getNum       (pJson: '/priceJohn');
       value = json_getStr       (pJson: '/priceJohn');


       json_dump(pJson);
       json_delete(pJson);
       *inlr = *on;
