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
select * from customer;     --kund med id 1/2/3/4 �r registrerade
select * from disscount;
select * from product_disscount;
select * from customer_favorite;    --ej klar med constraints, ska endast g� att gilla en produkt 1 g�ng samt baserat p� namn, ej storlek.



-- upddate -> set
-- insert -> values
GO
-- Visa kategori, visa endast produkter i lager, sortera genom popularitet
CREATE OR ALTER PROCEDURE view_category_in_stock_sort_by_score @category_id int
AS
BEGIN
	select product.score, category.name as category, product.name as product_name, size.name as size, product.retail_price as price, stock.quantity as quantity_in_stock from product
	inner join stock on product.id = stock.product_id
	inner join product_category on product.id = product_category.product_id
	inner join category on product_category.category_id = category.id
	inner join size on product.size_id = size.id
	where category.id = @category_id and stock.quantity >0
	order by product.score desc
END
GO
EXEC view_category_in_stock_sort_by_score @category_id = 2
GO

-- Visa produkter mot s�kterm, 
-- med val f�r tillg�nglig p� lager, samt val f�r sortering (score, price, name)
CREATE OR ALTER PROCEDURE view_product_list_by_search_term @search_term varchar(50), @in_stock bit, @sort varchar(25)
AS
BEGIN
	declare @in_stock_int int
	if @in_stock = 1 set @in_stock_int = 0
	else set @in_stock_int = -1 --f�r att denna ska funka korrekt beh�vs korrekt constraint p� stock tabellen..

	select product.score, category.name as category, product.name as product_name, 
	color.name as color, product.description, size.name as size, product.retail_price as price, 
	stock.quantity as quantity_in_stock from  product
	inner join product_category on product.id = product_category.product_id
	inner join category on product_category.category_id = category.id
	inner join color on product.color_id = color.id
	inner join size on product.size_id = size_id
	inner join stock on product.id = stock.product_id
	where (product.name like '%' + @search_term + '%'
	or product.description like concat ('%',@search_term,'%')
	or category.name like '%'+ @search_term +'%'
	or color.name like '%'+ @search_term + '%')
	and stock.quantity > @in_stock_int
	order by
		(case when @sort = 'price' then product.retail_price end)desc,
		(case when @sort = 'score' then product.score end) desc,
		(case when @sort = 'name' then product.name end) asc
END
GO
EXEC view_product_list_by_search_term @search_term = 'dress', @in_stock = 1, @sort = 'price'
GO
EXEC view_product_list_by_search_term @search_term = 'gold', @in_stock = 0, @sort = 'name'
GO




-- ADD TO CART / "L�gg till i varukorg"
CREATE OR ALTER PROCEDURE cart_add_product @customer_id int, @product_id int
AS
BEGIN
	if exists (select * from cart where cart.product_id = @product_id and cart.customer_id = @customer_id	)
	begin
		update cart
		set quantity = quantity + 1
		where cart.product_id = @product_id and cart.customer_id = @customer_id
	end
	else
	begin
		insert into cart(customer_id, product_id, quantity)
		values (@customer_id, @product_id, 1)
	end
END;

EXEC cart_add_product @customer_id = 1, @product_id = 50;  
EXEC cart_add_product @customer_id = 4, @product_id = 16;
EXEC cart_add_product @customer_id = 4, @product_id = 20;
EXEC cart_add_product @customer_id = 4, @product_id = 21;
GO





-- SHOW CART / "visa varukorg"
CREATE OR ALTER PROCEDURE view_cart @customer_id int
AS
BEGIN
	SELECT product.name as Product_name, size.name as Size, product.retail_price as Price, disscount.procent_off as Disscount, cart.quantity, cart.customer_id 
	FROM cart
	inner join product on product.id = cart.product_id
	inner join size on size.id = product.size_id
	left join product_disscount on product_disscount.product_id = product.id
	left join disscount on disscount.id = product_disscount.disscount_id
	WHERE cart.customer_id = @customer_id
	ORDER BY product.name
END;
GO
EXEC view_cart @customer_id = 1;
EXEC view_cart @customer_id = 2;
EXEC view_cart @customer_id = 3;
EXEC view_cart @customer_id = 4;
GO






-- REMOVE PRODUCT FROM CART / "Ta bort en produkt fr�n varukorgen, om 0 kvar, ta bort hela raden"
CREATE OR ALTER PROCEDURE decrease_cart_quantity @customer_id int, @product_id int
AS
BEGIN
	if exists (select * from cart where cart.product_id = @product_id and cart.customer_id = @customer_id	)
	begin
		update cart
		set quantity = quantity - 1
		where cart.product_id = @product_id and cart.customer_id = @customer_id
		delete from cart where quantity <= 0 
	end
	else
	begin
		PRINT 'product do not exist in cart'
	end
END;
GO
EXEC decrease_cart_quantity @customer_id = 3, @product_id = 26;  --FUNKA !
GO





-- FUNKAR !!
-- update sk�ter: ta bort reservation + minska lagersaldo
---f�r att UPDATE ska funka m�ste tabellen "stock" ha siffror, ej null i quantity/reserved !!
CREATE OR ALTER PROCEDURE do_stock_transaktion (@product_id int, @quantity int = null, @order_id int = null, @mark_enum varchar(15))
AS
BEGIN
	if @mark_enum = 'replenishment'
		begin
			update stock set stock.quantity = stock.quantity + @quantity WHERE stock.product_id = @product_id
			insert stock_transaktion (product_id, mark, quantity)
			values (@product_id, @mark_enum, @quantity)
		end
	else if @mark_enum = 'created'
		begin
			insert stock_transaktion (product_id, mark, order_id, quantity)
			values (@product_id, @mark_enum, @order_id, @quantity)
			update stock set stock.reserved += @quantity WHERE stock.product_id = @product_id
			--anropa en procedure som l�gger till info i tabell: order_item
		end
	else if @mark_enum = 'packed'
		begin
			update stock_transaktion set mark = @mark_enum WHERE stock_transaktion.order_id = @order_id AND stock_transaktion.product_id = @product_id
		end
	else if @mark_enum = 'shipped'
		begin
			update stock set reserved -= @quantity, quantity -= @quantity WHERE stock.product_id = @product_id
			update stock_transaktion set quantity = @quantity, mark = @mark_enum WHERE stock_transaktion.order_id = @order_id AND stock_transaktion.product_id = @product_id
		end
END

GO
-----EXEC do_stock_transaktion @product_id = 36, @quantity = 600, @mark_enum = 'replenishment'
go

-----EXEC do_stock_transaktion @product_id = 16, @quantity = 500, @mark_enum = 'shipped', @order_id = 2






-- "CHECKA UT VARUKORG"
--EMPTY CUSTOMER CART / checka ut, t�m varukorgen genom kund id **Alla voror som matchar kundens id ska bort**
CREATE OR ALTER PROCEDURE create_order_and_empty_cart @order_number varchar(10), @customer_id int 
AS
BEGIN
	--skapa order
	insert into orders(order_number, customer_id, status)
	values (@order_number, @customer_id, 'created')

	--h�mta order_id
	declare @order_id int
	select @order_id = (select id from orders
	where order_number = @order_number)

	--variabler f�r cursor
	declare
		@product_id int, 
		@quantity int,
		@product_price decimal(10,5),
		@product_disscount_procent decimal(10,5)

	--cursor
	declare cursor_customer_check_out cursor
	for select 
		product_id, 
		quantity
	from 
		cart where cart.customer_id = @customer_id

	open cursor_customer_check_out;
	
	fetch next from cursor_customer_check_out into
	@product_id, 
	@quantity

	while @@FETCH_STATUS = 0
	begin
		--s�tter �vriga v�rden som beh�vs till order_item, de baseras p� @product_id, detta g�rs f�r att arkivera aktuellt pris vid orderl�ggning
		set @product_price = (select product.retail_price
								from product
								where product.id = @product_id)
		if exists (select disscount.procent_off from disscount left join product_disscount on product_disscount.disscount_id = disscount.id)
		begin
			set @product_disscount_procent = (select disscount.procent_off from disscount left join product_disscount on product_disscount.disscount_id = disscount.id)
		end
		else
		begin
			set @product_disscount_procent = 0
		end;

		--anropa procedure "do_stock_transaktion"
		EXEC do_stock_transaktion @product_id, @quantity, @order_id, @mark_enum = 'created'

		--cursor g�r insert till order_item + anropar n�sta rad fr�n cart
		insert into order_item (order_id, product_id, product_price, product_disscount_procent, quantity)
		values(@order_id, @product_id, @product_price, @product_disscount_procent, @quantity)
		fetch next from cursor_customer_check_out into
		@product_id,
		@quantity
	end

	-- t�m cart p� produkter baserat p� @customer_id	
	DELETE FROM cart 
	WHERE cart.customer_id = @customer_id
END;

GO
--EXEC create_order_and_empty_cart
GO



---Retur av produkter, markeras p� ordern (order_item) hur mycket som har retunerats
CREATE OR ALTER PROCEDURE do_retun_of_product @order_id int, @product_id int, @quantity int 
AS
BEGIN
	if exists (select * from order_item oi where oi.order_id = @order_id and oi.product_id = @product_id and (oi.quantity-oi.quantity_returned) <=@quantity)
	begin
		update order_item
		set quantity_returned += @quantity
		where order_id = @order_id and product_id = @product_id
		--(ut�ka: uppdetera lagersaldort + g�r en stock_transaktion)
	end
	else
	begin
		print 'no matching order found'
	end
END

GO



	

---Visa produktdetaljer + lagerstatus (i lager/ej i lager)
CREATE OR ALTER PROCEDURE show_product_detail_and_stock_status @product_id int
AS
BEGIN
	declare 
		@stock_quantity_avalibul int

	select @stock_quantity_avalibul = ( select stock.quantity-stock.reserved 
	from stock 
	where stock.product_id = @product_id)
	
	select p.id, p.name product_name, size.name size, color.name color,
	case
		when @stock_quantity_avalibul > 0 then 'product in stock'
		when @stock_quantity_avalibul <= 0 then 'out of stock'
		else 'unknown'
	end stock_status, @stock_quantity_avalibul quantity_avalibul
	from product p
	inner join stock s on p.id = s.product_id
	inner join size on p.size_id = size.id
	inner join color on p.color_id = color.id
	where p.id = @product_id
END
GO
EXEC show_product_detail_and_stock_status 14
EXEC show_product_detail_and_stock_status 16  -- Ska vara 0 f�r: 1 p� lager & 1 reserverad
EXEC show_product_detail_and_stock_status 32
EXEC show_product_detail_and_stock_status 47
EXEC show_product_detail_and_stock_status 99  --produkt 99 finns ej

GO




--Testat skriva triggers, men funkar inte som �nskat

drop trigger trigger_score_check_out
drop trigger trigger_score_cart

GO

--trigger f�r att ge po�ng till produkter
create or alter trigger trigger_score_cart
on cart
after INSERT
as
BEGIN
	declare
		@product_id int,
		@score_point int = 1
		select @product_id = (select product_id from inserted)
	
	update product 
	set score += @score_point
	where product.id = @product_id
	
END
GO


--trigger f�r att ge po�ng till produkter
create or alter trigger trigger_score_check_out
on order_item
after INSERT
as
BEGIN
	declare
		@product_id int,
		@score_point int = 3
		select @product_id = (select product_id from inserted)
	
	update product 
	set score += @score_point
	where product.id = @product_id
END
GO


