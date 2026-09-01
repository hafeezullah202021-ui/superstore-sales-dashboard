/* ============================================================================
 * Superstore Sales Performance — analysis queries
 *
 * Source table : orders  (loaded from Superstore_Cleaned.xlsx, 9,994 order lines)
 * Coverage     : 2014-01-03 to 2017-12-30, United States
 * Totals       : Sales 2,297,200.86 | Profit 286,397.02 | Mean discount 15.62%
 * Dialect      : SQLite. "Order Date" is held as TEXT (YYYY-MM-DD), which is why
 *                Q3 slices the month with substr() rather than a date function.
 *
 * PART 1 (Q1-Q6) answers the six headline business questions.
 * PART 2 (Q7-Q14) is the supporting evidence for the four business insights
 * written up in README.md — discount behaviour, the Tables loss, the Furniture
 * margin gap, and segment profitability.
 *
 * The result of every query is recorded beneath it. All figures below were
 * produced by running these statements against Superstore_Cleaned.xlsx.
 * ==========================================================================*/


/* ---------------------------------------------------------------------------
 * PART 1 — The six business questions
 * ------------------------------------------------------------------------*/

-- 1. Which regions drive the most sales and profit?
SELECT Region, ROUND(SUM(Sales),2) AS total_sales, ROUND(SUM(Profit),2) AS total_profit,
       ROUND(SUM(Profit)*100.0/SUM(Sales),2) AS profit_margin_pct
FROM orders GROUP BY Region ORDER BY total_sales DESC;
--   West     725457.82  108418.45  14.94
--   East     678781.24   91522.78  13.48
--   Central  501239.89   39706.36   7.92
--   South    391721.91   46749.43  11.93
-- West leads on both revenue and margin. Central is third on revenue but last
-- on margin by a wide gap — the thread picked up in Q7.


-- 2. What are the top 5 revenue-generating sub-categories?
SELECT "Sub-Category", ROUND(SUM(Sales),2) AS revenue
FROM orders GROUP BY "Sub-Category" ORDER BY revenue DESC LIMIT 5;
--   Phones   330007.05
--   Chairs   328449.10
--   Storage  223843.61
--   Tables   206965.53
--   Binders  203412.73


-- 3. How does revenue trend month over month?
SELECT substr("Order Date", 1, 7) AS month, ROUND(SUM(Sales),2) AS monthly_sales
FROM orders GROUP BY month ORDER BY month;
-- 48 months returned. The five largest are:
--   2017-11  118447.82
--   2016-12   96999.04
--   2017-09   87866.65
--   2017-12   83829.32
--   2014-09   81777.35
-- November and December dominate in every year of the series.


-- 4. Which product category is most profitable relative to sales?
SELECT Category, ROUND(SUM(Profit)*100.0/SUM(Sales),2) AS profit_margin_pct
FROM orders GROUP BY Category ORDER BY profit_margin_pct DESC;
--   Technology       17.40
--   Office Supplies  17.04
--   Furniture         2.49
-- Technology leads on margin, and (see Q13) on revenue as well.


-- 5. Who are the highest lifetime-value customers?
SELECT "Customer Name", ROUND(SUM(Sales),2) AS lifetime_spend
FROM orders GROUP BY "Customer Name" ORDER BY lifetime_spend DESC LIMIT 10;
--   Sean Miller         25043.05      Ken Lonsdale        14175.23
--   Tamara Chand        19052.22      Sanjit Chand        14142.33
--   Raymond Buch        15117.34      Hunter Lopez        12873.30
--   Tom Ashbrook        14595.62      Sanjit Engle        12209.44
--   Adrian Barton       14473.57      Christopher Conant  12129.07


-- 6. Which sub-categories are losing money?
SELECT "Sub-Category", ROUND(SUM(Sales),2) AS revenue, ROUND(SUM(Profit),2) AS total_profit
FROM orders GROUP BY "Sub-Category" HAVING total_profit < 0 ORDER BY total_profit ASC;
--   Tables     206965.53  -17725.48
--   Bookcases  114880.00   -3472.56
--   Supplies    46673.54   -1189.10
-- Tables is the largest loss in the catalogue despite being 4th on revenue.


/* ---------------------------------------------------------------------------
 * PART 2 — Evidence for the business insights in README.md
 * ------------------------------------------------------------------------*/

/* Insight 1: Central's weak margin is a discounting problem, not a demand
   problem. Q7 establishes that Central discounts roughly twice as hard as
   anywhere else; Q8 shows the behaviour is concentrated in two categories
   rather than spread across the region's whole book. */

-- 7. Does discounting explain the regional margin gap?
SELECT Region, ROUND(AVG(Discount)*100,2) AS avg_discount_pct, COUNT(*) AS orders,
       ROUND(SUM(Profit)*100.0/SUM(Sales),2) AS profit_margin_pct
FROM orders GROUP BY Region ORDER BY avg_discount_pct DESC;
--   Central  24.04  2323   7.92
--   South    14.73  1620  11.93
--   East     14.54  2848  13.48
--   West     10.93  3203  14.94
-- Discount rate and margin rank in near-perfect inverse order across regions.


-- 8. Where inside Central is the discounting concentrated?
SELECT Category, Region, ROUND(AVG(Discount)*100,2) AS avg_discount_pct
FROM orders WHERE Category IN ('Furniture','Office Supplies')
GROUP BY Category, Region ORDER BY Category, avg_discount_pct DESC;
--   Furniture        Central  29.74      Office Supplies  Central  25.27
--   Furniture        East     15.41      Office Supplies  South    16.74
--   Furniture        West     13.14      Office Supplies  East     14.29
--   Furniture        South    12.15      Office Supplies  West      9.34
-- Central discounts Furniture ~2x and Office Supplies ~1.6x the next region.
-- This is category-level pricing behaviour, not a uniformly weaker market.


/* Insight 2: Tables lose money because of discount depth, not the product.
   Q9 sets the context, Q10 measures the discount-profit relationship, and
   Q11/Q12 show the split between loss-making and profitable Table orders. */

-- 9. How does discount depth track with sub-category profitability?
SELECT "Sub-Category", ROUND(SUM(Sales),2) AS revenue, ROUND(SUM(Profit),2) AS profit,
       ROUND(AVG(Discount)*100,2) AS avg_discount_pct
FROM orders GROUP BY "Sub-Category" ORDER BY revenue DESC LIMIT 6;
--   Phones    330007.05   44515.73  15.46
--   Chairs    328449.10   26590.17  17.02
--   Storage   223843.61   21278.83   7.47
--   Tables    206965.53  -17725.48  26.13
--   Binders   203412.73   30221.76  37.23
--   Machines  189238.63    3384.76  30.61
-- Tables carries a 26.13% average discount against 15.62% company-wide.
-- Binders discounts harder still and stays profitable, so discount depth alone
-- is not automatically fatal — which is what Q10 tests directly.


-- 10. How strongly does discount move with profit — overall, and on Tables?
--     Pearson r, written without SQRT so it runs on SQLite builds compiled
--     without the optional math functions. r = sign(covariance) * sqrt(r_squared).
SELECT 'All orders' AS scope, COUNT(*) AS n,
       ROUND(AVG(Discount*Profit) - AVG(Discount)*AVG(Profit), 4) AS covariance,
       ROUND((AVG(Discount*Profit) - AVG(Discount)*AVG(Profit)) *
             (AVG(Discount*Profit) - AVG(Discount)*AVG(Profit)) /
             ((AVG(Discount*Discount) - AVG(Discount)*AVG(Discount)) *
              (AVG(Profit*Profit)     - AVG(Profit)*AVG(Profit))), 4) AS r_squared
FROM orders
UNION ALL
SELECT 'Tables only', COUNT(*),
       ROUND(AVG(Discount*Profit) - AVG(Discount)*AVG(Profit), 4),
       ROUND((AVG(Discount*Profit) - AVG(Discount)*AVG(Profit)) *
             (AVG(Discount*Profit) - AVG(Discount)*AVG(Profit)) /
             ((AVG(Discount*Discount) - AVG(Discount)*AVG(Discount)) *
              (AVG(Profit*Profit)     - AVG(Profit)*AVG(Profit))), 4)
FROM orders WHERE "Sub-Category" = 'Tables';
--   All orders   9994  -10.6141  0.0482   ->  r = -0.2195
--   Tables only   319  -26.1898  0.4513   ->  r = -0.6718
-- The discount-profit relationship on Tables is three times as strong as it is
-- across the book as a whole.
--
-- On PostgreSQL, MySQL or a SQLite build with math functions, the same result
-- is available directly:  CORR(Discount, Profit)  /  the SQRT form of the above.


-- 11. Do loss-making Table orders differ from profitable ones by discount?
SELECT CASE WHEN Profit < 0 THEN 'Loss-making' ELSE 'Profitable' END AS outcome,
       COUNT(*) AS orders, ROUND(AVG(Discount)*100,2) AS avg_discount_pct,
       ROUND(SUM(Profit),2) AS total_profit
FROM orders WHERE "Sub-Category" = 'Tables' GROUP BY outcome;
--   Loss-making  203  36.53  -32412.15
--   Profitable   116   7.93   14686.67
-- Profitable Table orders exist in volume and average a 7.93% discount, so
-- healthy margin is achievable on this product at shallower discounts.


-- 12. How much of the Table book is discounted past 30%?
SELECT COUNT(*) AS table_orders,
       SUM(CASE WHEN Discount >= 0.30 THEN 1 ELSE 0 END) AS discounted_30_plus,
       ROUND(SUM(CASE WHEN Discount >= 0.30 THEN 1.0 ELSE 0.0 END)*100/COUNT(*),1) AS pct_of_table_orders
FROM orders WHERE "Sub-Category" = 'Tables';
--   319  176  55.2
-- A majority of Table orders sit at or beyond the discount level that Q11
-- associates with losses.


/* Insight 3: Furniture's weak margin is not fully explained by discounting. */

-- 13. Category margin against category discount.
SELECT Category, ROUND(SUM(Sales),2) AS revenue, ROUND(SUM(Profit),2) AS profit,
       ROUND(SUM(Profit)*100.0/SUM(Sales),2) AS profit_margin_pct,
       ROUND(AVG(Discount)*100,2) AS avg_discount_pct
FROM orders GROUP BY Category ORDER BY revenue DESC;
--   Technology       836154.03  145454.95  17.40  13.23
--   Furniture        741999.80   18451.27   2.49  17.39
--   Office Supplies  719047.03  122490.80  17.04  15.73
-- Furniture and Technology sit close on revenue, but 14.9 margin points apart
-- on only a 4.2-point discount difference. Discounting cannot account for the
-- whole gap, which points to thinner base margins in the category itself.


/* Insight 4: Home Office is the most profitable segment per dollar sold. */

-- 14. Segment revenue and margin.
SELECT Segment, ROUND(SUM(Sales),2) AS revenue, ROUND(SUM(Profit),2) AS profit,
       ROUND(SUM(Profit)*100.0/SUM(Sales),2) AS profit_margin_pct
FROM orders GROUP BY Segment ORDER BY profit_margin_pct DESC;
--   Home Office   429653.15   60298.68  14.03
--   Corporate     706146.37   91979.13  13.03
--   Consumer     1161401.34  134119.21  11.55
-- Margin runs inverse to size: the smallest segment converts best, the largest
-- converts worst.
