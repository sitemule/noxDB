**FREE
// CMD:CRTRPGMOD
// Target service program for test/callpgm.rpgle (nox_CallProcedure).
// Build: gmake test/callsrv.rpgle --always-make, then
//   CRTSRVPGM SRVPGM(<lib>/CALLSRV) MODULE(<lib>/CALLSRV) EXPORT(*ALL)
ctl-opt nomain pgminfo(*PCML:*MODULE)
        option(*srcstmt : *nodebugio : *nounref);

dcl-proc greet export;
    dcl-pi *n;
        name   varchar(30) const;
        text   varchar(60);
        times  int(10);
    end-pi;
    text  = 'Hej ' + name + ' fra Ærø';
    times = times * 2;
end-proc;

dcl-proc addDays export;
    dcl-pi *n;
        start  date(*iso) const;
        days   int(10)    const;
        result date(*iso);
    end-pi;
    result = start + %days(days);
end-proc;
