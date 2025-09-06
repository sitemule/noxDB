# noxDB – Not Only XML….
This branch is "work in progress" - merging the "EBCDIC" master, aiming at havinf the graph 100% in UTF-8 and tighten this up. 
 


Nox is an opensource framework that makes it easy to work with XML, JSON and SQL with one single approach - from within RPG.

Basically you have an object graph which is built from scratch or loaded from XML, JSON, SQL or even CSV files.

The idea is that it is equally easy to manipulate the data graph from RPG and save/update data right back to XML, JSON or SQL.

This makes this tool perfect to load data from SQL and produce JSON in a web application. Or simply load data from SQL totally dynamically and then update SQL – dynamically.

It brings dynamic result set to RPG, so you don't have to recompile each time you add or change columns to your DB2 tables.

It is as simple as this in your RPG program:

```
// load a resultset from the product table
sql   = 'Select * from product';
pRows = nox_sqlResultSet(sql);

// Produce a JSON stream file in the root of the IFS
nox_writeJsonStmf(pRows  :
   '/tmp/resultset-array.json' : 1208 : *ON
);
```

