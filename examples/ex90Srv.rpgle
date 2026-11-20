**FREE
// CMD:CRTRPGMOD
// ------------------------------------------------------------------------------------
// noxDB - Not Only Xml - Its JSON, XML, SQL and more
//
// Demo 90 - the service program that ex90Call calls by its PCML.
//
// Again plain RPG with pgminfo(*PCML:*MODULE). nox_CallProcedure maps the
// parameters - not a return value - so results go in parameters.
//
// try/build:
// cd '/prj/NOXDBUTF8'
// addlible NOXDBUTF8
// chgjob ccsid(500)
// gmake examples/ex90Srv.rpgle --always-make
// CRTSRVPGM SRVPGM(NOXDBUTF8/EX90SRV) MODULE(NOXDBUTF8/EX90SRV) EXPORT(*ALL)
// ------------------------------------------------------------------------------------
Ctl-Opt copyright('Sitemule - System & Method (C), 2026');
Ctl-Opt nomain pgminfo(*PCML:*MODULE);
Ctl-Opt option(*nodebugio:*srcstmt:*nounref);

// ------------------------------------------------------------------------------------
// Greet in a language: national characters go both ways
// ------------------------------------------------------------------------------------
dcl-proc greeting export;
    dcl-pi *n;
        name      varchar(50)  const;
        language  char(2)      const;
        text      varchar(100);
    end-pi;

    select;
        when language = 'da';
            text = 'Hej ' + name + ' - velkommen på Ærø';
        when language = 'de';
            text = 'Grüß Gott ' + name;
        other;
            text = 'Hello ' + name;
    endsl;
end-proc;
