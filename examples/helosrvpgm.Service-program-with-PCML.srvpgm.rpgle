**FREE

///
// Routing to a program adding openAPI ( swagger)
//
// This example shows how traditional programs compiled with
//    ctl-opt pgminfo(*PCML:*MODULE) thread(*CONCURRENT);
// can be used with ILEastic, and also serve the openAPI.json ( yet to come)
//
// The routing is shown in swagroute.rpgle
//
// Start it:
// SBMJOB CMD(CALL PGM(SWAGROUTE)) JOB(SWAGROUTE) JOBQ(QSYSNOMAX) ALWMLTTHD(*YES)
//
// The web service can be tested with the browser by entering the following URL:
// http://my_ibm_i:44045/hello?name=john
//
// @info: It requires your RPG code to be reentrant and compiled for
//        multithreading. Each client request is handled by a seperate thread.
///
ctl-opt pgminfo(*PCML:*MODULE:*DCLCASE) thread(*CONCURRENT);
ctl-opt nomain;
ctl-opt copyright('Sitemule.com  (C), 2023');
ctl-opt decEdit('0,') datEdit(*YMD.);
ctl-opt debug(*yes);

dcl-ds employee_t template;
    id        int(10);
    name      char(50);
    age       int(3);
    income    packed(9:2);
    birthDate date;
    birthTime time;
    updated   timestamp;
end-ds;
// ------------------------------------------------------------------------------------
// nameage
// ------------------------------------------------------------------------------------
dcl-proc nameage export;

    dcl-pi nameage ;
        name char (10) const;
        text char(200);
        age  packed(5:0);
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
dcl-proc alltypes export;

    dcl-pi alltypes ;
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

dcl-proc complex export;

    dcl-pi *n ;
        id        int(10) const ;
        employee  likeds(employee_t);
    end-pi;

    // clear employee;
    // employee.id = id;
    // employee.name = 'John Doe';
    // employee.age = 25;
    // employee.income = 12345.67;
    // employee.birthDate = %date();
    // employee.birthTime = %time();
    // employee.updated = %timestamp();
    // employee.isMale = *on;
//
    return ;
end-proc;
