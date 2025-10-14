[![Open in Visual Studio Code](https://open.vscode.dev/badges/open-in-vscode.svg)](https://open.vscode.dev/sitemule/noxDB)
# noxDB - Not Only XML...

**This branch is in currently considered as being Work-In-Progress**
**Once this work has been completed, this main branch will become the new default, and the current master branch will be deprecated, and renamed to legacy**

noxDB is an opensource framework that makes it easy to work with XML, JSON and SQL with one single approach - from within RPG.

### Preface
Basically you have an object graph which is built from scratch or loaded from XML, JSON, SQL or even CSV files.

The idea is that it is equally easy to manipulate the data graph from RPG and save/update data right back to XML, JSON or SQL.

This makes this tool perfect to load data from SQL and produce JSON in a web application. Or simply load data from SQL totally dynamically and then update SQL – dynamically.

It brings dynamic result set to RPG, so you don't have to recompile each time you add or change columns to your DB2 tables.

It is as simple as this in your RPG program:

```
// load a resultset from the product table
sql   = 'Select * from product';
pRows = nox_sqlResultSet(pCon: sql);

// Produce a JSON stream file in the root of the IFS
nox_writeJsonStmf(pRows  :
   '/tmp/resultset-array.json' : 1208 : *ON
);
```

You can find examples and documentation on the [Sitemule documentation website](https://sitemule.github.io/noxdb/about).

### Installation

Installation of noxDB should be done with `git` and `gmake` (GNU Make), which are available via `yum` - Here you can read more about yum:

[yum](https://bitbucket.org/ibmi/opensource/src/master/docs/yum/).

Also ensure that the open source tools are available in your path, according to this:

[set open source path](https://ibmi-oss-docs.readthedocs.io/en/latest/troubleshooting/SETTING_PATH.html)


noxDB is a two step process. noxDB requires you to build from source, but this step has been totally automated for you. To install noxDB, you need to use the pase environment (with `ssh` for example) and with a couple of seconds you can have the project built. No need to download save files, upload them or restore them.

```
ssh my_ibm_i
mkdir /prj
cd /prj
git -c http.sslVerify=false clone https://github.com/sitemule/noxDB.git
cd noxDB
gmake
```

This will create:

* The `NOXDB` library
* `NOXDB/JSONXML` service program.
* `NOXDB/QRPGLEREF.XMLPARSER` for the XML noxDB API prototypes.
* `NOXDB/QRPGLEREF.JSONPARSER` for the JSON noxDB API prototypes.
* `NOXDB/NOXDB` binding directory, with the `JSONXML` object on it.


### Build the distribution.

When you have made the project in library NOXDB, you can create the release as a savefile

```
ssh my_ibm_i
cd /prj/noxDB
gmake clean release
```

### Notes
This branch merges the "EBCDIC" legacy branch (previously called master),
with the code in UTF-8-Consolidated branch, aimed at making noxDB fully compatible with UTF-8 while also cleaning up the codebase.

### Further Reading

Want some further reading on noxDB?  See Andy Youens PowerWire article on [noxDB here.](https://powerwire.uk/noxdb-easily-use-json-in-rpg/)
