create schema noxdbdemo;


drop table noxdbdemo.unicode;
create or replace table noxdbdemo.unicode (
	id int generated always as identity primary key,
	text_ucs2       vargraphic (60) ccsid 13488,
	text_utf8       varchar(60)     ccsid 1208,
	text_unicode    vargraphic (60) ccsid 1200
);

label on table noxdbdemo.unicode
	is 'Noxdb demo: Unicode data' ;

label on column noxdbdemo.unicode (
	id 				is 'Id',
	text_ucs2 	    is 'text ucs2' ,
	text_utf8 	    is 'text utf8' ,
	text_unicode 	is 'text unicode'
);


insert into noxdbdemo.unicode
	(text_ucs2,text_utf8,text_unicode)
values

('abcÆØÅÆØÅ','abcÆØÅÆØÅ', 'abcÆØÅÆØÅ'),
('Αθήνα','Αθήνα','Αθήνα');

select * from noxdbdemo.unicode;
