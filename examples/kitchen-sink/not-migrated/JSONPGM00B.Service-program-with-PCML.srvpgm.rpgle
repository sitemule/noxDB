**FREE

///
// This example shows how traditional service programs compiled with
//    ctl-opt pgminfo(*PCML:*MODULE:*DCLCASE:*V8);
// can be dynamically called from a noxDb
//
// Adding an extra thread(*CONCURRENT) to the ctl-opt
// it can even be used with ILEastic, and also serve the openAPI.json ( yet to come)
// My compiler is complaining with:
//    ctl-opt pgminfo(*PCML:*MODULE:*DCLCASE:*V8)
// The parameter for keyword PGMINFO is not *DCLCASE, *MODULE, *V6, or *V7.
// Enven on V7R5, the default is *V8, so you can use that.
///
ctl-opt pgminfo(*PCML:*MODULE:*DCLCASE:*V7);
ctl-opt thread(*CONCURRENT);
ctl-opt nomain;
ctl-opt copyright('Sitemule.com (C), 2023-2025');
ctl-opt decEdit('0,') datEdit(*YMD.);
ctl-opt debug(*yes);

// anonymous !! Experimental !!!
// anonymous array, will take the values from the anonumous input array
// and receive and return it without object structure arround it.
// The trick is to sufix with 3 under scores:
dcl-ds anonymousArray_t template qualified;
    intArray___  int(5)   dim(2) ;
end-ds;

// regular array - always received and send with the object structure around it
dcl-ds intArray_t template qualified;
    intArray  int(5)   dim(2) ;
end-ds;


dcl-ds employee_t template qualified;
    id        int(10);
    name      char(50);
    age       int(10);
    income    packed(9:2);
    birthDate date;
    birthTime time;
    updated   timestamp;
    isMale    ind;
end-ds;

// The template for the customer  structure
dcl-ds customer_t    extname('QIWS/QCUSTCDT') qualified template end-ds;

// *VAR and *AUTO array of customers - need some stuff from IBM, notsupported yet
dcl-ds customerList_t    extname('QIWS/QCUSTCDT') dim(*var:20) qualified template end-ds;

// Nested customer structure
dcl-ds CustomerNested_t qualified template;
    id   packed(8: 0);
    name varchar(30);
    dcl-ds cmsInfo;
        creditLimit uns(10);
        chargeCode  packed(1);
        balanceDue  zoned(10:2);
        creditDue   packed(9:2);
    end-ds;
    dcl-ds address;
        Street char(30);
        City   char(30);
        State  char(2);
        Postal char(10);
    end-ds;
end-ds;


// ------------------------------------------------------------------------------------
// nameage
// ------------------------------------------------------------------------------------
dcl-proc nameAge export;

    dcl-pi nameAge extproc(*dclcase);
        Name char (10) const;
        Text char(200);
        Age  packed(5:0);
    end-pi;

    text = 'hello ' + name;
    age = 25;
    return;

end-proc;
dcl-proc allTypes export;

    dcl-pi allTypes extproc(*dclcase);
        char      char (10);
        varchar   varchar (10);
        int8     int(20);
        int4     int(10);
//        int2     int(3);
        uns8     uns(20);
        uns4     uns(10);
        uns2     uns(3);
        packed  packed(9:2);
        zoned   zoned(9:2);
        ind     ind;
        date    date;
        time    time;
        timestamp    timestamp;
    end-pi;

    char    = 'xyz';
    varchar = 'Test';
    int8     = -456789012345;
    int4     = -56789;
//    int2     = -127;
    uns8     = 456789012345;
    uns4     = 56789;
    uns2     = 255;
    packed  = -987.65;
    zoned   = -8765.43;
    ind     = *OFF;
    date    = %date();
    time    = %time();
    timestamp   = %timestamp();

    return;


end-proc;

// ------------------------------------------------------------------------------------
dcl-proc complex export;

    dcl-pi complex extproc(*dclcase) ;
        id        int(10) const ;
        employee  likeds(employee_t) ;
    end-pi;

    employee.id = id;
    employee.name = 'John Doe';
    employee.age = 25;
    employee.income = 12345.67;
    employee.birthDate = %date();
    employee.birthTime = %time();
    employee.updated = %timestamp();
    employee.isMale = *on;
end-proc;
// ------------------------------------------------------------------------------------
dcl-proc echo export;

    dcl-pi echo extproc(*dclcase) ;
        employeeIn   likeds(employee_t) const;
        employeeOut  likeds(employee_t) ;
    end-pi;

    employeeOut = employeeIn;

end-proc;

// ------------------------------------------------------------------------------------
dcl-proc simpleArray export;

    dcl-pi simpleArray extproc(*dclcase);
        myArrayIn  int(5)   dim(5) const;
        myArrayOut char(5)  dim(5) ;
    end-pi;

    dcl-s i int(5);

    // Copy the input to the output in reveser order
    for i = 1 to %elem(myArrayOut);
        myArrayOut(6-i) = %char(myArrayIn(i));
    endfor;

end-proc;

// ------------------------------------------------------------------------------------
dcl-proc nestedArray export;

    dcl-pi nestedArray extproc(*dclcase);
        myArrayIn  likeds(intArray_t) dim(5) const;
        myArrayOut likeds(intArray_t) dim(5) ;
    end-pi;


    dcl-s i int(5);
    dcl-s j int(5);

    // Copy the input to the output in reveser order
    for i = 1 to %elem(myArrayOut);
        for j = 1 to %elem(myArrayOut.intArray);
            myArrayOut(6-i).intArray(3-j) = myArrayIn(i).intArray(j);
        endfor;
    endfor;

end-proc;

// ------------------------------------------------------------------------------------
// Annoymous array, will take the values from the anonumous input array
// and receive and return it without object structure arround it.
// The trick ire to sufix with 3 under scores:
dcl-proc anonymousArray export;

    dcl-pi anonymousArray extproc(*dclcase);
        myArrayIn___  likeds(anonymousArray_t) dim(5) const;
        myArrayOut___ likeds(anonymousArray_t) dim(5) ;
    end-pi;

    dcl-s i int(5);
    dcl-s j int(5);

    // Copy the input to the output in reveser order
    for i = 1 to %elem(myArrayIn___);
        for j = 1 to %elem(myArrayIn___.intArray___);
            myArrayOut___(6-i).intArray___(3-j) = myArrayIn___(i).intArray___(j);
        endfor;
    endfor;

end-proc;


// ------------------------------------------------------------------------------------
dcl-proc customer  export;

    dcl-pi customer extproc(*dclcase) ;
        customerIn   likeds(customer_t) dim(20) const;
        customerOut  likeds(customer_t) dim(20);
    end-pi;

    // Copy the input to the output
    // Note that the input is an array of 20 elements, so we copy all
    // we do some magic later.
    customerOut = customerIn;

end-proc;

// ------------------------------------------------------------------------------------
// *VAR and *AUTO need some stuff from IBM
// Not supported yet
// ------------------------------------------------------------------------------------
dcl-proc customerVar  export;

    dcl-pi customerVar extproc(*dclcase) ;
        customerIn   likeds(customerList_t) const options(*varsize);
        customerOut  likeds(customerList_t) options(*varsize);
    end-pi;

    // Copy the input to the output
    // Note that the input is an array of 20 elements, so we copy all
    // we do some magic later.

    customerOut = customerIn;
    // %elem(customerOut) = 2;

end-proc;

// ------------------------------------------------------------------------------------
dcl-proc customerNested  export;

    dcl-pi customerNested extproc(*dclcase) ;
        customerIn   likeds(customerNested_t) const;
        customerOut  likeds(customernested_t) ;
    end-pi;

    // Copy the input to the output
    // Note that the input is an array of 20 elements, so we copy all
    // we do some magic later.
    customerOut = customerIn;

end-proc;

// ------------------------------------------------------------------------------------
dcl-proc customerNestedList  export;

    dcl-pi customerNestedList extproc(*dclcase) ;
        customerIn   likeds(customerNested_t) dim(20) const;
        customerOut  likeds(customernested_t) dim(20);
    end-pi;

    // Copy the input to the output
    // Note that the input is an array of 20 elements, so we copy all
    // we do some magic later.
    customerOut = customerIn;

end-proc;

// ------------------------------------------------------------------------------------
// Input is an object, but resule is an array of objects
// This is a bit tricky, as the input is an object, but the output is an
// array of objects.
// notice the sufix with 3 under scores, this is a trick to make it anonymous
// ------------------------------------------------------------------------------------
dcl-proc customerAnonymousArray  export;

    dcl-pi customerAnonymousArray extproc(*dclcase) ;
        customerIn      likeds(customerNested_t) dim(20) const;
        customerOut___  likeds(customernested_t) dim(20);
    end-pi;

    // Copy the input to the output
    // Note that the input is an array of 20 elements, so we copy all
    // we do some magic later.
    customerOut___ = customerIn;

end-proc;
