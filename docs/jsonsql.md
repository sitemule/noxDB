# JSON+SQL Functionality

This page documents the JSON+SQL functionality available in noxDB. Header file: `headers/JSONPARSER.rpgle`.

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