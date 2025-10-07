**free
// ------------------------------------------------------------------------------------
// noxDB - Not Only Xml - Its JSON, XML, SQL and more
//
// This tutorial will show all the features, from a JSON
// and SQL perspective
//
// Design:  Niels Liisberg
// Project: Sitemule.com
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// Look at the header source file "QRPGLEREF" member "NOXDBUTF8"
// for a complete description of the functionality
//
// When using noxDbUtf8 you need two things:
//  A: Bind you program with "NOXDBUTF8" Bind directory
//  B: Include the noxDbUtf8 prototypes from QRPGLEREF member NOXDBUTF8
//
// Important: You need to set the CCSID of the source to the CCSID of the
//            target ccsid of the running job.
//            otherwise special chars will be strange for constants.
//            This project is by default set to CCSID 500
//            do a CHGJOBCCSID(500) before running these examples.
//            This only applies to program constants !!
//
// Note:      This program is/can be build with UTF-8, so all CHAR/VARCHAR are in UTF-8
//            This is not an requirement - you can use any CCSID you like
//
//
// try/build:
// cd '/prj/NOXDBUTF8'
// addlible NOXDBUTF8
// chgjobccsid(500)
// call
// ------------------------------------------------------------------------------------
Ctl-Opt copyright('Sitemule - System & Method (C), 2025');
Ctl-Opt BndDir('NOXDBUTF8') CCSID(*CHAR:*UTF8);
Ctl-Opt dftactgrp(*NO) ACTGRP('QILE') option(*nodebugio:*srcstmt:*nounref) ALWNULL(*USRCTL);
Ctl-Opt main(main) ;

/include qrpgleref,noxDbUtf8

// ------------------------------------------------------------------------------------
dcl-proc main;

    dcl-s id           int(10);
    dcl-s name         varchar(256);
    dcl-s street       varchar(256);
    dcl-s city         varchar(256);
    dcl-s creditLimit  packed(15:2);
    dcl-s createdDate  date;
    dcl-s createdTime  time;
    dcl-s dateTime     timeStamp;
    dcl-s isNice       ind;

    dcl-s debug        varchar(32766:4);
    dcl-s msg          varchar(256) ccsid(*jobrun);
    dcl-s len          int(10);
    dcl-s checksum     int(10);
    dcl-s memuse       int(20);
    dcl-s pCustObject  pointer;
    dcl-s pCon         pointer;
    dcl-s pCustomer    pointer;
    dcl-s pCustomer2   pointer;
    dcl-s pCustList    pointer;
    dcl-s pMoreCust    pointer;
    dcl-s pTopFive     pointer;
    dcl-s pRes         pointer;
    dcl-s key          varchar(256) inz('topFive[id=12345]');

    dcl-ds itList      likeds(nox_iterator);

// ------------------------------------------------------------------------------------

    // Take a snapshot of the memory usage before we start
    memuse = nox_memUse();

    // We will need a database connection in a moment
    pCon = nox_sqlConnect();


    // Step 1: Lets build a JSON object from scratch
    // and let set some attirbutes on the object.
    // we use integer, string, fixed decimal, date, time, timestamp and boolen (indicator)
    // float numbers and date
    pCustomer = nox_newObject();
    nox_setInt (pCustomer:'id'         : 12345);
    nox_setStr (pCustomer:'name'       : 'System & Metod A/S');
    nox_setStr (pCustomer:'street'     : 'Håndværkersvinget 8');
    nox_setStr (pCustomer:'city'       : 'Hørsholm');
    nox_setStr (pCustomer:'greeting'   : u'4f605978'); // "Ni hau" in unicode
    nox_setDec (pCustomer:'creditLimit': 76543.21);
    nox_setDate(pCustomer:'createdDate': %date());
    nox_setTime(pCustomer:'createdTime': %time());
    nox_setTS  (pCustomer:'dateTime'   : %timestamp());
    nox_setBool(pCustomer:'isNice'     : (10 > 1)); // Logical expression

    // Just to see the progress:
    nox_WriteJsonStmf(pCustomer : '/prj/noxDbUtf8/testout/ex01Tutorial-Customer.json' : NOX_UTF8_BOM : *OFF);
    debug = nox_asJsonText(pCustomer);
    nox_joblog ( debug );

    // Step 1.a: alternativ - you can also make it with the object builder:
    // Here you make atomic value nodes in the graph, and create a new object on the fly
    pCustomer2 = nox_Object(
        'id'         : nox_Int  (12345):
        'name'       : nox_Str  ('System & Metod A/S'):
        'street'     : nox_Str  ('Håndværkersvinget 8'):
        'city'       : nox_Str  ('Hørsholm'):
        'greeting'   : nox_Str  (u'4f605978'): // "Ni hau" in unicode
        'creditLimit': nox_Dec  (76543.21):
        'createdDate': nox_Date (%date()):
        'createdTime': nox_Time (%time()):
        'dateTime'   : nox_TS   (%timestamp()):
        'isNice'     : nox_Bool (10 > 1)
    );

    // Just to see the progress:
    nox_WriteJsonStmf(pCustomer2 : '/prj/noxDbUtf8/testout/ex01Tutorial-Customer2.json' : NOX_UTF8_BOM : *OFF);
    debug = nox_asJsonText(pCustomer);
    nox_joblog ( debug );

    // Step 2: Build an array with customers
    // note the arrayPush can push it to either head or tail
    pCustList = nox_newArray();
    nox_arrayPush ( pCustList : pCustomer);

    // Just to see the progress:
    debug = nox_asJsonText(pCustList);
    nox_joblog ( debug );

    // step3: now we get the rest of customers from the database;
    pMoreCust = nox_sqlResultSet(pCon:
        'select                       -
            cusnum  as "id",          -
            lstnam  as "name",        -
            street  as "street",      -
            cdtlmt  as "creditLimit"  -
        from qiws.QCUSTCDT            -
    ');

    // Just to see the progress:
    debug = nox_asJsonText(pMoreCust);
    nox_joblog ( debug );

    // now we have the list
    // Note: the MOVE_UNLINK can be used if the array was already
    // a sub-node in an other object/array. here it just an example and have no effect
    // Also you can omit the result - but returns the receiving array so you can "chain" this function
    // ie "moveObjectInto"
    pRes  = nox_Append(pCustList : pMoreCust: NOX_MOVE_UNLINK);

    // How many are there in the array?
    len  = nox_getLength(pCustList);

    // Just to see the progress:
    debug = nox_asJsonText(pCustList);
    nox_joblog ( debug );

    // Lets sort the array on highest "creditLimit" and then "name"
    nox_arraySort(pCustList : 'creditLimit:DESC,name:ASC' );

    // Just to see the progress:
    debug = nox_asJsonText(pCustList);
    nox_joblog ( debug );


    // I only want the first 5
    // Note the first element is = 0
    // You can also use NOX_MOVE_UNLINK, to carve the result out of the source
    // however, here we copy the elements to a new array
    pTopFive = nox_arraySlice(pCustList : 0: 5 : NOX_COPY_CLONE);

    // Just to see the progress:
    debug = nox_asJsonText(pTopFive);
    nox_joblog ( debug );

    // we can caluculate the checksum, to see later if anyone have touched the object graph
    checksum = nox_NodeCheckSum(pTopFive);

    // and save it to disk:
    // You can use UTF8_BOM if you need the BOM-siganture
    nox_WriteJsonStmf(pTopFive : '/prj/noxDbUtf8/testout/ex01Tutorial-topfive.json' : NOX_UTF8_BOM : *OFF);

    // Now what do we need to clean up:
    // pCustList? yes
    // pCustomer? no - it is already removed when deleting the pCustList
    // pTopFive? Yes - it is a clone
    // Note: we always delete everything in our exit handler
    //       it is OK to delete an already deleted node - it just does nothing
    // This is just to show how to do it
    nox_delete(pCustList);
    nox_delete(pTopFive);

    // We could stop the program here - But let's have some more fun:
    // Load the top five array
    pTopFive = nox_ParseFile ('/prj/noxDbUtf8/testout/ex01Tutorial-topfive.json');

    // Just to see the progress:
    debug = nox_asJsonText(pTopFive);
    nox_joblog ( debug );

    // Was there some issues?
    if Nox_Error(pTopFive) ;
        msg = nox_Message(pTopFive);
        nox_joblog ( msg );
        nox_dump(pTopFive);
        return;
    endif;

    // Is the checksum the same?
    if checksum <> nox_NodeCheckSum(pTopFive);
        nox_joblog ('Invlaid checksum');
    endif;

    // now create a object with that array and call it "topFive":
    pCustObject = nox_newObject();
    nox_moveObjectInto (pCustObject: 'topFive': pTopFive );

    // Just to see the progress:
    debug = nox_asJsonText(pCustObject);
    nox_joblog ( debug );

    // let's loop through all items and get them back to RPG variables:
    // note: we could have used pTopFive - but for fun we locate from the top
    itList = nox_setIterator(pCustObject : 'topFive');
    dow nox_ForEach(itList);
        id          = nox_getInt ( itList.this : 'id');
        name        = nox_getStr ( itList.this : 'name');
        street      = nox_getStr ( itList.this : 'street');
        city        = nox_getStr ( itList.this : 'city');
        creditLimit = nox_getDec ( itList.this : 'creditLimit');
        createdDate = nox_getDate( itList.this : 'createdDate');
        createdTime = nox_getTime( itList.this : 'createdTime');
        dateTime    = nox_getTS  ( itList.this : 'dateTime');
        isNice      = nox_getBool( itList.this : 'isNice');
    enddo;


    // Locate the first node with id = 12345.
    // the index for the array can be the indexnumber OR a simple element test (=,>,<,<=,>= are supported)
    pCustomer   = nox_Locate(pCustObject: 'topFive[id=12345]');


    // Note: You have to be carefull with the source is in the right CCSID for RPG to convert the
    // strings ( if they contains national charaters and/or brackets like{}[] )
    // if you run into issues, you can define them as const as in the
    // example below: it is suppose to do the same as abowe
    pCustomer   = nox_Locate(pCustObject: key);

    id          = nox_getInt ( pCustomer : 'id');
    name        = nox_getStr ( pCustomer : 'name');
    street      = nox_getStr ( pCustomer : 'street');
    city        = nox_getStr ( pCustomer : 'city');
    creditLimit = nox_getDec ( pCustomer : 'creditLimit');
    createdDate = nox_getDate( pCustomer : 'createdDate');
    createdTime = nox_getTime( pCustomer : 'createdTime');
    dateTime    = nox_getTS  ( pCustomer : 'dateTime');
    isNice      = nox_getBool( pCustomer : 'isNice');

    // Just to see the progress:
    debug = nox_asJsonText(pCustomer);
    nox_joblog ( debug );

// Note: We always delete everything in our exit handler
// it is OK to delete an already deleted node - it just does nothing
on-exit;
    nox_sqlDisconnect(pCon);
    nox_delete(pCustomer);
    nox_delete(pCustomer2);
    nox_delete(pMoreCust);
    nox_delete(pCustList);
    nox_delete(pRes);
    nox_delete(pCustObject);
    nox_delete(pTopFive);

    if memuse <> nox_memuse();
        nox_joblog('Ups - forgot to clean something up?');
    endif;
end-proc;
