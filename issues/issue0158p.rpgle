**FREE
// Issue 158: the program issue0158.rpgle calls with JSON - a payroll raise.
//
// A plain RPG program: the only thing it needs is pgminfo(*PCML:*MODULE).
// - One data structure parameter: when the payload has no element named
//   "payroll", the whole payload is mapped onto it.
// - "employees" is an array of 50, "employees_LENGTH" says how many are used.
//   noxDB fills it in from the number of elements the payload has, and returns
//   only that many - the _LENGTH field itself is not returned.
//
//   gmake issues/issue0158p.rpgle --always-make
ctl-opt pgminfo(*PCML:*MODULE)
        option(*srcstmt : *nodebugio : *nounref)
        dftactgrp(*no) actgrp(*caller)
        main(main);

dcl-ds employee_t qualified template;
    name       char(30);
    salary     packed(9:2);
    newSalary  packed(9:2);
end-ds;

dcl-ds payroll_t qualified template;
    percent           packed(5:2);
    employees         likeds(employee_t) dim(50);
    employees_LENGTH  int(10);
    total             packed(11:2);
    raisedAt          timestamp;
end-ds;

dcl-proc main;
    dcl-pi *n;
        payroll  likeds(payroll_t);
    end-pi;

    dcl-s i int(10);

    payroll.total = 0;
    for i = 1 to payroll.employees_LENGTH;
        payroll.employees(i).newSalary =
            payroll.employees(i).salary * (100 + payroll.percent) / 100;
        payroll.total += payroll.employees(i).newSalary;
    endfor;
    payroll.raisedAt = %timestamp();
end-proc;
