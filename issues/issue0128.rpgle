**FREE
// XML serializer fails for blank attributes - UTF-8 version
ctl-opt main( main )
             option(*srcstmt : *nodebugio: *showcpy : *expdds: *nounref)
             EXTBININT(*YES)
             DECEDIT(',')
             bnddir( 'NOXDBUTF8/NOXDBUTF8' )
             CCSID(*CHAR:*JOBRUN);

/copy noxdbutf8/qrpgleref,noxdbutf8


dcl-proc main;


  dcl-s msg             varchar( 52 );
  dcl-s input_ebcdic    varchar( 500 );
  dcl-s pRoot           pointer;


  // blanks values in attribute - casuses NULL pointer exeption
  input_ebcdic = '<a b=""/>';

  pRoot = nox_ParseString( input_ebcdic);
  If nox_Error( pRoot ) ;
      msg = nox_Message( pRoot );
      dsply msg;
      return;
  endif;

  nox_WriteXmlStmf( pRoot: '/tmp/PP' + '.xml': 1252: *OFF);
  nox_WriteJsonStmf( pRoot: '/tmp/PPP' + '.json' );


  return;

  on-exit;

    if pRoot <> *null;
        nox_delete( pRoot );
    endif;

end-proc;