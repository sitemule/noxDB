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
    // cd '/prj/noxdb2' 
    // addlible noxdb2 
    // call 
    // ------------------------------------------------------------- 

    Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE'); 
    Ctl-Opt CCSID(*CHAR:*UTF8) ; //  CCSID(*EXACT) ; // CCSID(*CHAR:*JOBRUN) ; // CCSID(*CHAR:*UTF8);


    //------------------------------------------------------------- *

    /include 'headers/noxDB2JSON.rpgle'

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
    
    dcl-ds itList      likeds(json_iterator);

    //------------------------------------------------------------- *

    *inlr = *on;
    memuse = json_memUse();

    // Step 1: Lets build a JSON object from scratch
    // and let set some attirbutes on the object. 
    // we use integers, string , fixed float numbers and date 
    pCustomer = json_newObject();
    json_setInt (pCustomer:'id'         : 12345);
    json_setStr (pCustomer:'name'       : 'System & Metod A/S');
    json_setStr (pCustomer:'street'     : 'Håndværkersvinget 8');
    json_setStr (pCustomer:'city'       : 'Hørsholm');
    json_setStr (pCustomer:'greeting'   : u'4f605978'); // "Ni hau" in unicode
    json_setNum (pCustomer:'creditLimit': 76543.21);
    json_setDate(pCustomer:'created'    : %date());

    // Just to see the progress:
    json_WriteJsonStmf(pCustomer : './test/documents/ex01Tutorial-Customer.json' : 1208 : *OFF);    
    debug = json_asJsonText(pCustomer);


    // Step 2: Build an array with customers
    // note the arrayPush can push it to either head or tail
    pCustList = json_newArray();
    json_arrayPush ( pCustList : pCustomer);

    // Just to see the progress:
    debug = json_asJsonText(pCustList);

    // step3: now we get the rest of customers from the database;
    pCon = json_sqlConnect();
    pMoreCust = json_sqlResultset(pCon:
        'select                       - 
            cusnum  as "id",          -
            lstnam  as "name",        -
            street  as "street",      -
            cdtlmt  as "creditLimit"  -
        from qiws.QCUSTCDT            -
    ');
    json_sqlDisconnect(pCon);

    // Just to see the progress:
    debug = json_asJsonText(pMoreCust);

    // now we have the list
    // Note: the MOVE_UNLINK can be used if the array was already 
    // a sub-node in an other object/array. here it just an example and have no effect
    // Also you can omit the result - but returns the receiving array so you can "chain" this function
    // ie "moveObjectInto" 
    pRes  = json_arrayAppend(pCustList : pMoreCust: JSON_MOVE_UNLINK);  

    // How many are there in the array? 
    len  = json_getLength(pCustList); 

    // Just to see the progress:
    debug = json_asJsonText(pCustList);

    // Lets sort the array on highest "creditLimit" and then "name"
    json_arraySort(pCustList : 'creditLimit:DESC,name:ASC' );   

    // Just to see the progress:
    debug = json_asJsonText(pCustList);


    // I only want the first 5
    // Note the first element is = 0
    // You can also use JSON_MOVE_UNLINK, to carve the result out of the source
    // however, here we copy the elements to a new array  
    pTopFive = json_arraySlice(pCustList : 0: 5 : JSON_COPY_CLONE);         

    // Just to see the progress:
    debug = json_asJsonText(pTopFive);

    // we can caluculate the checksum, to see later if anyone have touched the object graph
    checksum = json_NodeCheckSum(pTopFive);   

    // and save it to disk:
    // You can use UTF8_BOM it you need the BOM-siganture
    json_WriteJsonStmf(pTopFive : './test/documents/ex01Tutorial.json' : 1208 : *OFF);    

    // Now what do we need to clean up:
    // pCustList? yes 
    // pCustomer? no - it is already removed when deleting the pCustList
    // pTopFive? Yes - it is a clone
    json_delete(pCustList); 
    json_delete(pTopFive); 

    // We could stop the program here - But let's have som more fun:
    // Load the top five array 
    pTopFive = json_ParseFile ('./test/documents/ex01Tutorial.json');

    // Just to see the progress:
    debug = json_asJsonText(pTopFive);

    // Was there som issues?        
    if Json_Error(pTopFive) ;
        msg = Json_Message(pTopFive);
        Json_dump(pTopFive);
        Json_delete(pTopFive);
        return;
    endif;

    // Is the checksum the same? 
    if checksum <> json_NodeCheckSum(pTopFive);
        dsply 'Invlaid checksum';
    endif;   

    // now create a object with that array and call it "topFive":
    pCustObject = json_newObject();
    json_moveObjectInto (pCustObject: 'topFive': pTopFive );

    // Just to see the progress:
    debug = json_asJsonText(pCustObject);

    // let's loop through all items and get them back to RPG variables:
    // note: we could have used pTopFive - but for fun we locate from the top
    itList = json_setIterator(pCustObject : 'topFive');      
    dow json_ForEach(itList);        
        id          = json_getInt ( itList.this : 'id');
        name        = json_getStr ( itList.this : 'name');
        street      = json_getStr ( itList.this : 'street');
        city        = json_getStr ( itList.this : 'city');
        creditLimit = json_getNum ( itList.this : 'creditLimit');
        created     = json_getDate( itList.this : 'created');
    enddo;    


    // Locate the first node with id = 593029. 
    // the indexfor the array can be the indexnumber OR a simple element test (=,>,<,<=,>= are supported)
    pCustomer   = Json_Locate(pCustObject: 'topFive[id=12345]');


    // Note: You have to be carefull with the source is in the right CCSID for ROG to convert the
    // strings ( if they contains national charater s and/or brackets like{}[] )
    // if you run into issues, you can define them as const as in the 
    // example below: it is suppose to do the same as abowe
    pCustomer   = Json_Locate(pCustObject: key);

    id          = json_getInt ( pCustomer : 'id');
    name        = json_getStr ( pCustomer : 'name');
    street      = json_getStr ( pCustomer : 'street');
    city        = json_getStr ( pCustomer : 'city');
    creditLimit = json_getNum ( pCustomer : 'creditLimit');
    created     = json_getDate( pCustomer : 'created');

    // Just to see the progress:
    debug = json_asJsonText(pCustomer);

    // That's it - time to cleanup:
    json_delete(pCustomer);

    if memuse <> json_memuse();
        dsply 'Ups - forgot to clean something up';
    endif;   

    Return;