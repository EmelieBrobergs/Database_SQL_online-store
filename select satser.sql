use ElGiganto4

select * from product;
select * from size;
select * from size_range;
select * from category;
select * from product_category;
select * from color;
select * from stock;
select * from stock_transaktion;
select * from orders;
select * from order_item;
select * from cart;
select * from customer;
--select * from order_history;  -- rederad, skapar som en vy ist
select * from disscount;
select * from product_disscount;
select * from customer_favorite;

-- insert into disscount(name, code, procent_off, [start_date], end_date)
-- values ('40% on Jackets', '40JACKET', 0.4, '2020-12-17', '2021-01-27');

--insert into product(article_no, size_id, color_id, name, description, purchase_price, retail_price)
--values ('703879-019', 9, 5,'Charlotte Sequin Gown Gold', 'Magical sequin dress from MOMENTS NEW YORK.', 280.50, 1199.00);
GO
--insert into orders (order_number, customer_id, status)
--values (1234567890, 1, 'created')

--delete from stock_transaktion where order_id = 2
--delete from orders where id = 5

update product set score = 0 

--alter table orders
--drop column status

GO

delete from customer_favorite;
--Kundernas favoriter (ska inte gå att lägga in dubletter.. eller via storlek, utan via produkt typ)
insert into customer_favorite(product_id, customer_id)
values (16, 1), (17, 1), (23, 1), (28, 1), (28, 1), (37, 1), 
(18, 2), (18, 2), (47, 2), (48, 2),
(34, 3), (32, 3), (32, 3),
(24, 4), (29, 4)
GO

