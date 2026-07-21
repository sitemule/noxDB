**free
///
// This example shows how traditional programs compiled with
//    ctl-opt pgminfo(*PCML:*MODULE:*DCLCASE:*V8);
// can be dynamically called from a noxDb
//
// Adding an extra thread(*CONCURRENT) to the ctl-opt
// it can even be used with ILEastic, and also serve the openAPI.json ( yet to come)
//
// My compiler is complaining with:
//    ctl-opt pgminfo(*PCML:*MODULE:*DCLCASE:*V8)
// The parameter for keyword PGMINFO is not *DCLCASE, *MODULE, *V6, or *V7.
// Enven on V7R5, the default is *V8, so you can use that.

///
ctl-opt pgminfo(*PCML:*MODULE:*DCLCASE:*V7);
ctl-opt copyright('Sitemule.com (C), 2023-2025');
ctl-opt decEdit('0,') datEdit(*YMD.);
ctl-opt debug(*yes);

dcl-pi *N;
    Name char (10) const;
    Text char(200);
    Age  packed(5:0);
end-pi;

text = 'hello ' + name;
age = 44;
return;
