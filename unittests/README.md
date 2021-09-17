# noxDB Unit Tests

For executing the unit tests located in the folder _unittests_ you need to 
previously install either [iRPGUnit][iru] or [RPGUnit][ru].

You can compile the unit tests with the make tool.

    make

The unit tests need access to the ASSERT copy book from the iRPGUNIT or RPGUNIT.
You need to pass this as a parameter to the make command:

    make RUINCDIR=/usr/local/include/irpgunit

By default the unit tests are placed in the NOXDB library. You can change
this by passing your custom library to the BIN_LIB parameter like this:

    make BIN_LIB=NOXDBUT

The unit tests need the noxDB service program. By default it is expected in 
the library NOXDB. You can change this by passing that to the parameter
NOXDB_LIB like this:

    make BIN_LIB=NOXDBUT NOXDB_LIB=JXLIB

It is assumed that the RUTESTCASE service program of the unit testing framework
is in the library list. You can specify the library for it with the parameter 
RU_LIB.

    make BIN_LIB=NOXDBUT NOXDB_LIB=JXLIB RU_LIB=IRPGUNIT

[iru]: https://irpgunit.sourceforge.net
[ru]: https://rpgunit.sourceforge.net

