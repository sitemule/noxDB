**FREE
// CMD:CRTRPGMOD
// Target service program for test/callpgm.rpgle (PCML 7.0 copy) (nox_CallProcedure).
// Build: gmake test/callsrv.rpgle --always-make, then
//   CRTSRVPGM SRVPGM(<lib>/CALLSRV7) MODULE(<lib>/CALLSRV7) EXPORT(*ALL)
ctl-opt nomain pgminfo(*PCML:*MODULE:*V7)
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
