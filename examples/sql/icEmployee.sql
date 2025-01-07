create schema noxdbdemo;

-- Thank you NOTHWIND for the data

drop table noxdbdemo.icEmployee;
create or replace table noxdbdemo.icEmployee (
	id int generated always as identity primary key,
	name        varchar(256) ,
    age         int ,
    income      dec(15 , 2) ,
    birthDate   date ,
    birthTime   time ,
    updated     timestamp ,
    isMale      BOOL
);
