create schema noxdbdemo;
drop table noxdbdemo.icManufacturer;

create or replace table noxdbdemo.icManufacturer (
	manuid       char(30) primary key ,
	description  varchar(64),
	logourl      varchar(256)
)
rcdfmt manufactr  ;

label on table noxdbdemo.icManufacturer
	is 'noxDb demo: Manufacturer' ;

label on column noxdbdemo.icManufacturer (
	manuid 		is 'Manufacturer        ID' ,
	description is 'Description' ,
	logourl 	is 'Logo                url'
) ;

label on column noxdbdemo.icManufacturer(
	manuid 		 text is 'Manufacturer ID' ,
	description  text is 'Description' ,
	logourl 	 text is 'Logo url'
) ;


insert into noxdbdemo.icManufacturer (
  manuid, description, logourl
) values
  ('ACER', 'Acer', 'Images/Acer.gif'),
  ('CANON', 'Canon', 'Images/Canon.gif'),
  ('CASIO', 'Casio', 'Images/Casio.gif'),
  ('FUJIFILM', 'Fujifilm', 'Images/Fujifilm.gif'),
  ('HP', 'HP', 'Images/HP.gif'),
  ('KODAK', 'Kodak', 'Images/Kodak.gif'),
  ('KONICA', 'Konica', 'Images/Konica.gif'),
  ('NIKON', 'Nikon', 'Images/Nikon.gif'),
  ('OLYMPUS', 'Olympus', 'Images/Olympus.gif'),
  ('PANASONIC', 'Panasonic', 'Images/Panasonic.gif'),
  ('SAMSUNG', 'Samsung', 'Images/Samsung.gif'),
  ('SONY', 'Sony', 'Images/Sony.gif');
