/*
 * Your CSV file has been imported into orders table.
 * You can run this SQL query to make all CSV records available for charting.
 */

SELECT "Order Date" FROM orders LIMIT 5;
-- 1. Sales & Profit by Region
SELECT Region, ROUND(SUM(Sales),2) AS total_sales, ROUND(SUM(Profit),2) AS total_profit,
       ROUND(SUM(Profit)*100.0/SUM(Sales),2) AS profit_margin_pct
FROM orders GROUP BY Region ORDER BY total_sales DESC;
-- 2. Top 5 Sub-Categories by Revenue
SELECT "Sub-Category", ROUND(SUM(Sales),2) AS revenue
FROM orders GROUP BY "Sub-Category" ORDER BY revenue DESC LIMIT 5;
-- 3. Monthly Sales Trend 
SELECT substr("Order Date", 1, 7) AS month, ROUND(SUM(Sales),2) AS monthly_sales
FROM orders GROUP BY month ORDER BY month;
-- 4. Profit Margin by Category
SELECT Category, ROUND(SUM(Profit)*100.0/SUM(Sales),2) AS profit_margin_pct
FROM orders GROUP BY Category ORDER BY profit_margin_pct DESC;
-- 5. Top 10 Customers by Lifetime Spend
SELECT "Customer Name", ROUND(SUM(Sales),2) AS lifetime_spend
FROM orders GROUP BY "Customer Name" ORDER BY lifetime_spend DESC LIMIT 10;
-- 6. Sub-Categories Losing Money
SELECT "Sub-Category", ROUND(SUM(Sales),2) AS revenue, ROUND(SUM(Profit),2) AS total_profit
FROM orders GROUP BY "Sub-Category" HAVING total_profit < 0 ORDER BY total_profit ASC;
