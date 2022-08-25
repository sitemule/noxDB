**free
// -------------------------------------------------------------
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
//
// -------------------------------------------------------------
Ctl-Opt BndDir('JSONPARSER') dftactgrp(*NO) ACTGRP('QILE' );
Dcl-S pRow      Pointer;
Dcl-S error     ind;
Dcl-S id        int(20);
Dcl-S msg       varchar(256);

/include qrpgleRef,noxdb

    // Don't use the cycle;
    *inlr = *on;

    pRow = json_newObject();
    json_setStr(pRow: 'TITLE' : 'ÆØÅæøå \u0410\u0411\u0412\u0413\u0414\u0415');
    json_setStr(pRow: 'THEME': '');
    json_setInt(pRow: 'WEBACTIVE': 0);
    json_setStr(pRow: 'PUBDATE': %char(%timestamp()));
    json_setStr(pRow: 'EXPIREDATE':  %char(%timestamp()));
    json_setInt(pRow: 'SITECLUDE': 0);
    json_setInt(pRow: 'NOINDEX': 0);
    json_setInt(pRow: 'HASSEOURL': 0);
    json_setStr(pRow: 'PROPERTIES': '{"h":"ÆØÅæøå \u0410\u0411\u0412"');
    json_setStr(pRow: 'LAYOUT': '{}');
    json_setInt(pRow: 'STATUS_CODE': 0);
    json_setInt(pRow: 'CREATED_BY': 0);
    json_setStr(pRow: 'CREATED_TIMESTAMP':  %char(%timestamp()));
    json_setInt(pRow: 'CHANGED_BY': 0);
    json_setStr(pRow: 'CHANGED_TIMESTAMP':  %char(%timestamp()));
    json_setInt(pRow: 'DELETED_BY': 0);
    json_setStr(pRow: 'DELETED_TIMESTAMP':  %char(%timestamp()));

    json_WriteJsonStmf(pRow:'/prj/noxdb/testout/CLOB-row.json':1208:*OFF);


    error = json_sqlInsert  (
        'fledb/cms_page'
        :pRow
    );
    id = json_sqlGetInsertId();


    // Was there a problem ?
    if error;
        msg = json_Message();
    EndIf;

    // Finaly and always !! close the SQL cursor and dispose the json row object
    json_delete(pRow);
    json_sqlDisconnect();
