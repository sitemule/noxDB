**free
// -------------------------------------------------------------
// issue:
// nested reslutset does not have right ccsid for SQL statement
// -------------------------------------------------------------
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') main(main);
/include qrpgleRef,noxdb

dcl-proc main;

    // Here i force the CCSID of constants to be 500
    // causing the error:
    json_setDelimitersByCcsid(500);

    issue92();
    issue92_workaround ();

end-proc;
// -------------------------------------------------------------
dcl-proc issue92;

    Dcl-S  pManufacturer      Pointer;
    Dcl-S  pProducts          Pointer;
    Dcl-DS manufacturereList  likeds(json_iterator);

    // return an simple array with rows
    pManufacturer = json_sqlResultSet(
        'Select * from noxdbdemo.icManufacturer'
    );
    manufacturereList = json_setIterator(pManufacturer);
    DoW json_ForEach(manufacturereList  );

        // This fails if the ccsid of job is not 500 because the $
        pProducts = json_sqlResultSet(
            'Select * from noxdbdemo.icProduct where manuid = $manuid':
            1:  // first row
            -1: // all rows
            0:  // simple array
            manufacturereList.this  // from where to pick the key
        );
        json_MoveObjectInto (manufacturereList.this   : 'products' : pProducts );
    EndDo;

    json_WriteJsonStmf(pManufacturer:'/prj/noxdb/testout/issue92.json':1208:*OFF);


on-exit;
    // Cleanup: dispose the rows in the array
    json_delete(pManufacturer);

end-proc;

// -------------------------------------------------------------
dcl-proc issue92_workaround;

    Dcl-S  pManufacturer      Pointer;
    Dcl-S  pProducts          Pointer;
    Dcl-s  dollar             char(1) inz(x'67');
    Dcl-DS manufacturereList  likeds(json_iterator);

    // return an simple array with rows
    pManufacturer = json_sqlResultSet(
        'Select * from noxdbdemo.icManufacturer'
    );

    manufacturereList = json_setIterator(pManufacturer);
    DoW json_ForEach(manufacturereList  );

        // This works, since the $ is replace by the hex value in ccsid 500
        pProducts = json_sqlResultSet(
            'Select * from noxdbdemo.icProduct where manuid = ' + dollar + 'manuid':
            1:  // first row
            -1: // all rows
            0:  // simple array
            manufacturereList.this  // from where to pick the key
        );
        json_MoveObjectInto (manufacturereList.this   : 'products' : pProducts );
    EndDo;

    json_WriteJsonStmf(pManufacturer:'/prj/noxdb/testout/nested.json':1208:*OFF);


on-exit;
    // Cleanup: dispose the rows in the array
    json_delete(pManufacturer);

end-proc;
