/* ============================================================================
 * Superstore Sales Performance — analysis queries
 *
 * Source table : orders  (loaded from Superstore_Cleaned.xlsx, 9,994 order lines)
 * Coverage     : 2014-2017, United States
 * Dialect      : SQLite. Order Date is stored as TEXT (YYYY-MM-DD), which is why
 *                Q3 slices the month with substr() rather than a date function.
 *
 * Each query answers one business question. The findings they produce are
 * discussed in README.md.
 * ==========================================================================*/


-- 1. Which regions drive the most sales and profit?
SELECT Region, ROUND(SUM(Sales),2) AS total_sales, ROUND(SUM(Profit),2) AS total_profit,
       ROUND(SUM(Profit)*100.0/SUM(Sales),2) AS profit_margin_pct
FROM orders GROUP BY Region ORDER BY total_sales DESC;

-- 2. What are the top 5 revenue-generating sub-categories?
SELECT "Sub-Category", ROUND(SUM(Sales),2) AS revenue
FROM orders GROUP BY "Sub-Category" ORDER BY revenue DESC LIMIT 5;

-- 3. How does revenue trend month over month?
SELECT substr("Order Date", 1, 7) AS month, ROUND(SUM(Sales),2) AS monthly_sales
FROM orders GROUP BY month ORDER BY month;

-- 4. Which product category is most profitable relative to sales?
SELECT Category, ROUND(SUM(Profit)*100.0/SUM(Sales),2) AS profit_margin_pct
FROM orders GROUP BY Category ORDER BY profit_margin_pct DESC;

-- 5. Who are the highest lifetime-value customers?
SELECT "Customer Name", ROUND(SUM(Sales),2) AS lifetime_spend
FROM orders GROUP BY "Customer Name" ORDER BY lifetime_spend DESC LIMIT 10;

-- 6. Which sub-categories are losing money?
SELECT "Sub-Category", ROUND(SUM(Sales),2) AS revenue, ROUND(SUM(Profit),2) AS total_profit
FROM orders GROUP BY "Sub-Category" HAVING total_profit < 0 ORDER BY total_profit ASC;
