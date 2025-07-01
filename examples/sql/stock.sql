create or replace table noxdb.stock (
    id int generated always as identity primary key,
    sku varchar(50),
    department varchar(50),
    main_category varchar(50),
    sub_category varchar(50),
    description varchar(100),
    price decimal(10,2)

);

create or replace table noxdb.sizes  (
    id int generated always as identity primary key,
    main_category varchar(50),
    stock_level int ,
    text varchar(100),
    number float
);

create or replace table noxdb.colurs (
    id int generated always as identity primary key,
    main_category varchar(50),
    colur_name varchar(100)
);


-- Load data into the stock table
truncate table noxdb.stock;
insert into noxdb.stock (sku, department, main_category, sub_category, description, price) values
('Cycles', 'Sports', 'Bikes', 'racing', 'Fiber 21 gears', 399.99),
('Cycles', 'Mountain', 'E-bikes', 'MTB', 'Mountain bike with 21 gears', 299.99),
('Skis', 'Sports', 'Winter Sports', 'Ski Equipment', 'Alpine skis with bindings', 499.99),
('Tennis Racket', 'Sports', 'Racquet Sports', 'Tennis Equipment', 'Professional tennis racket with strings', 89.99);

truncate table noxdb.sizes;
insert into noxdb.sizes (main_category, stock_level, text, number) values
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
('E-bikes', 1, null, 60);

truncate table noxdb.colurs;
insert into noxdb.colurs (main_category, colur_name) values
('E-bikes', 'White'),
('E-bikes', 'Black'),
('E-bikes', 'Green'),
('E-bikes', 'Red'),
('E-bikes', 'Blue');

-- test
Select * from noxdb.stock left join noxdb.sizes on noxdb.stock.main_category = noxdb.sizes.main_category
left join noxdb.colurs on noxdb.stock.main_category = noxdb.colurs.main_category
where noxdb.stock.sku = 'Cycles';
