use ElGiganto4

CREATE TABLE [product] (
  [id] int IDENTITY(1,1) PRIMARY KEY,
  [article_no] varchar(10),
  [size_id] int NOT NULL,
  [color_id] int NOT NULL,
  [name] varchar(50),
  [description] varchar(300),
  [purchase_price] int,
  [retail_price] int,
  [created_at] date DEFAULT current_timestamp,
  [score] int
  CONSTRAINT uc_product UNIQUE (article_no)
)
GO
ALTER TABLE product
ALTER COLUMN retail_price decimal (5,2);

CREATE INDEX idx_article_no
ON product (article_no)
GO

CREATE TABLE [size] (
  [id] int IDENTITY(1,1) PRIMARY KEY,
  [size_range_id] int NOT NULL,
  [name] varchar(5)
)
GO

CREATE TABLE [size_range] (
  [id] int IDENTITY(1,1) PRIMARY KEY,
  [name] varchar(50)
)
GO

CREATE TABLE [category] (
  [id] int IDENTITY(1,1) PRIMARY KEY,
  [name] varchar(50)
)
GO

CREATE TABLE [product_category] (
  [product_id] int NOT NULL,
  [category_id] int NOT NULL
)
GO

CREATE TABLE [color] (
  [id] int IDENTITY(1,1) PRIMARY KEY,
  [name] varchar(50)
)
GO

CREATE TABLE [stock] (
  [product_id] int,
  [quantity] int,
  [reserved] int
)
GO

CREATE INDEX idx_quantity
ON stock (quantity)
GO

CREATE TABLE [stock_transaktion] (
  [id] int IDENTITY(1,1) PRIMARY KEY,
  [product_id] int NOT NULL,
  [order_id] int,
  [mark] nvarchar(255) NOT NULL CHECK ([mark] IN ('created', 'pending', 'packed', 'shipped')),
  [date] date DEFAULT current_timestamp,
)
GO

CREATE INDEX idx_stock_transaktion_mark
ON stock_transaktion (mark, date)
GO

CREATE TABLE [orders] (
  [id] int IDENTITY(1,1) PRIMARY KEY,
  [order_number] varchar(10),
  [customer_id] int,
  [price_total] int,
  [disscount_total] int,
  [status] nvarchar(255) NOT NULL CHECK ([status] IN ('created', 'pending', 'shipped', 'canceled')),
  [created_at] date DEFAULT current_timestamp,
)
GO
ALTER TABLE orders
ALTER COLUMN disscount_total decimal (5,2);

CREATE INDEX idx_orders_status
ON orders (status)
GO
CREATE INDEX idx_orders_created_at
ON orders (created_at)
GO

CREATE TABLE [cart] (
  [id] int IDENTITY(1,1) PRIMARY KEY,
  [order_id] int,
  [product_id] int,
  [product_price] int,
  [product_disscount_procent] decimal,
  [quantity] int
)
GO
ALTER TABLE cart
ALTER COLUMN product_disscount_procent decimal (5,2);

CREATE TABLE [customer] (
  [id] int IDENTITY(1,1) PRIMARY KEY,
  [cart_id] int,
  [customer_favorite_id] int,
  [full_name] varchar(100),
  [email] varchar(100),
  [phone] varchar(20),
  [shipping_address] varchar(100)
)
GO

CREATE TABLE [order_history] (
  [id] int IDENTITY(1,1) PRIMARY KEY,
  [order_id] int,
  [customer_id] int
)
GO

CREATE INDEX idx_order_history_customer_id
ON order_history (customer_id)
GO

CREATE TABLE [disscount] (
  [id] int IDENTITY(1,1) PRIMARY KEY,
  [name] varchar(100),
  [code] varchar(10) NOT NULL,
  [procent_off] decimal NOT NULL,
  [start_date] date NOT NULL,
  [end_date] date NOT NULL
)
GO
ALTER TABLE disscount
ALTER COLUMN procent_off decimal (5,2);

CREATE TABLE [product_disscount] (
  [disscount_id] int,
  [product_id] int
)
GO

CREATE INDEX idx_product_disscount_product_id
ON product_disscount (product_id)
GO

CREATE TABLE [customer_favorite] (
  [customer_id] int NOT NULL,
  [product_id] int NOT NULL
)
GO

CREATE INDEX idx_customer_favorite_product_id
ON customer_favorite (product_id)
GO

ALTER TABLE [product] ADD CONSTRAINT [fk_product-size] FOREIGN KEY ([size_id]) REFERENCES [size] ([id])
GO

ALTER TABLE [size] ADD CONSTRAINT [fk_size-size_range] FOREIGN KEY ([size_range_id]) REFERENCES [size_range] ([id])
GO

ALTER TABLE [product_category] ADD CONSTRAINT [fk_product_category-product] FOREIGN KEY ([product_id]) REFERENCES [product] ([id])
GO

ALTER TABLE [product_category] ADD CONSTRAINT [fk_product_category-category] FOREIGN KEY ([category_id]) REFERENCES [category] ([id])
GO

ALTER TABLE [product] ADD CONSTRAINT [fk_product-color] FOREIGN KEY ([color_id]) REFERENCES [color] ([id])
GO

ALTER TABLE [stock] ADD CONSTRAINT [fk_stock-product] FOREIGN KEY ([product_id]) REFERENCES [product] ([id])
GO

ALTER TABLE [stock_transaktion] ADD CONSTRAINT [fk_stock_transaktion-product] FOREIGN KEY ([product_id]) REFERENCES [product] ([id])
GO

ALTER TABLE [stock_transaktion] ADD CONSTRAINT [fk_stock_transaktion-order] FOREIGN KEY ([order_id]) REFERENCES [orders] ([id])
GO

ALTER TABLE [orders] ADD CONSTRAINT [fk_order-customer] FOREIGN KEY ([customer_id]) REFERENCES [customer] ([id])
GO

ALTER TABLE [cart] ADD CONSTRAINT [fk_cart-product] FOREIGN KEY ([product_id]) REFERENCES [product] ([id])
GO

ALTER TABLE [cart] ADD CONSTRAINT [fk_cart-order] FOREIGN KEY ([order_id]) REFERENCES [orders] ([id])
GO

ALTER TABLE [customer] ADD CONSTRAINT [fk_customer-cart] FOREIGN KEY ([cart_id]) REFERENCES [cart] ([id])
GO

ALTER TABLE [order_history] ADD CONSTRAINT [fk_order_history-order] FOREIGN KEY ([order_id]) REFERENCES [orders] ([id])
GO

ALTER TABLE [order_history] ADD CONSTRAINT [fk_order_history-customer] FOREIGN KEY ([customer_id]) REFERENCES [customer] ([id])
GO

ALTER TABLE [product_disscount] ADD CONSTRAINT [fk_product_disscount-disscount] FOREIGN KEY ([disscount_id]) REFERENCES [disscount] ([id])
GO

ALTER TABLE [product_disscount] ADD CONSTRAINT [fk_product_disscount-product] FOREIGN KEY ([product_id]) REFERENCES [product] ([id])
GO

ALTER TABLE [customer_favorite] ADD CONSTRAINT [fk_customer_favorites-customer] FOREIGN KEY ([customer_id]) REFERENCES [customer] ([id])
GO

ALTER TABLE [customer_favorite] ADD CONSTRAINT [fk_customer_favorites-product] FOREIGN KEY ([product_id]) REFERENCES [product] ([id])
GO

---JUSTERINGAR

---fel fält iom att det kan vara flera
ALTER TABLE customer
DROP COLUMN customer_favorite_id;
GO

---byt plats på FK
ALTER TABLE  order_history
DROP COLUMN id;
GO
ALTER TABLE stock_transaktion
ADD quantity int;
GO
ALTER TABLE [cart] ADD CONSTRAINT [fk_cart-customer] FOREIGN KEY ([customer_id]) REFERENCES [customer] ([id])
GO
CREATE INDEX idx_cart_customer_id
ON cart (customer_id)
GO
CREATE INDEX idx_cart_order_id
ON cart (order_id)
GO

CREATE TABLE [order_item] (
  [order_id] int,
  [product_id] int,
  [product_price] decimal(10,2),
  [product_disscount_procent] decimal(10,2),
  [quantity] int,
  [quantity_returned] int
  )

GO

ALTER TABLE [order_item] ADD CONSTRAINT [fk_order_item_product] FOREIGN KEY ([product_id]) REFERENCES [product] ([id])
GO