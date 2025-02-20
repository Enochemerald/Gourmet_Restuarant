/* PROJECT DESCRIPTION
Mr gourmet owns a restuarant and wants to analyze the collected data to better understand customers visiting pattern,
Purchasing habits and behaviours.
Gaining insights into these aspects will help him tailor the menu to customer preferences and offer a more
personalized experience */

-- Creating database
CREATE DATABASE IF NOT EXISTS gourmet_db;
USE gourmet_db;

-- creating tables
CREATE TABLE sales (
	 customer_id VARCHAR (5),
	 order_date DATE,
	 product_id INT
);
CREATE TABLE menu(
     product_id INT,
     product_name VARCHAR (20),
     price INT
);
CREATE TABLE customers (
     customer_id VARCHAR (5),
     joining_date DATE
);

-- Inserting data into the tables
INSERT INTO sales
VALUES ('A', '2021-01-01',1),
	   ('A','2021-01-01',2),
	   ('A','2021-01-07',2),
	   ('A','2021-01-10',3),
	   ('A','2021-01-11',3),
	   ('A','2021-01-11',3),
	   ('B','2021-01-01',2),
	   ('B','2021-01-02',2),
	   ('B','2021-01-04',1),
	   ('B','2021-01-11',1),
	   ('B','2021-01-16',3),
	   ('B','2021-02-01',3),
	   ('C','2021-01-01',3),
	   ('C','2021-01-01',3),
	   ('C','2021-01-07',3);
       
INSERT INTO menu
VALUES (1,'sushi',10),
	   (2,'curry',15),
	   (3,'ramen',12);
       
INSERT INTO customers
VALUES ('A','2021-01-07'),
	   ('B','2021-01-09');
       
SELECT *
FROM sales;
SELECT *
FROM menu;
SELECT *
FROM customers;

-- Showing the total amount each customer spent at the restaurant
SELECT s.customer_id, SUM(price) AS total_amount_spent
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- Showing how many days each customer visited the restaurant
SELECT customer_id, COUNT(DISTINCT(order_date)) AS total_visits
FROM sales
GROUP BY customer_id;

-- Showing the first item from the menu purchased by each customer
WITH purchases_first AS (
							 SELECT customer_id, order_date, product_name,
							 DENSE_RANK() OVER(PARTITION BY sales.customer_id
							 ORDER BY sales.order_date) AS ranks
							 FROM sales AS sales
							 JOIN menu AS menu
							 ON sales.product_id = menu.product_id
						    )
SELECT customer_id, product_name
FROM purchases_first
WHERE ranks = 1
GROUP BY customer_id,product_name;

-- Showing the most purchased item on the menu and how many times it was purchased by all customers
 SELECT menu.product_name, COUNT(menu.product_id) AS highest_purchased
 FROM menu
 JOIN sales
 ON menu.product_id = sales.product_id
 GROUP BY menu.product_name, menu.product_id
 ORDER BY highest_purchased DESC;

-- Showing what item is the most popular for each customer
WITH most_popular_item AS (
								SELECT sales.customer_id, menu.product_name,
								COUNT(menu.product_id) AS orders_count,
								DENSE_RANK() OVER(PARTITION BY sales.customer_id
								ORDER BY COUNT(sales.customer_id)DESC) AS ranks
								FROM sales
								JOIN menu
								ON sales.product_id = menu.product_id
								GROUP BY sales.customer_id, menu.product_name
							)
SELECT customer_id, product_name, orders_count
FROM most_popular_item
WHERE ranks = 1;

-- Showing which item the customer purchased after they became a member

WITH customer_purchased AS (
								SELECT sales.customer_id,customers.joining_date,sales.order_date,sales.product_id,
								DENSE_RANK() OVER(PARTITION BY sales.customer_id
								ORDER BY sales.order_date DESC) AS ranks
								FROM sales
								JOIN customers
								ON sales.customer_id = customers.customer_id
								WHERE sales.order_date <= customers.joining_date
							)
SELECT customer_purchased.customer_id,customer_purchased. order_date, menu. product_name
FROM customer_purchased
JOIN menu
ON customer_purchased.product_id = menu.product_id
WHERE ranks = 1;

-- Showing the total items and amount spent by each member before they became a member
SELECT sales.customer_id, COUNT(DISTINCT sales.product_id) AS item_count, SUM(menu.price) AS total
FROM sales 
JOIN customers
ON sales.customer_id = customers.customer_id
JOIN menu
ON menu.product_id = sales.product_id
WHERE order_date < joining_date
GROUP BY sales.customer_id;


-- Showing how many points each customer would get if each $1 spent equates to 10 points and sushi has a 2x points multiplier
WITH spent_points_cte AS 
							(SELECT *, CASE 
											WHEN product_id = 1
											THEN price * 20
											ELSE price * 10
											END AS sushi_points
					         FROM menu)
SELECT sales.customer_id, SUM(sp.sushi_points) AS total_pointss
FROM spent_points_cte AS sp
JOIN sales
ON sp.product_id = sales.product_id
GROUP BY sales.customer_id
        