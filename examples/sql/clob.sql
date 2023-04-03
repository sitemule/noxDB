-- Table using clob

create schema noxdbdemo;
set schema noxdbdemo;

create or replace table noxdbdemo.clobs (
  id  bigint not null generated always as identity primary key,
  myclob clob (16M)
);

label on column noxdbdemo.clobs  (
  id is 'Id',
  myclob  is 'Clob Data'
);

insert into noxdbdemo.clobs (myclob)
    values ('ABC');


select * from noxdbdemo.clobs;
