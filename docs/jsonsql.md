# JSON+SQL Functionality

This page documents the JSON+SQL functionality available in noxDB. Header file: `headers/JSONPARSER.rpgle`.

* json_sqlOpen
* json_sqlResultRow
* json_sqlResultSet
* json_sqlFetchNext
* json_sqlFetchRelative
* json_sqlExec
* json_sqlInsert
* json_sqlUpdate
* json_sqlClose
* json_sqlDisconnect

---

## json_sqlOpen

```
Pointer json_sqlOpen( String sqlstatement : [String jsonparams] )
```

#### Paramaters

1. An SQL statement.
2. JSON object with properties matching the parameter markers.

Returns an SQL handle - not a JSON node.

#### Example

```
sqlhnd = json_sqlOpen('select * from product');
```

```
sql = (
  'select * ' +
  'from product ' +
  'where prodKey = $prodKey'
);

sqlhnd = json_sqlOpen(sql:'{"prodKey": 250}');
```

---

## json_sqlResultRow

```
Pointer json_sqlResultRow( String sqlstatement : [String jsonparams] )
```

#### Paramaters

1. An SQL statement.
2. JSON object with properties matching the parameter markers.

Returns a object node with one resulting row for the SQL statment.

#### Example

```
sql   = (
    'Select * ' +
    'from product ' +
    'where prodKey = 500'
);

pJson = json_sqlResultRow(sql);

pResult = json_asJsonText(pJson);

json_NodeDelete(pJson);
json_sqlDisconnect();
```

---

## json_sqlResultSet

```
Pointer json_sqlResultSet( String sqlstatement : [Int(10) rowStart] : [Int(10) limit] : [String parameters] )
```

#### Parameters

1. SQL statement to be executed.
2. Which row to start the result set from
3. The max amount of rows to return. You can pass in `JSON_ALLROWS` for all rows.
4. Format, accepts one of the following constants:
   * `JSON_ROWARRAY` - An array with each row as an object
   * `JSON_META` - Metaobject: rows, fields
   * `JSON_FIELDS` - Columns info
   * `JSON_TOTALROWS` - Count all rows in the resultset (may affect performance)
   * `JSON_UPPERCASE` - Uppercase column names
   * `JSON_APPROXIMATE_TOTALROWS` - Appoximate number of rows
5. JSON object with properties matching the parameter markers.

---

## json_sqlFetchNext

```
Pointer json_sqlFetchNext( Pointer sqlHnd )
```

#### Parmaters

1. An SQL handle, which could come from `json_sqlOpen`.

#### Example

```
// Open our SQL cursor. Use a simple select
sqlhnd  = json_sqlOpen('Select * from product');

// Now iterate on each row in the resultset
pRow = json_sqlFetchNext(sqlhnd);
dow (pRow <> *NULL);
  ints    = json_getInt (pRow : 'PRODKEY');
  numbers = json_getNum (pRow : 'PRICE');
  
  text    = json_getStr (pRow : 'DESC');
  dates   = %date(json_getStr (pRow : 'STOCKDATE'));
  
  json_NodeDelete(pRow); // Always dispose it before get the next
  pRow = json_sqlFetchNext(sqlhnd);
enddo;

// Finaly and always!! Close the SQL cursor and dispose the json row object
json_sqlClose(sqlhnd);
json_sqlDisconnect();
```

---

## json_sqlFetchRelative

```
Pointer json_sqlFetchNext( Pointer sqlHnd : Int(10) count )
```

#### Parmaters

1. An SQL handle.
2. Amount of rows to skip relative to the current cursor position. Positive number to go forward, negative number to go backwards.

---

## json_sqlExec

```
Ind json_sqlExec( String sqlstatement : [String jsonobject] )
Ind json_sqlExec( String sqlstatement : [Pointer jsonobject] )
```

#### Parameters

1. An SQL statement.
2. JSON object with properties matching the parameter markers.

#### Example

````
err = json_sqlExec(
    'update product set price = price * 1.01'
);
````

````
priceJsStr = '{ "newprice" : 1.03 }';
err = json_sqlExec(
    'update product set price = price * $newprice'
    :priceJsStr
);
````

````
priceObj = json_parseString ('{ "newprice" : 1.04 }');
err = json_sqlExec(
    'update product set price = price * $newprice'
    :priceObj
);
json_Close(priceObj);
````

---

### json_sqlInsert

```
Ind json_sqlInsert( String table : String jsonrow : [String jsonparms] )
Ind json_sqlInsert( String table : Pointer jsonrow : [Pointer jsonparms] )
```

#### Parameters

1. The name of the name which is going to be updated.
2. The string or JSON object Pointer which contains the rows columns.
3. The parameters if parameter markers are used in the JSON document.

#### Example

```
row  = json_parseString ('{     -
    "prodKey": 99999  ,         -
    "desc": "Test" ,            -
    "manuid": "SAMSUNG",        -
    "price": 456.78  ,          -
    |stockCnt": 12              -
}');

err = json_sqlInsert (
    'product'
    :row
);

json_delete(row);
```

---

## json_sqlUpdate

```
Ind json_sqlUpdate( String table : String jsonrow : String whereclause : [String jsonwhereparms] )
Ind json_sqlUpdate( String table : Pointer jsonrow : String whereclause : [Pointer jsonwhereparms] )
```

#### Parameters

1. The name of the name which is going to be updated.
2. The string or JSON object Pointer which contains the rows updated columns.
3. The where clause for the update.
4. The parameters for the where clause if parameter markers are used in the where clause.

#### Example

```
row  = json_parseString ('{  -
    manuid: "SAMSUNG",        -
    price: 1234,              -
    stockCnt: 22              -
}');
```

```
err = json_sqlUpdate (
    'product'                // table name
    :row                     // row in object form {a:1,b:2} etc..
    :'prodkey = 120'         // Where clause
);
```

```
err = json_sqlUpdate (
    'product'                // table name
    :row                     // row in object form {a:1,b:2} etc..
    :'prodkey = $ID'         // Where clause
    : '{"ID":130}'           // Templte or object
);
```

---

## json_sqlClose

Closes internal SQL statement handle.

```
void json_sqlClose( Pointer sqlHnd )
```

#### Parameters

1. Pointer to local SQL handle.

---

## json_sqlDisconnect

Disconnect from connected database.

```
void json_sqlDisconnect()
```