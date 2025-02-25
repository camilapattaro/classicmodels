# SQL Analysis of the Classic Models Database

In this guided project, we will perform an exploratory analysis of the Classic Models relational database. The primary objective is to derive valuable insights from the company's data while showcasing analytical proficiency through SQL JOIN operations and subqueries. Additionally, we will perform a customer RFM analysis, applying SQL techniques such as temporary table, window function, and CASE statement in a practical context.
The database used is classicmodels from MySQL sample database, and it can be found [here](https://www.mysqltutorial.org/getting-started-with-mysql/mysql-sample-database/).

"The classicmodels database is a retailer of scale models of classic cars. It contains typical business data, including information about customers, products, sales orders, sales order line items, and more."

The database schema consists of the following tables:

*customers: stores customer's data.
*products: stores a list of scale model cars.
*productlines: stores a list of product lines.
*orders: stores sales orders placed by customers.
*orderdetails: stores sales order line items for every sales order.
*payments: stores payments made by customers based on their accounts.
*employees: stores employee information and the organization structure such as who reports to whom.
*offices: stores sales office data.

Following a diagram (like an ERD - Entity-Relationship Diagram) is important when working with relational databases, because it acts like a map, making it easier to navigate the database and create correct, efficient queries.

![image](https://github.com/user-attachments/assets/c0f724eb-0b71-459d-acfe-4e9f4cbc0520)


