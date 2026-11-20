**FREE
// Target program for test/callpgm.rpgle (PCML 7.0 copy): nox_CallProgram maps the JSON
// payload onto these parameters by the PCML compiled into the program,
// calls it, and returns the inputoutput parameters as JSON.
//   gmake test/calltgt.rpgle --always-make
ctl-opt pgminfo(*PCML:*MODULE:*V7)
        option(*srcstmt : *nodebugio : *nounref)
        dftactgrp(*no) actgrp(*caller)
        main(main);

dcl-ds employee_t qualified template;
    id        int(10);
    name      char(30);
    income    packed(9:2);
    tags      char(5) dim(3);
end-ds;

dcl-proc main;
    dcl-pi *n;
        name      char(10)     const;
        text      char(50);
        age       packed(5:0);
        amount    zoned(9:2);
        count     int(10);
        big       int(20);
        uns       uns(10);
        flag      ind;
        birth     date(*iso);
        birthEur  date(*eur);
        at        time(*iso);
        stamp     timestamp;
        vc        varchar(40);
        list      char(5) dim(3);
        emp       likeds(employee_t);
    end-pi;

    dcl-s tmp char(5);

    text     = 'Hello ' + %trim(name) + ' זרו';
    age     += 1;
    amount  *= 2;
    count   += 1;
    big      = -big;
    uns     += 1;
    flag     = not flag;
    birth   += %days(1);
    birthEur+= %days(1);
    at      += %hours(1);
    stamp   += %seconds(1);
    vc       = vc + '!';
    tmp      = list(1);
    list(1)  = list(3);
    list(3)  = tmp;
    emp.id      += 1;
    emp.name     = %trim(emp.name) + ' ״';
    emp.income  += 100;
    emp.tags(2)  = 'two';
end-proc;
