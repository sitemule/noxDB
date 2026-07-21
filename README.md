[![Open in Visual Studio Code](https://open.vscode.dev/badges/open-in-vscode.svg)](https://open.vscode.dev/sitemule/noxDB)
# noxDB - Not Only XML...

**This branch is in currently considered as being Work-In-Progress**
Read more in end of this README.md

**Once this work has been completed, this main branch will become the new default, and the current master branch will be deprecated, and renamed to legacy**

noxDB is an opensource framework that makes it easy to work with XML, JSON and SQL with one single approach - from within RPG.

### Preface
Basically you have an object graph which is built from scratch or loaded from XML, JSON, SQL or even CSV files.

The idea is that it is equally easy to manipulate the data graph from RPG and save/update data right back to XML, JSON or SQL.

This makes this tool perfect to load data from SQL and produce JSON in a web application. Or simply load data from SQL totally dynamically and then update SQL â€“ dynamically.

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

* The `NOXDBUTF8` library
* `NOXDBUTF8/NOXDBUTF8` service program.
* `NOXDBUTF8/QRPGLEREF.NOXDBUTF8` for the API prototypes.
* `NOXDBUTF8/NOXDBUTF8` binding directory, with the `NOXDBUTF8` object on it.


### Build the distribution.

When you have made the project in library NOXDBUTF8, you can create the release as a savefile

```
ssh my_ibm_i
cd /prj/noxDB
gmake clean release
```

### Notes
This branch merges the "EBCDIC" legacy branch (previously called master),
with the code in UTF-8-Consolidated branch, aimed at making noxDB fully compatible with UTF-8 while also cleaning up the codebase.

### Work in progress?
I know it sounds confusing, so let me try to explain it:

The **master** branch, was carved out from the IceBreak core where everything was EBCDIC.
This code has been battle-tested for at least two decades and we
know that the "classic" noxDb is very stable.

Today - we have UTF-8 in RPG and the world has changed.
We had attempts to put UTF-8 into the "classic" noxDb,
but it was not clean - this brach still exists as **utf-8** but only for reference.

So we created the **main** branch, where the graph itself is in UTF-8 and everything in that branch works, however it is not battle-tested for more that two decades.

Also notice that the **main** branch (the UTF-8 stuff) has all the new features for easy construction of objects and array - ex:

```RPGLE
   pCustomer1 = nox_Object(
      'id'         : nox_Int  (12345):
      'name'       : nox_Str  ('System & Metod A/S'):
      'street'     : nox_Str  ('Håndværkersvinget 8'):
      'city'       : nox_Str  ('Hørsholm'):
      'greeting'   : nox_Str  (u'4f605978'): // "Ni hau" in unicode
      'creditLimit': nox_Dec  (76543.21):
      'createdDate': nox_Date (%date()):
      'createdTime': nox_Time (%time()):
      'dateTime'   : nox_TS   (%timestamp()):
      'isNice'     : nox_Bool (10 > 1):
      'isUS'       : nox_Bool ('DK' = 'USA')
   );
```

Let me point to, where the "work in progress" coms in:

- Examples - are not all re-written, the original branch was bloated with examples. There is a kitch-sink where old-stuff can stay as inspiration.
- JSON-IN/JSON-OUT dynamic calls of programs with inline PCM. This is a super advanced feature that is not ported yet. It fails during compilation and was therefore left out of the service program.


### My advice:
if you are starting a new project, please go for the **main**. It is production ready, and we use it for our own projects at clients.

