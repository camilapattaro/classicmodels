/* Inspecting the Data
I uploaded the database into MySQL Workbench and thoroughly inspected all the tables to familiarize myself with the columns.
After that, I checked for inconsistent data types, duplicates, and missing values that could affect my analysis. 
NULL values were found in fields such as addressLine, city, state, and postalCode, but not in the country field. 
Therefore, I will focus on using the country data for my territorial analysis.
Next, I examined some unique values:
*/

--Each query was executed individually
SELECT DISTINCT YEAR(paymentdate) AS year FROM payments;
SELECT DISTINCT country FROM customers;
SELECT COUNT(DISTINCT customernumber) FROM customers;
SELECT COUNT(DISTINCT productcode) FROM products;
SELECT COUNT(DISTINCT productline) FROM productlines;
SELECT COUNT(DISTINCT productscale) FROM products;

/* 
We have data for the years 2003, 2004 and 2005;
customers from 28 countries;
122 customers,
110 distinct products; 
7 different categories;
7 different product scale.
*/

-- 1. What are the total sales (revenue) per year?

SELECT DISTINCT 
    YEAR(paymentdate) AS year, 
    SUM(amount) AS total_sales
FROM payments
GROUP BY year
ORDER BY total_sales DESC;

-- The highest sales were recorded in 2004, followed by 2003, while 2005 had significantly lower revenue.

SELECT 
 YEAR(paymentdate) AS year,
 COUNT(DISTINCT MONTH(paymentdate)) AS month
FROM payments
GROUP BY year

-- Here, we can see that data is available only for six months in 2005, which explains the lower revenue for that year. 
-- This is important to note when comparing performance across years since 2005's data is incomplete.

-- 2. Which customers have spent the most money?

SELECT 
    c.customername,
    SUM(p.amount) AS total_spent,
    c.country
FROM customers c JOIN payments p
ON c.customernumber = p.customernumber
GROUP BY 
 c.customername,
    c.country
ORDER BY total_spent DESC
LIMIT 5;

-- Euro + Shopping Channel (Spain) and Mini Gifts Distributors (USA) have the highest spending customers. 
--This suggests that both countries are key markets for the business.

-- 3. Which countries have the top 3 highest number of customers, and what is their average spending?

SELECT 
    c.country,
    COUNT(c.customernumber) AS customers_count,
    ROUND(AVG(p.amount), 2) AS avg_spent
FROM customers c JOIN payments p
ON c.customernumber = p.customernumber
GROUP BY c.country 
ORDER BY customers_count DESC
LIMIT 3;

-- USA, France, and Spain have the highest number of customers, which could imply that the company should focus marketing and product efforts in these countries, especially USA.

--4. Who are the top 5 sales representatives based on revenue generated?

SELECT 
 e.lastname,
 e.firstname,
    SUM(p.amount) AS total_sold,
    o.country
FROM customers c JOIN payments p JOIN employees e JOIN offices o
ON c.customernumber = p.customernumber 
AND e.employeenumber = c.salesRepEmployeeNumber
AND o.officecode = e.officecode
GROUP BY salesRepEmployeeNumber
ORDER BY total_sold DESC
LIMIT 5;

-- The Top 5 sellers are primarily in France, USA, and UK, suggesting these countries are driving the sales volume for the company. 
--Focusing efforts on these regions might further boost sales.

--5. Which office location has the TOP 5 highest total sales?

SELECT 
    o.city,
    o.country,
    SUM(p.amount) AS total_sold
FROM payments p
JOIN customers c ON p.customernumber = c.customernumber
JOIN employees e ON c.salesRepEmployeeNumber = e.employeenumber
JOIN offices o ON e.officecode = o.officecode
GROUP BY o.officecode, o.city, o.country
ORDER BY total_sold DESC
LIMIT 5;

-- Once again, we see the France, USA and UK in strong positions.

-- 6. Which product line generates the most revenue?
SELECT 
    p.productline, 
    SUM(od.quantityordered * od.priceeach) AS total_revenue,
    ROUND((SUM(od.quantityordered * od.priceeach) / 
           (SELECT SUM(od2.quantityordered * od2.priceeach) 
            FROM orderdetails od2)) * 100, 2) AS percentage_of_total_revenue
FROM orderdetails od
JOIN products p ON od.productcode = p.productcode
GROUP BY p.productline
ORDER BY total_revenue DESC;

-- Classic Cars clearly dominate sales, contributing more than double the sales of Vintage Cars, showing strong consumer interest in that category. 
-- This could indicate a need to focus more on classic cars in future marketing campaigns.
-- Train products represent less than 2% of total revenue, indicating that this category is underperforming. 
-- The company might consider focusing less on this category or finding ways to revitalize interest in it.

-- 7. What are the TOP 3 most profitable products?

SELECT 
 productname,
    productline,
    (msrp - buyprice) AS profit
FROM products
ORDER BY profit DESC
LIMIT 3;

-- The Top 2 most profitable products are Classic Cars, indicating that products in this category are not only popular but also generate a higher profit margin.

-- 8. Are there products that have never been sold?

SELECT
    p.productname,
    p.productline,
    COALESCE(SUM(od.quantityordered), 0) AS total_quantity_sold
FROM products p LEFT JOIN orderdetails od
ON p.productcode = od.productcode
GROUP BY 
 p.productname,
    p.productline
HAVING total_quantity_sold = 0;

-- 1985 Toyota Supra is a classic car and have never been sold.

-- 9. How many orders were placed per month in the last year?

SELECT 
    YEAR(orderdate) AS year,  
    MONTH(orderdate) AS month,
    COUNT(ordernumber) AS orders_count
FROM orders
GROUP BY year, month
ORDER BY year DESC, month DESC
LIMIT 12;

-- The numbers were consistent between 11 and 15 throughout the last year, with one exception in November 2004, where, for some reason, the orders were more than double.
--We can verify if the sales in November 2003 were also higher.

SELECT 
    YEAR(orderdate) AS year,  
    MONTH(orderdate) AS month,
    COUNT(ordernumber) AS orders_count
FROM orders
GROUP BY year, month
HAVING month = 11

-- The sales in November 2003 were also high. Since November is the month of Black Friday, this could possibly explain the increase in sales, 
-- which suggests that promotional activities, such as discounts, can have a big impact on sales. 
-- Planning for such events in future years could boost revenue during those periods.

  
-- 10. What are the most frequently ordered products?

SELECT
    p.productname,
    SUM(od.quantityordered) AS total_quantity_ordered,
    p.productline
FROM products p
JOIN orderdetails od
ON p.productcode = od.productcode
GROUP BY 
 p.productname,
    p.productline
ORDER BY total_quantity_ordered DESC
LIMIT 10;

-- Ferrari 360 Spider red, a Classic Car, is the most ordered product , which shows a strong demand for high-end luxury cars. 
-- This product could be further emphasized in marketing campaigns to continue capitalizing on its popularity and profitability.

-- 11. Who are the best customers? (RFM Analysis)

-- Findinf Recency:

SELECT 
 c.customername,
    c.customernumber,
    SUM(p.amount) AS monetary,
    AVG(p.amount) AS avg_monetary,
    COUNT(p.checknumber) AS frequency,
    MAX(p.paymentdate) AS last_payment_date,
    (SELECT MAX(paymentdate) FROM payments) AS max_last_order,
    DATEDIFF((SELECT MAX(paymentdate) FROM payments), MAX(p.paymentdate)) AS recency
FROM customers c JOIN payments p
ON c.customernumber = p.customernumber 
GROUP BY c.customername, c.customernumber;

-- The most recent order in the dataset occurred on 09/06/2005, and the recency was calculated relative to this date.

-- Using NTILE window function to allow for the categorization of customers into equal groups (quartiles in this case) based on their RFM scores.

WITH rfm AS
(    
    SELECT 
  c.customername,
  c.customernumber,
  SUM(p.amount) AS monetary,
  AVG(p.amount) AS avg_monetary,
  COUNT(p.checknumber) AS frequency,
  MAX(p.paymentdate) AS last_payment_date,
  (SELECT MAX(paymentdate) FROM payments) AS max_last_order,
  DATEDIFF((SELECT MAX(paymentdate) FROM payments), MAX(p.paymentdate)) AS recency
 FROM customers c JOIN payments p
 ON c.customernumber = p.customernumber 
 GROUP BY c.customername, c.customernumber
)
SELECT * ,
   NTILE(4) OVER (ORDER BY recency) AS rfm_recency,
   NTILE(4) OVER (ORDER BY frequency) AS rfm_frequency,
   NTILE(4) OVER (ORDER BY avg_monetary) AS rfm_monetary
  FROM rfm
  ORDER BY frequency DESC

-- After calculating the RFM quartiles, the CASE function was used to assign customer four segments.
-- Additionally, a temporary table was created to streamline the execution of the subsequent query.

CREATE TEMPORARY TABLE temp_rfm AS 
(
SELECT 
 customername,
    rfm_string,
 rfm_recency,
 rfm_frequency,
 rfm_monetary,
 CASE 
  WHEN rfm_string IN ('444', '443', '434', '433', '424', '423', '414', '413', '344', '343', '334'
) THEN 'Top 25% (Best customers)'
  WHEN rfm_string IN ('333', '324', '323', '314', '313', '342', '341', '332', '331', '322', '321', '312', '311', '242', '241', '232', '231' 
) THEN 'Upper-Mid 25% (Good customers)'
  WHEN rfm_string IN ('222', '221', '212', '211', '144', '134', '124', '142', '141', '143', '132', '131', '122', '121', '112', '242', '241', '232', '231', '222', '221', '212', '211', '414', '413', '412', '411'
) THEN 'Lower-Mid 25% (At-risk customers)'
  ELSE 'Bottom 25% (Lost customers)'
 END AS rfm_segment
FROM 
(
 WITH rfm AS
 ( 
  SELECT 
   c.customername,
   c.customernumber,
   SUM(p.amount) AS monetary,
   AVG(p.amount) AS avg_monetary,
   COUNT(p.checknumber) AS frequency,
   MAX(p.paymentdate) AS last_payment_date,
   (SELECT MAX(paymentdate) FROM payments) AS max_last_order,
   DATEDIFF((SELECT MAX(paymentdate) FROM payments), MAX(p.paymentdate)) AS recency
  FROM customers c JOIN payments p
  ON c.customernumber = p.customernumber 
  GROUP BY c.customername, c.customernumber
 ),
 rfm_calc AS
 (
  SELECT * ,
   NTILE(4) OVER (ORDER BY recency) AS rfm_recency,
   NTILE(4) OVER (ORDER BY frequency) AS rfm_frequency,
   NTILE(4) OVER (ORDER BY avg_monetary) AS rfm_monetary
  FROM rfm
  ORDER BY frequency DESC
 )
 SELECT 
  *, 
  rfm_recency + rfm_frequency + rfm_monetary AS rfm_total,
  CONCAT(CAST(rfm_recency AS CHAR), CAST(rfm_frequency AS CHAR), CAST(rfm_monetary AS CHAR)) AS rfm_string
 FROM rfm_calc    
) AS rfm_final);

-- Finally, I would like to compare the RFM segment of each customer with their respective revenue.

SELECT 
 c.customername,
 SUM(p.amount) AS revenue,
    t.rfm_string,
    t.rfm_segment
FROM customers c JOIN payments p JOIN temp_rfm t
ON c.customernumber = p.customernumber 
AND c.customername = t.customername
 GROUP BY 
 c.customername,
    t.rfm_segment,
    t.rfm_string
ORDER BY revenue DESC;

-- According to the segmentation categories chosen for this project, we can observe that the Top 2 customers who spent the most money are actually categorized as Lost Customers.
-- Upon analyzing their RFM, we can see that Euro + Shopping Channel and Mini Gifts Distributors have high frequency and high spending, but low recency. 
-- This could indicate that these customers were valuable in the past but have not made a purchase recently.
-- On the other hand, Handji Gifts & Co (21st on the list) is likely one of the Good Customers, with moderate recency, frequency, and monetary values. 
-- This suggests that the customer is fairly engaged and spends a reasonable amount, but not at the highest level.

-- To conclude the analysis, the Top 5 customers are:

SELECT * FROM temp_rfm6

SELECT 
 c.customername,
    SUM(p.amount) AS revenue,
    t.rfm_segment,
    c.country
FROM customers c JOIN payments p JOIN temp_rfm6 t
ON c.customernumber = p.customernumber
AND c.customername = t.customername
WHERE rfm_segment =  'Top 25% (Best customers)'
GROUP BY 
 c.customername,
    c.country
ORDER BY revenue DESC
LIMIT 5;

-- Top 1 customer is in France, followed by USA in second place and Italy. 
-- This suggests that France and USA are not only the largest markets in terms of customer numbers and spending, but they also have some of the most valuable customers in terms of loyalty and purchase behavior.
-- Italy's appearance in the Top 3 could indicate an opportunity for the company to explore the Italian market further, potentially uncovering untapped potential.
