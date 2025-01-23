/*SELECT & FROM¶
SELECT and FROM are the 2 minimum components
we need to build a query in SQL. SELECT defines what columns we would like, and FROM 
defines the table we would like to pull data from.*/

select category_name from categories;
select * from categories;

/*ORDER BY, DISTINCT, LIMIT¶
ORDER BY allows us to order the output of the query by 1 or more columns.*/

select first_name,last_name from customers
order by last_name;

select first_name,last_name from customers
order by last_name, first_name;

/*Return only the unique values in a column. 
last_name to get unique last names.*/

select distinct last_name from customers
order by last_name desc;

/*LIMIT allows us to limit the number of output rows. 
This is useful when dealing with large tables where we only need to see the columns.*/ 

select distinct last_name from customers
order by last_name asc
limit 10;

select first_name, last_name from customers
where last_name= 'Acevedo'
order by first_name;

select first_name, last_name from customers
where last_name= 'Acevedo'
and first_name='Ester';

select first_name, last_name from customers
where last_name = 'Acevedo'
and first_name ='Ester'
or first_name = 'Jamika';

select first_name, last_name from customers
where last_name = 'Acevedo'
and ((first_name ='Ester')
or (first_name = 'Jamika'));

/*select all customers from New York and California only.*/

select * from customers
where state IN ('NY', 'CA') 
limit 5;

--add this to the previous query to filter down to users with no phone number on file.--

select * from customers
where state IN ('NY', 'CA') 
and phone is null
limit 5;

--To get customers who are not in Texas or New York, and who do have a phone number.--

select * from customers 
where state NOt IN ('CA', 'NY')
and phone IS NOT NULL
limit 5;

select * from products
where product_name LIKE 'T%'
limit 5;

--find the most expensive item purchased and the total items ordered using these.--
select max(list_price) from order_items;

--rename the column for our total order count query.--

select sum(quantity) as total_order_count
from order_items;

-- take the average of the list price multiplied by the discount in the order_items table to see the average discount in dollars.--

select avg(list_price * discount) as avg_discount from order_items;

--find the average final sale price for items priced at least at $1,000.--

select round(avg(list_price * (1-discount)),2) as avg_sale_price from order_items
where list_price >= 1000;

--GROUP BY & HAVING¶

select order_id,round(sum(quantity*list_price * (1-discount)),2) as avg_sale_price from order_items
group by order_id;

select order_id,round(sum(quantity * list_price * (1-discount)),2) as avg_sale_price 
from order_items
group by order_id
having avg_sale_price > 20000
order by 2 desc;

select 
case when shipped_date > required_date then 1 else 0
end as 'late_shipping' from orders
limit 5;

select order_id,cast(order_id as float) as order_id_float from orders
limit 5;

-- join the orders table with the customers table--

select * from orders join
customers on orders.customer_id = customers.customer_id
limit 5;

--LEFT JOIN--

select * from orders left join
customers on orders.customer_id = customers.customer_id
limit 5;

--FULL OUTER JOIN--

select * from orders full join
customers on orders.customer_id = customers.customer_id
limit 5;

--SELF JOIN--

select t1.customer_id,
max(t1.order_date) as most_recent_order,
max(t2.order_date) as second_recent_order
from orders t1
inner join orders t2
on t1.customer_id = t2.customer_id
and t1.order_date > t2.order_date
group by t1.customer_id;

--UNION¶
--We want to get the products for 2016 and 2019, so we can use UNION to combine the results.--

select product_id, product_name, model_year, list_price from products
where model_year = 2016
UNION
select product_id, product_name, model_year, list_price from products
where model_year = 2019;

--if we want to see 2019 products with an above average price.--

select * from products where model_year = 2019 
and list_price > (select avg(list_price) from products where model_year =2019);


--IN--
-- subquery that returns order ids for the Trek brand that were discounted
--at least 20%, and use that to filter orders and return the unique order_id 
--and customer_id for orders with those conditions.

select distinct order_id, customer_id from orders
where order_id in (
  select distinct order_id from order_items inner join products 
  on orders_items.product_id = products.product_id
  where  brand_id = 9 and discount >= 0.2
  );

--EXISTS¶--

select distinct orders.order_id, customer_id from orders
where EXISTS ( select orders.order_id from order_items 
inner join orders on order_items.order_id = orders.order_id
where discount >= 0.20 );

--CTE--

with category_sales as 
( select distinct order_id,order_items.product_id,quantity,
 order_items.list_price, quantity*order_items.list_price as sub_total,category_id
  from order_items inner join products on order_items.product_id = products.product.id
 )
 
 select category_id, sum(sub_total) as revenue, sum(quantity) as units_sold,
 count(distinct order_id) as total_orders from category_sales
 group by category_id 
 order by revenue desc;

--Recursive CTE--
With RECURSIVE employee_hierarchy as (
  select staff_id, manager_id,
  first_name || ' ' || last_name as full_name 
  from staffs t1
  where manager_id is null 
  union ALL
  select t2.staff_id,
  t2.manager_id, t2.first_name || ' ' || t2.last_name as full_name 
  from staffs t2
  inner join 
  employee_hierarchy eh on t2.manager_id = eh.staff_id 
  )
  select * from employee_hierarchy;
  

--window function to calculate the 30-day moving average of orders.--

with daily_orders as (
select order_date, store_id, count(*) from orders group by 1 ,2
  )
  
  select order_date, store_id, avg(orders) over (partition by store_id order by order_date asc
  rows between 14 preceding and 15 following) as moving_avg_30 from daily_orders;

--Practical Examples¶
--Customer Segmentation
--Query to segment customers based on order count, total spent, and recency:

with customer_stats as (
  select customer_id, sum(quantity * list_price * (1-discount)) as total_spent,
  count(distinct orders.order_id)as total_orders,
  julianday('2018-12-29') - julianday(max(order_date)) as days_since_last_purchase 
  from orders inner join order_items ON
  orders.order_id = order_items.order_id group by 1
  )
  select customer_id,
  case when total_orders > 1 then 'repeat_buyer'
  else 'one-time-buyer'
  end as purchase_frequency,
  case when days_since_last_purchase < 90 then 'recent buyer'
  else 'not recent buyer'
  end as purchase_recency,
  case when total_spent/(select max(total_spent) from customer_stats) >= 0.65 then 'big spender'
  when total_spent/(Select max(total_spent) from customer_stats) <= 0.30 then 'low spender'
  else 'average spender' end as buying_power from customer_stats

--Seasonality Analysis
--Query to find the average units sold for each month of the year, for each product category:

with product_categories as (
select product_id, category_name from products inner JOIN categories 
on products.category_id = categories.category_id ),
product_sales_ym as (
  select strftime('%Y', order_date) as year,
  strftime('%M' order_date) as month, product_id,
  sum(quantity) as units_sold from orders inner join order_items 
  on orders.order_id = order_items.order_id group by 1,2,3)
  select month, category_name,avg(units_sold) as avg_units_sold
  from product_sales_ym inner join product_categories ON
  product_sales_ym.product_id = product_categories.product_id 
  group by 1,2;
  
--Ranking and Ordering Analysis
--Query to get the top 10 customers based on total purchase amount:


select c.first_name || ' ' || c.last_name as customer_name,
count(o.order_id) as total_transactions,
Rank() over (order by count(o.order_id) desc) as rank from customers c 
inner join orders o on c.customer_id = o.customer_id group by 1
order by 2 desc;

--Market Basket Analysis
--Query to find frequently co-purchased products with a specific product:

SELECT
    product_a,
    product_b,
    co_purchase_count
FROM 
 (
     SELECT
         p1.product_name AS product_a,
         p2.product_name AS product_b,
         COUNT(*) AS co_purchase_count
     FROM
         order_items s1
   INNER JOIN
         order_items s2 ON s1.order_id = s2.order_id AND s1.product_id <> s2.product_id
     INNER JOIN
         products p1 ON s1.product_id = p1.product_id
     INNER JOIN
         products p2 ON s2.product_id = p2.product_id
     GROUP BY
         p1.product_id, p2.product_id
    ) subquery
ORDER BY
    co_purchase_count DESC;


--Time Intervals between Engagements
--Query to calculate average time between consecutive purchases for customers:

select customer_id, avg(julianday(order_date) - julianday(prev_order_date))
as avg_days_between_purchases from (
  select c.customer_id, order_date,lag(order_date) over
  (partition by c.customer_id order by order_date) as prev_order_date
  from orders o inner join customers c on o.customer_id = c.customer_id)
  subquery
  where prev_order_date is not null
  group by 1;
  










