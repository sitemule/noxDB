create or replace procedure qgpl.inc (
    inout a int
) 
begin 
    set a = a + 1;
end;
call inc (a=>123);



drop procedure qgpl.common_types;
create or replace procedure qgpl.common_types  (
    in ismallint smallint default null,
    in iinteger integer default null,
    in ibigint bigint default null,
    in idecimal decimal (30, 10) default null,
    in inumeric numeric (30, 10) default null,
    in ifloat float default null,
    in ireal real default null,
    in idouble double default null,
    in ichar char (256) default null,
    in ivarchar varchar (256) default null,
    in idate date default null,
    in itime time default null,
    in itimestamp timestamp default null, 
    out osmallint smallint,
    out ointeger integer ,
    out obigint bigint ,
    out odecimal decimal (30, 10) ,
    out onumeric numeric (30, 10) ,
    out ofloat float ,
    out oreal real ,
    out odouble double ,
    out ochar char (256) ,
    out ovarchar varchar (256) ,
    out odate date ,
    out otime time ,
    out otimestamp timestamp , 
    inout iosmallint smallint default null,
    inout iointeger integer default null,
    inout iobigint bigint default null,
    inout iodecimal decimal (30, 10) default null,
    inout ionumeric numeric (30, 10) default null,
    inout iofloat float default null,
    inout ioreal real default null,
    inout iodouble double default null,
    inout iochar char (256) default null,
    inout iovarchar varchar (256) default null,
    inout iodate date default null,
    inout iotime time default null,
    inout iotimestamp timestamp default null
)
set option output=*print, commit=*none, dbgview = *list 
begin 

    set iinteger = ismallint;
    set ibigint = ismallint;
    set idecimal  = ismallint;
    set inumeric  = ismallint;
    set ifloat = ismallint;
    set ireal = ismallint;
    set idouble = ismallint;
    set ichar = ismallint;
    set ivarchar = ismallint;
    
    if ismallint is null then
        set idate = null;
        set itime = null;
        set itimestamp = null;
    else
        set idate = now();
        set itime = now();
        set itimestamp = now();
    end if;

    set osmallint = ismallint;
    set ointeger = ismallint;
    set obigint = ismallint;
    set odecimal  = ismallint;
    set onumeric  = ismallint;
    set ofloat = ismallint;
    set oreal = ismallint;
    set odouble = ismallint;
    set ochar = ismallint;
    set ovarchar = ismallint;

    if ismallint is null then
        set odate = null;
        set otime = null;
        set otimestamp = null;
    else
        set odate = now();
        set otime = now();
        set otimestamp = now();
    end if;

    set iosmallint = ismallint;
    set iointeger = ismallint;
    set iobigint = ismallint;
    set iodecimal  = ismallint;
    set ionumeric  = ismallint;
    set iofloat = ismallint;
    set ioreal = ismallint;
    set iodouble = ismallint;
    set iochar  = ismallint;
    set iovarchar = ismallint;
    if ismallint is null then
        set iodate = null;
        set iotime = null;
        set iotimestamp = null;
    else
        set iodate = now();
        set iotime = now();
        set iotimestamp = now();
    end if;
end;
         
call  qgpl.common_types  (
    ismallint => 123,
    osmallint =>?,
    ointeger =>?,
    obigint =>?,
    odecimal  =>?,
    onumeric  =>?,
    ofloat =>?,
    oreal =>?,
    odouble =>?,
    ochar =>?,
    ovarchar =>?,
    odate =>?,
    otime =>?,
    otimestamp =>?
);

call  qgpl.common_types  (
    ismallint => null,
    osmallint =>?,
    ointeger =>?,
    obigint =>?,
    odecimal  =>?,
    onumeric  =>?,
    ofloat =>?,
    oreal =>?,
    odouble =>?,
    ochar =>?,
    ovarchar =>?,
    odate =>?,
    otime =>?,
    otimestamp =>?
);
