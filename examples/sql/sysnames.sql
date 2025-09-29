-- Table using sysnames


create schema noxdbdemo;
set schema noxdbdemo;
create or replace table sysnames
(
  row_id_sysnames for column sysrowid bigint not null generated always as identity primary key,
  actual_job_name for column jobname  char(26)
) rcdfmt sysnamesr;

--Label

label on table sysnames is 'Table using System names';

label on column sysnames (
  row_id_sysnames is 'Id',
  actual_job_name is 'Job Name            Actual'
);

label on column sysnames(
  row_id_sysnames text is 'Id',
  actual_job_name text is 'Actual Job Name'
); 

insert into sysnames (
        actual_job_name
    )  
    values(  'ABC/QSYSWRK/123456');
 commit;

select * from noxdbdemo.sysnames;
