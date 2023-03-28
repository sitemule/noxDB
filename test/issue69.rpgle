**free
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

/include 'headers/JSONPARSER.rpgle'

test0();
test1();
test2();
*INLR = *ON;

// ------------------------------------------------------------------------------------
// test0
// ------------------------------------------------------------------------------------
dcl-proc test0;


    dcl-ds params qualified inz;
        s  char(10) inz;
    end-ds;

    dcl-s pfrom pointer;

    pFrom = json_parseString ('{-
        "s":null  -
    }');

    data-into params %data ('':'allowextra=yes allowmissing=yes case=any') %parser(json_DataInto(pFrom));
    json_delete(pFrom);


end-proc;
// ------------------------------------------------------------------------------------
// test1
// ------------------------------------------------------------------------------------
dcl-proc test1;


    dcl-ds params qualified inz;
        s  char(10) inz;
    end-ds;

    dcl-s pfrom pointer;

    pFrom = json_parseString ('{-
        "s":"Life is a gift" -
    }');


    data-into params %data ('':'allowextra=yes allowmissing=yes case=any') %parser(json_DataInto(pFrom));
    json_delete(pFrom);

    pFrom = json_parseString ('{-
        "s":"" -
    }');


    data-into params %data ('':'allowextra=yes allowmissing=yes case=any') %parser(json_DataInto(pFrom));
    json_delete(pFrom);


end-proc;
// ------------------------------------------------------------------------------------
// test2
// ------------------------------------------------------------------------------------
dcl-proc test2;

    dcl-ds params qualified inz;
    s  char(10)           inz;
    a likeds(a_t) inz(*likeds);
    end-ds;

    dcl-ds a_t qualified template;
    o likeds(o_t) dim(99) inz(*likeds);
    end-ds;

    dcl-ds o_t qualified template;
    b char(100) inz;
    c char(100) inz;
    end-ds;

    dcl-s pfrom pointer;

    //--------------------------------------------------------------------
    pFrom = json_parseString ('{    -
    "s":"Life is a gift",        -
    "a":{                        -
        "o":[                     -
            {                      -
                "b":"hello world",  -
                "c":" "             -
            },                     -
            {                      -
                "b":"hello world",  -
                "c":" "             -
            },                     -
            {                      -
                "b":"hello world",  -
                "c":" "             -
            }                      -
        ]                         -
    }                            -
    }');


    // works fine
    data-into params %data ('':'allowextra=yes allowmissing=yes case=any') %parser(json_DataInto(pFrom));
    json_delete(pFrom);


    pFrom = json_parseString ('{    -
    "s":"Life is a gift",        -
    "a":{                        -
        "o":[                     -
            {                      -
                "b":"hello world",  -
                "c":""              -
            },                     -
            {                      -
                "b":"hello world",  -
                "c":""              -
            },                     -
            {                      -
                "b":"hello world",  -
                "c":""              -
            }                      -
        ]                         -
    }                            -
    }');


    // crash!
    data-into params %data ('':'allowextra=yes allowmissing=yes case=any') %parser(json_DataInto(pFrom));
    json_delete(pFrom);

end-proc;
