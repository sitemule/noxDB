-- drop schema noxdbdemo;
create schema noxdbdemo;
set schema noxdbdemo;

create or replace table noxdbdemo.stock (
    id int generated always as identity primary key,
    sku varchar(50) ccsid 1208,
    -- department vargraphic(50) ccsid 13488, -- Issue with UCS2??
    department vargraphic(50) ccsid 1200, -- use UTF-16
    main_category varchar(50) ccsid 1208,
    sub_category varchar(50) ccsid 1208,
    description varchar(100) ccsid 1208,
    price decimal(10 , 2)

);

create or replace table noxdbdemo.sizes  (
    id int generated always as identity primary key,
    main_category varchar(50) ccsid 1208,
    stock_level int ,
    text varchar(100) ccsid 1208,
    number float
);

create or replace table noxdbdemo.colurs (
    id int generated always as identity primary key,
    main_category varchar(50) ccsid 1208,
    colur_name varchar(100)
);


-- Load data into the stock table
truncate table noxdbdemo.stock;
insert into noxdbdemo.stock (sku, department, main_category, sub_category, description, price) values
('Cycles', 'Sports', 'Bikes', 'racing', 'Fiber 21 gears', 399.99),
('Cycles', 'Mountain', 'E-bikes', 'MTB', 'Mountain bike with 21 gears', 299.99),
('Skis', 'Sports', 'Winter Sports', 'Ski Equipment', 'Alpine skis with bindings', 499.99),
('Tennis Racket', 'Sports', 'Racquet Sports', 'Tennis Equipment', 'Professional tennis racket with strings', 89.99),
('??????','??????????', '?????????? ???????', '??????? ???????', '???? ????? ??? ????' , 266.88 );


truncate table noxdbdemo.sizes;
insert into noxdbdemo.sizes (main_category, stock_level, text, number) values
('Bikes', 1, null, 51),
('Bikes', 1, null, 55),
('Bikes', 1, null, 58),
('Bikes', 1, null, 60),
('Bikes', 2, 'S', null),
('Bikes', 2, 'L', null),
('Bikes', 2, 'XL', null),

('E-bikes', 1, null, 51),
('E-bikes', 1, null, 55),
('E-bikes', 1, null, 58),
('E-bikes', 1, null, 60),

('?????????? ???????', 2,  '5mm x 1000m' , null)
;

truncate table noxdbdemo.colurs;
insert into noxdbdemo.colurs (main_category, colur_name) values
('E-bikes', 'White'),
('E-bikes', 'Black'),
('E-bikes', 'Green'),
('E-bikes', 'Red'),
('E-bikes', 'Blue');

-- test
Select *
from noxdbdemo.stock
left join noxdbdemo.sizes  on stock.main_category = sizes.main_category
left join noxdbdemo.colurs on stock.main_category = colurs.main_category
where stock.sku = 'Cycles';

-- Greek
Select *
from noxdbdemo.stock
left join noxdbdemo.sizes  on stock.main_category = sizes.main_category
left join noxdbdemo.colurs on stock.main_category = colurs.main_category
where stock.sku = '??????';
