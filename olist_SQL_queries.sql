use olist_data;

#########clean data for customer table#########

SELECT * FROM olist_data.customer;

#get rid of quotation marks around customer id columns and zip code
UPDATE olist_data.customer
SET customer_id = REPLACE(customer_id, '"', '') 
WHERE customer_id LIKE '"%"';

UPDATE olist_data.customer
SET customer_unique_id = REPLACE(customer_unique_id, '"', '') 
WHERE customer_unique_id LIKE '"%"';

UPDATE olist_data.customer
SET customer_zip_code = REPLACE(customer_zip_code, '"', '') 
WHERE customer_zip_code LIKE '"%"';

#########clean data from geolocation table#########

SELECT * FROM olist_data.geolocation;

#remove quotation marks from zip code
UPDATE olist_data.geolocation
SET geolocation_zip_code_prefix = REPLACE(geolocation_zip_code_prefix, '"', '') 
WHERE geolocation_zip_code_prefix LIKE '"%"';

#########clean data from order items table#########

SELECT * FROM olist_data.order_items;

#remove quotation marks from id columns

UPDATE olist_data.order_items
SET order_id = REPLACE(order_id, '"', '') 
WHERE order_id LIKE '"%"';

UPDATE olist_data.order_items
SET product_id = REPLACE(product_id, '"', '') 
WHERE product_id LIKE '"%"';

UPDATE olist_data.order_items
SET seller_id = REPLACE(seller_id, '"', '') 
WHERE seller_id LIKE '"%"';

#########clean data from order payments table#########

SELECT * FROM olist_data.order_payments;

#remove quotation marks from id column

UPDATE olist_data.order_payments
SET order_id = REPLACE(order_id, '"', '') 
WHERE order_id LIKE '"%"';

#remove underscores from payment type
UPDATE olist_data.order_payments
SET payment_type = REPLACE(payment_type, '_', ' ') 
WHERE payment_type LIKE '%_%';

#########clean data from orders table#########

SELECT * FROM olist_data.orders;

#remove quotation marks from id columns

UPDATE olist_data.orders
SET order_id = REPLACE(order_id, '"', '') 
WHERE order_id LIKE '"%"';

UPDATE olist_data.orders
SET customer_id = REPLACE(customer_id, '"', '') 
WHERE customer_id LIKE '"%"';

#########clean data from products translation table#########

#Remove underscores from columns

UPDATE olist_data.product_translation
SET product_category_name_english = REPLACE(product_category_name_english, '_', ' ') 
WHERE product_category_name_english LIKE '%_%';

UPDATE olist_data.product_translation
SET product_category_name = REPLACE(product_category_name, '_', ' ') 
WHERE product_category_name LIKE '%_%';

#########clean data from products table#########

SELECT * FROM olist_data.products;

#remove quotation marks from id column

UPDATE olist_data.products
SET product_id = REPLACE(product_id, '"', '') 
WHERE product_id LIKE '"%"';

#remove underscores from product category column
UPDATE olist_data.products
SET product_category_name = REPLACE(product_category_name, '_', ' ') 
WHERE product_category_name LIKE '%_%';

#########clean data from sellers table#########

SELECT * FROM olist_data.sellers;

#remove quotation marks from id column and zip code

UPDATE olist_data.sellers
SET seller_id = REPLACE(seller_id, '"', '') 
WHERE seller_id LIKE '"%"';

UPDATE olist_data.sellers
SET seller_zip_code_prefix = REPLACE(seller_zip_code_prefix, '"', '') 
WHERE seller_zip_code_prefix LIKE '"%"';

#########Order_ID Duplicates#########

#multiple order_IDs were found, but did not contain duplicate information in other columns
select order_id, count(*)
from olist_data.order_items
group by order_id
having count(*) > 1;

#Confirmed that there are not duplicate order_IDs in other tables
select order_id, count(*)
from olist_data.orders
group by order_id
having count(*) > 1;

select order_id, count(*)
from olist_data.order_payments
group by order_id
having count(*) > 1;

#########join english translation to products table#########
create view product_translations as
select product_id, products.product_category_name, product_category_name_english, broad_category
from olist_data.products 
left join olist_data.product_category_name_translation
on products.product_category_name = olist_data.product_category_name_translation.product_category_name;

#########Create table with price and shipping together#########
create view complete_calculated_total_value as
SELECT order_id, order_item_id, calculated_total_value.product_id, seller_id, shipping_limit_date, price, freight_value, total_value, payment_value, broad_category, product_category_name_english, product_category_name
FROM olist_data.calculated_total_value
LEFT JOIN product_translations
ON calculated_total_value.product_id = product_translations.product_id;

#########Make sure total value and payment value match#########
select order_id, count(*), sum(total_value)*count(*), sum(payment_value)
from complete_calculated_total_value
where total_value != payment_value
group by order_id
having count(order_id) > 1;

#########Fill Blank Category Names#########
SELECT products.product_id, product_category_name, product_name_length, price, freight_value, seller_id FROM olist_data.products, order_items
where product_category_name = "";

update products
set product_category_name = "Miscellaneous"
where product_category_name = "";

#########Change Broad Category Names#########
SELECT * FROM olist_data.product_category_name_translation
where broad_category = "Miscellaneous";

alter table product_category_name_translation
RENAME COLUMN ï»¿product_category_name TO product_category_name;

update product_category_name_translation
set  broad_category = "Gifts"
where product_category_name_english = "Watches/Gifts";

update product_category_name_translation
set  broad_category = "Travel"
where product_category_name_english = "Luggage Accessories";

#########Add English Translation for Missing Categories#########
INSERT INTO product_category_name_translation (product_category_name, product_category_name_english, broad_category) 
VALUES("portateis cozinha e preparadores de alimentos", "Portable Kitchens and Food Preparers", "Home Goods");

INSERT INTO product_category_name_translation (product_category_name, product_category_name_english, broad_category) 
VALUES("moveis cozinha area de servico jantar e jardi", "Kitchen, Dining, and Garden Furniture", "Furniture");

INSERT INTO product_category_name_translation (product_category_name, product_category_name_english, broad_category) 
VALUES("pc gamer", "PC Games", "Media");

#########Change Category Names#########
update product_translations
set broad_category = "Media"
where product_category_name = "pc gamer";

update product_category_name_translation
set  broad_category = "Travel"
where product_category_name_english = "Luggage Accessories";

update complete_product_translation
set broad_category = "Books"
where product_category_name_english = "Technical Books";