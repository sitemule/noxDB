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

dcl-proc customerNested  export;

    dcl-pi customerNested extproc(*dclcase) ;
        customerIn   likeds(customerNested_t) dim(20) const;
        customerOut  likeds(customernested_t) dim(20);
    end-pi;

    // Copy the input to the output
    // Note that the input is an array of 20 elements, so we copy all
    // we do some magic later.
    customerOut = customerIn;

end-proc;
