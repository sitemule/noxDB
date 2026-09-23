**free
Ctl-Opt copyright('Sitemule - System & Method (C), 2025');
Ctl-Opt BndDir('NOXDBUTF8') CCSID(*CHAR:*UTF8);
Ctl-Opt dftactgrp(*NO) ACTGRP('QILE') option(*nodebugio:*srcstmt:*nounref) ALWNULL(*USRCTL);
Ctl-Opt main(main) ;

/include qrpgleref,noxDbUtf8

// ------------------------------------------------------------------------------------
dcl-proc main;

    nox_Assert ('Start issue112') ;

    // Support for ../ to travel upwards

    test_up1();
    test_up2();

    nox_Assert ('End issue112') ;

end-proc;
// ------------------------------------------------------------------------------------
// test_up1
// ------------------------------------------------------------------------------------
dcl-proc test_up1;

    dcl-s MemStart int(20);
    dcl-s MemNow   int(20);
    dcl-s pRoot  pointer;
    dcl-s pA pointer;
    dcl-s pB pointer;


    MemStart = nox_memUse();

    pRoot = nox_Object (
        'a' : 'a' :
        'b' : nox_Object(
            'x':nox_int(100):
            'y':nox_int(200)
        )
    );

    pA = nox_locate (pRoot : '/a');
    nox_Assert ( 'a = "a"' : nox_getstr(pA) = 'a' );

    // this goes one up and down to b:
    pB = nox_locate (pA : '../b');
    nox_Assert ( 'b.x=100' : nox_getint(pB : 'x') = 100 );

    // this goes directly to b.y
    nox_Assert ( 'b.y=200' : nox_getint(pRoot : '/b.y') = 200 );

// Always clearn up
on-exit;
    nox_delete(pRoot);
    MemNow  = nox_memUse();
    nox_Assert ( 'Mem leak' : MemNow = MemStart);
end-proc;


// ------------------------------------------------------------------------------------
// test_up2 - object having array of objects
// ------------------------------------------------------------------------------------
dcl-proc test_up2;

    dcl-s MemStart int(20);
    dcl-s MemNow   int(20);
    dcl-s pRoot  pointer;
    dcl-s pA pointer;
    dcl-s pB pointer;


    MemStart = nox_memUse();

    pRoot = nox_Object (
        'a' : nox_str('a') :
        'b' : nox_Array(
            nox_Object(
                'x':nox_int(100):
                'y':nox_int(200)
            ):
            nox_Object(
                'x':nox_int(300):
                'y':nox_int(400)
            )
        ):
        'c' : nox_str('c'):
        'funny object' : nox_Object(
            'funny name' : nox_str('funny value')
        )
    );

    pA = nox_locate (pRoot : '/a');
    nox_Assert ( 'a = "a"' : nox_getstr(pA) = 'a' );

    // this goes one up and down to b:
    pB = nox_locate (pA : '../b[y=400]');
    nox_Assert ( 'b.x=300' : nox_getint(pB : 'x') = 300 );

    // this goes directly to b.y via the root
    nox_Assert ( '/b[y=400].x' : nox_getint(pRoot : '/b[y=400].x') = 300 );

    // Must have same effect since we are on the root
    nox_Assert ( 'b[y=400].x' : nox_getint(pRoot : 'b[y=400].x') = 300 );

    // Find by index: 0 is first, 1= second
    nox_Assert ( 'b[1].x' : nox_getint(pRoot : 'b[1].x') = 300 );

    // Upper boundary is number of elements:
    nox_Assert ( 'b[UBOUND]' : nox_getint(pRoot : 'b[UBOUND]') = 2);

    // Upper boundary is number of elements:
    nox_Assert ( '"funny object"."funny name"' : nox_getstr(pRoot : '"funny object"."funny name"') = 'funny value');

// Always clearn up
on-exit;
    nox_delete(pRoot);
    MemNow  = nox_memUse();
    nox_Assert ( 'Mem leak' : MemNow = MemStart);
end-proc;
