**FREE

///
// This example shows how traditional service programs compiled with
//    ctl-opt pgminfo(*PCML:*MODULE:*DCLCASE:*V8);
// can be dynamically called from a noxDb
//
// Adding an extra thread(*CONCURRENT) to the ctl-opt
// it can even be used with ILEastic, and also serve the openAPI.json ( yet to come)
// My copiler is complaining with:
//    ctl-opt pgminfo(*PCML:*MODULE:*DCLCASE:*V8)
// The parameter for keyword PGMINFO is not *DCLCASE, *MODULE, *V6, or *V7.
// Enven on V7R5, the default is *V8, so you can use that.
///
ctl-opt pgminfo(*PCML:*MODULE:*DCLCASE:*V7) thread(*CONCURRENT);
ctl-opt nomain;
ctl-opt copyright('Sitemule.com (C), 2023-2025');
ctl-opt decEdit('0,') datEdit(*YMD.);
ctl-opt debug(*yes);

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

// ------------------------------------------------------------------------------------
// alltypes - following produces:
//  <?xml version="1.0" encoding="UTF-8" ?>
//  <pcml version="6.0">
//    <program name="ALLTYPES" entrypoint="ALLTYPES">
//      <data name="CHAR" type="char" length="10" usage="inputoutput"/>
//      <struct name="VARCHAR" outputsize="12" usage="inputoutput">
//        <data name="length" type="int" length="2" precision="16" usage="inherit"/>
//        <data name="string" type="char" length="length" usage="inherit"/>
//      </struct>
//      <data name="INT8" type="int" length="8" precision="63" usage="inputoutput"/>
//      <data name="INT4" type="int" length="4" precision="31" usage="inputoutput"/>
//      <data name="UNS8" type="int" length="8" precision="64" usage="inputoutput"/>
//      <data name="UNS4" type="int" length="4" precision="32" usage="inputoutput"/>
//      <data name="UNS2" type="byte" length="1" usage="inputoutput"/>
//      <data name="PACKED" type="packed" length="9" precision="2" usage="inputoutput"/>
//      <data name="ZONED" type="zoned" length="9" precision="2" usage="inputoutput"/>
//      <data name="IND" type="char" length="1" usage="inputoutput"/>
//      <data name="DATE" type="date" dateformat="ISO" dateseparator="hyphen" usage="inputoutput"/>
//      <data name="TIME" type="time" timeformat="ISO" timeseparator="period" usage="inputoutput"/>
//      <data name="TIMESTAMP" type="timestamp" usage="inputoutput"/>
//    </program>
//    <program name="NAMEAGE" entrypoint="NAMEAGE">
//      <data name="NAME" type="char" length="10" usage="input"/>
//      <data name="TEXT" type="char" length="200" usage="inputoutput"/>
//      <data name="AGE" type="packed" length="5" precision="0" usage="inputoutput"/>
//    </program>
//  </pcml>
// ------------------------------------------------------------------------------------
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
dcl-proc simpleNestedArray export;

    dcl-pi simpleNestedArray extproc(*dclcase);
        myArrayIn  likeds(intArray_t) dim(5) const;
        myArrayOut likeds(intArray_t) dim(5) ;
    end-pi;

    dcl-ds intArray_t template qualified;
        intArray  int(5)   dim(2) ;
    end-ds;

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
dcl-proc customer  export;

    dcl-pi customer extproc(*dclcase) ;
        customerIn   likeds(customer_t) dim(100) const;
        customerOut  likeds(customer_t) dim(100);
    end-pi;

    // Copy the input to the output
    // Note that the input is an array of 100 elements, so we copy all
    // we do some magic later.
    customerOut = customerIn;

end-proc;
