**FREE
// Issue 129: Retrieving non existent attribute, causes NULL pointer error
ctl-opt main( main )
             option(*srcstmt : *nodebugio: *showcpy : *expdds: *nounref)
             extbinint(*yes)
             decedit(',')
             bnddir( 'NOXDBUTF8/NOXDBUTF8' )
             ccsid(*char:*jobrun);

/include noxdbutf8/qrpgleref,noxdbutf8


dcl-proc main;

    dcl-s MemStart int(20);
    dcl-s MemNow   int(20);
    dcl-s input_ebcdic    varchar( 500 );
    dcl-s value           varchar( 500 );
    dcl-s pRoot           pointer;

    nox_Assert ('Start issue0129') ;
    MemStart = nox_memUse();

    input_ebcdic = '<a b=""/>';

    pRoot = nox_ParseString( input_ebcdic);

    If nox_Error( pRoot ) ;
        nox_Assert ( nox_Message( pRoot )  );
        return;
    endif;


    // Retrieving non existent attribute, causes NULL pointer error
    value = nox_GetNodeAttrValue( pRoot : 'c' : 'default' );

    nox_Assert ('c = default' : value = 'default' );

    return;

on-exit;

    nox_delete( pRoot );
    MemNow  = nox_memUse();
    nox_Assert ( 'Mem leak' : MemNow = MemStart);

    nox_Assert ('End issue0129') ;


end-proc;