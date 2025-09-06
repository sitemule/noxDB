**FREE
    // ------------------------------------------------------------- 
    // noxDB - Not Only Xml - Its JSON, XML, SQL and more
    //
    // This tutorial will show all the features, from a JSON 
    // and SQL perspective
    //
    // Design:  Niels Liisberg  
    // Project: Sitemule.com
    //
    // try/build:
    // cd '/prj/NOXDBUTF8' 
    // addlible NOXDBUTF8 
    // call 
    // ------------------------------------------------------------- 

    Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE'); 
    Ctl-Opt CCSID(*CHAR:*UTF8) ; //  CCSID(*EXACT) ; // CCSID(*CHAR:*JOBRUN) ; // CCSID(*CHAR:*UTF8);

    /include QRPGLEREF,noxDbUtf8

    dcl-s id           int(10);
    dcl-s name         varchar(256);
    dcl-s street       varchar(256);
    dcl-s city         varchar(256);
    dcl-s creditLimit  packed(15:2);
    dcl-s created      date;

    dcl-s debug        varchar(32766:4);
    dcl-s msg          varchar(256);
    dcl-s len          int(10);
    dcl-s checksum     int(10);
    dcl-s memuse       int(10);
    dcl-s pCustObject  pointer;
    dcl-s pCon         pointer;
    dcl-s pCustomer    pointer;
    dcl-s pCustList    pointer;
    dcl-s pMoreCust    pointer;
    dcl-s pTopFive     pointer;
    dcl-s pRes         pointer;
    dcl-s key          varchar(256) CCSID(*UTF8) inz('topFive[id=12345]');
    
    dcl-ds itList      likeds(nox_iterator);

    //------------------------------------------------------------- *

    *inlr = *on;
    memuse = nox_memUse();

    // Step 1: Lets build a JSON object from scratch
    // and let set some attirbutes on the object. 
    // we use integers, string , fixed float numbers and date 
    pCustomer = nox_newObject();
    nox_setInt (pCustomer:'id'         : 12345);
    nox_setStr (pCustomer:'name'       : 'System & Metod A/S');
    nox_setStr (pCustomer:'street'     : 'Håndværkersvinget 8');
    nox_setStr (pCustomer:'city'       : 'Hørsholm');
    nox_setStr (pCustomer:'greeting'   : u'4f605978'); // "Ni hau" in unicode
    nox_setNum (pCustomer:'creditLimit': 76543.21);
    nox_setDate(pCustomer:'createdDate': %date());
    nox_setTime(pCustomer:'createdTime': %time());
    nox_setTimeStamp(pCustomer:'timeStamp': %timestamp());

    // Just to see the progress:
    nox_WriteJsonStmf(pCustomer : './test/documents/ex01Tutorial-Customer.json' : 1208 : *OFF);    
    debug = nox_asJsonText(pCustomer);


    // Step 2: Build an array with customers
    // note the arrayPush can push it to either head or tail
    pCustList = nox_newArray();
    nox_arrayPush ( pCustList : pCustomer);

    // Just to see the progress:
    debug = nox_asJsonText(pCustList);

    // step3: now we get the rest of customers from the database;
    pCon = nox_sqlConnect();
    pMoreCust = nox_sqlResultSet(pCon:
        'select                       - 
            cusnum  as "id",          -
            lstnam  as "name",        -
            street  as "street",      -
            cdtlmt  as "creditLimit"  -
        from qiws.QCUSTCDT            -
    ');
    nox_sqlDisconnect(pCon);

    // Just to see the progress:
    debug = nox_asJsonText(pMoreCust);

    // now we have the list
    // Note: the MOVE_UNLINK can be used if the array was already 
    // a sub-node in an other object/array. here it just an example and have no effect
    // Also you can omit the result - but returns the receiving array so you can "chain" this function
    // ie "moveObjectInto" 
    pRes  = nox_arrayAppend(pCustList : pMoreCust: NOX_MOVE_UNLINK);  

    // How many are there in the array? 
    len  = nox_getLength(pCustList); 

    // Just to see the progress:
    debug = nox_asJsonText(pCustList);

    // Lets sort the array on highest "creditLimit" and then "name"
    nox_arraySort(pCustList : 'creditLimit:DESC,name:ASC' );   

    // Just to see the progress:
    debug = nox_asJsonText(pCustList);


    // I only want the first 5
    // Note the first element is = 0
    // You can also use NOX_MOVE_UNLINK, to carve the result out of the source
    // however, here we copy the elements to a new array  
    pTopFive = nox_arraySlice(pCustList : 0: 5 : NOX_COPY_CLONE);         

    // Just to see the progress:
    debug = nox_asJsonText(pTopFive);

    // we can caluculate the checksum, to see later if anyone have touched the object graph
    checksum = nox_NodeCheckSum(pTopFive);   

    // and save it to disk:
    // You can use UTF8_BOM if you need the BOM-siganture
    nox_WriteJsonStmf(pTopFive : './test/documents/ex01Tutorial.json' : 1208 : *OFF);    

    // Now what do we need to clean up:
    // pCustList? yes 
    // pCustomer? no - it is already removed when deleting the pCustList
    // pTopFive? Yes - it is a clone
    nox_delete(pCustList); 
    nox_delete(pTopFive); 

    // We could stop the program here - But let's have som more fun:
    // Load the top five array 
    pTopFive = nox_ParseFile ('./test/documents/ex01Tutorial.json');

    // Just to see the progress:
    debug = nox_asJsonText(pTopFive);

    // Was there som issues?        
    if Nox_Error(pTopFive) ;
        msg = Nox_Message(pTopFive);
        Nox_dump(pTopFive);
        Nox_delete(pTopFive);
        return;
    endif;

    // Is the checksum the same? 
    if checksum <> nox_NodeCheckSum(pTopFive);
        dsply 'Invlaid checksum';
    endif;   

    // now create a object with that array and call it "topFive":
    pCustObject = nox_newObject();
    nox_moveObjectInto (pCustObject: 'topFive': pTopFive );

    // Just to see the progress:
    debug = nox_asJsonText(pCustObject);

    // let's loop through all items and get them back to RPG variables:
    // note: we could have used pTopFive - but for fun we locate from the top
    itList = nox_setIterator(pCustObject : 'topFive');      
    dow nox_ForEach(itList);        
        id          = nox_getInt ( itList.this : 'id');
        name        = nox_getStr ( itList.this : 'name');
        street      = nox_getStr ( itList.this : 'street');
        city        = nox_getStr ( itList.this : 'city');
        creditLimit = nox_getNum ( itList.this : 'creditLimit');
        createdDate = nox_getDate( itList.this : 'createdDate');
        createdTime = nox_getTime( itList.this : 'createdTime');
        dateTime    = nox_getTimeStamp( itList.this : 'timeStamp');
    enddo;    


    // Locate the first node with id = 593029. 
    // the indexfor the array can be the indexnumber OR a simple element test (=,>,<,<=,>= are supported)
    pCustomer   = Nox_Locate(pCustObject: 'topFive[id=12345]');


    // Note: You have to be carefull with the source is in the right CCSID for ROG to convert the
    // strings ( if they contains national charater s and/or brackets like{}[] )
    // if you run into issues, you can define them as const as in the 
    // example below: it is suppose to do the same as abowe
    pCustomer   = Nox_Locate(pCustObject: key);

    id          = nox_getInt ( pCustomer : 'id');
    name        = nox_getStr ( pCustomer : 'name');
    street      = nox_getStr ( pCustomer : 'street');
    city        = nox_getStr ( pCustomer : 'city');
    creditLimit = nox_getNum ( pCustomer : 'creditLimit');
    created     = nox_getDate( pCustomer : 'created');
    createdDate = nox_getDate( pCustomer : 'createdDate');
    createdTime = nox_getTime( pCustomer : 'createdTime');
    dateTime    = nox_getTimeStamp( pCustomer : 'timeStamp');

    // Just to see the progress:
    debug = nox_asJsonText(pCustomer);

    // That's it - time to cleanup:
    nox_delete(pCustomer);

    if memuse <> nox_memuse();
        dsply 'Ups - forgot to clean something up';
    endif;   

    Return;