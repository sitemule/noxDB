# Installation with ACS

From the ACS **Run SQL script** you can simply past the following SQL code and run it.

It will create a library NOXDB and it will pull the latests build from this git repo


```sql
begin 
    declare buf blob(2G); 
    declare continue handler for sqlstate '38501' begin end;
    set buf =  systools.httpgetblob ( 
        url => 'https://github.com/sitemule/noxDB/raw/master/release/release.savf' , 
        httpheader => null
    ); 
                              
    call qsys2.ifs_write_binary(
        path_name => '/tmp/release.savf',
        line => buf ,
        overwrite => 'REPLACE'
    );    
    
    call qcmdexc ('CRTLIB noxdb');
    call qcmdexc ('CPYFRMSTMF FROMSTMF(''/tmp/release.savf'') TOMBR(''/QSYS.lib/NOXDB.lib/RELEASE.FILE'') MBROPT(*REPLACE) CVTDTA(*NONE)');
    call qcmdexc ('RSTLIB SAVLIB(NOXDB) DEV(*SAVF) SAVF(NOXDB/RELEASE)');

end; 
```