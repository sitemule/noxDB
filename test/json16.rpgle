
**free
ctl-opt decEdit('0,') datEdit(*YMD.) main(main);
ctl-opt bndDir('NOXDB');
ctl-opt ALWNULL(*USRCTL);
//   -----------------------------------------------------------------------------
/include 'headers/JSONPARSER.rpgle'


dcl-proc main ;
    dcl-ds CashAccountMovementsParms qualified inz;
        clientAccount         char(7)  inz nullind;
        cashAccountType       char(16) inz nullind;
        cashAccountCurrency   char(3)  inz nullind;
        cashAccountMovementId char(33) inz nullind;
        numberOfResults       zoned(4) inz nullind;
        CashAccountMovementsFilters likeds(CashAccountMovementsFilterDs)  dim(8) inz(*likeds);
    end-ds;

    dcl-ds CashAccountMovementsFilterDs qualified Inz;
        name   char(35) inz nullind;
        Value  char(35) inz nullind;
    end-ds;

    dcl-s pJson pointer Inz;

    pJson = Json_ParseFile ('/prj/noxdb/testdata/nulltest.json');

    Reset CashAccountMovementsParms;

    // Get parameter(s)
    data-into CashAccountMovementsParms %data('':'allowextra=yes allowmissing=yes case=any')
                                %parser(json_DataInto(pJson));

    return;

on-exit;
    json_delete(pJson);

End-Proc;