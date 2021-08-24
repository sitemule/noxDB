-- Table using blob

create schema noxdbdemo;
set schema noxdbdemo;

create table noxdbdemo.blobs (
  id  bigint not null generated always as identity primary key,
  myblob blob 
);

label on column noxdbdemo.blobs  (
  id is 'Id',
  myBlob  is 'Blob Data'
);

insert into noxdbdemo.blobs (myblob) 
    values (blob(x'ABCD'));


select * from noxdbdemo.blobs;

