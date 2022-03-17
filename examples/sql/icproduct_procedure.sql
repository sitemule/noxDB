create or replace procedure noxdbdemo.icproduct (
    in manufaturer varchar(32) default null
) 
language sql
dynamic result sets 1
set option dbgview = *source , output=*print , commit=*none, datfmt=*eur
begin

    declare c1 cursor with return for
        select *
        from noxdbdemo.icproduct
        where manuid like  rtrim(manufaturer) concat '%' or manufaturer is null ;
    open c1 ;

end;

-- Test cases:
call  noxdbdemo.icproduct ( manufaturer => 'OLYMPUS');
call  noxdbdemo.icproduct ( );
