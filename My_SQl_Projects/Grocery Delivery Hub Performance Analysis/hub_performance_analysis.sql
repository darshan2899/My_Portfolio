-- Question Addressed
-- What are the total number of orders and late orders for each hub, and what are the reasons for delays?
-- Which are the top 5 hubs with the highest number of associates?
-- Which associates have handled the highest number of orders?
-- What are the counts of late orders by reason for each hub?
-- What is the overall performance of each hub, including total orders, late orders, and the percentage of late orders?
-- What is the average number of orders handled per month by each associate?
-- What is the average delay time (in days) for late orders by hub?
-- What is the percentage of late orders for each hub?

-- Total Number of Orders and Late Orders for Each Hub, and Reasons for Delays
WITH HubOrderDetails AS (
    SELECT o.hub_id,
           h.hub_name,
           COUNT(o.order_id) AS total_orders,
           SUM(CASE WHEN o.status = 'Late' THEN 1 ELSE 0 END) AS late_orders
    FROM orders o
    JOIN hubs h ON o.hub_id = h.hub_id
    GROUP BY o.hub_id, h.hub_name
),
DelayReasons AS (
    SELECT o.hub_id,
           d.reason_description,
           COUNT(od.order_id) AS reason_count
    FROM order_delays od
    JOIN delay_reasons d ON od.reason_id = d.reason_id
    JOIN orders o ON od.order_id = o.order_id
    WHERE o.status = 'Late'
    GROUP BY o.hub_id, d.reason_description
)
SELECT h.hub_name,
       h.total_orders,
       h.late_orders,
       dr.reason_description,
       dr.reason_count
FROM HubOrderDetails h
LEFT JOIN DelayReasons dr ON h.hub_id = dr.hub_id
ORDER BY h.hub_name, dr.reason_description;

-- Percentage of Late Orders for Each Hub

WITH TotalOrders AS (
    SELECT hub_id,
           COUNT(order_id) AS total_orders
    FROM orders
    GROUP BY hub_id
),
LateOrders AS (
    SELECT hub_id,
           COUNT(order_id) AS late_orders
    FROM orders
    WHERE status = 'Late'
    GROUP BY hub_id
)
SELECT h.hub_name,
       COALESCE(l.late_orders, 0) AS late_orders,
       COALESCE(t.total_orders, 0) AS total_orders,
       ROUND((COALESCE(l.late_orders, 0) / COALESCE(t.total_orders, 1)) * 100, 2) AS percentage_late_orders
FROM TotalOrders t
LEFT JOIN LateOrders l ON t.hub_id = l.hub_id
JOIN hubs h ON t.hub_id = h.hub_id
ORDER BY percentage_late_orders DESC;

-- Associates with Highest Number of Orders Handled

WITH AssociateOrderCount AS (
    SELECT a.associate_id,
           a.name,
           COUNT(o.order_id) AS orders_handled
    FROM hub_associates a
    JOIN orders o ON a.hub_id = o.hub_id
    WHERE o.status = 'Delivered'
    GROUP BY a.associate_id, a.name
),
RankedAssociates AS (
    SELECT associate_id,
           name,
           orders_handled,
           RANK() OVER (ORDER BY orders_handled DESC) AS rank
    FROM AssociateOrderCount
)
SELECT name,
       orders_handled
FROM RankedAssociates
WHERE rank <= 5;

-- Average Delay Time (in Days) for Late Orders by Hub

WITH DelayTimes AS (
    SELECT o.hub_id,
           AVG(DATEDIFF(o.delivery_date, o.order_date)) AS avg_delay_days
    FROM orders o
    WHERE o.status = 'Late'
    GROUP BY o.hub_id
)
SELECT h.hub_name,
       dt.avg_delay_days
FROM DelayTimes dt
JOIN hubs h ON dt.hub_id = h.hub_id
ORDER BY avg_delay_days DESC;

-- Counts of Late Orders by Reason for Each Hub

WITH ReasonCounts AS (
    SELECT o.hub_id,
           d.reason_description,
           COUNT(od.order_id) AS reason_count
    FROM order_delays od
    JOIN delay_reasons d ON od.reason_id = d.reason_id
    JOIN orders o ON od.order_id = o.order_id
    WHERE o.status = 'Late'
    GROUP BY o.hub_id, d.reason_description
)
SELECT h.hub_name,
       rc.reason_description,
       rc.reason_count
FROM ReasonCounts rc
JOIN hubs h ON rc.hub_id = h.hub_id
ORDER BY h.hub_name, rc.reason_description;

-- Hub Performance: Total Orders, Late Orders, and Percentage of Late Orders

WITH HubPerformance AS (
    SELECT h.hub_name,
           COUNT(o.order_id) AS total_orders,
           SUM(CASE WHEN o.status = 'Late' THEN 1 ELSE 0 END) AS late_orders
    FROM orders o
    JOIN hubs h ON o.hub_id = h.hub_id
    GROUP BY h.hub_name
)
SELECT hub_name,
       total_orders,
       late_orders,
       ROUND((late_orders / total_orders) * 100, 2) AS late_order_percentage
FROM HubPerformance
ORDER BY late_order_percentage DESC;

-- Average Number of Orders Handled Per Month by Each Associate

WITH AssociateMonthlyOrders AS (
    SELECT a.associate_id,
           a.name,
           EXTRACT(YEAR FROM o.order_date) AS year,
           EXTRACT(MONTH FROM o.order_date) AS month,
           COUNT(o.order_id) AS monthly_orders
    FROM hub_associates a
    JOIN orders o ON a.hub_id = o.hub_id
    GROUP BY a.associate_id, a.name, year, month
),
AssociateAverageOrders AS (
    SELECT associate_id,
           name,
           AVG(monthly_orders) AS avg_orders_per_month
    FROM AssociateMonthlyOrders
    GROUP BY associate_id, name
)
SELECT name,
       avg_orders_per_month
FROM AssociateAverageOrders
ORDER BY avg_orders_per_month DESC;

-- Top 5 Hubs with the Highest Number of Associates

WITH HubAssociateCounts AS (
    SELECT hub_id,
           COUNT(associate_id) AS associate_count
    FROM hub_associates
    GROUP BY hub_id
),
RankedHubs AS (
    SELECT h.hub_name,
           hac.associate_count,
           RANK() OVER (ORDER BY hac.associate_count DESC) AS rank
    FROM HubAssociateCounts hac
    JOIN hubs h ON hac.hub_id = h.hub_id
)
SELECT hub_name,
       associate_count
FROM RankedHubs
WHERE rank <= 5;
