--Customer segmentation based on order count and lifetime revenue
--1 part:Creating customers table
CREATE OR REPLACE VIEW customer_segments AS --it is for other queries see 'customers' table,cause CTE is temporary
WITH customers AS(
    SELECT
        o.user_id,
        COUNT(DISTINCT(o.order_id)) AS order_count,
        ROUND(SUM(o.price_usd):: numeric,2) AS lifetime_revenue,
        ABS(EXTRACT(DAY FROM MAX(created_at):: timestamp-'03-19-2015')) AS days_since_purchase
    FROM orders o
    GROUP BY o.user_id
)
SELECT *,
       CASE
           WHEN order_count>=2 AND lifetime_revenue>=180 AND days_since_purchase<=360 THEN 'REGULAR CUSTOMER'
           WHEN order_count=2 THEN 'HALF-REGULAR CUSTOMER'
           ELSE 'ONE-TIME CUSTOMER'
           END AS segment
FROM customers
ORDER BY lifetime_revenue DESC;


--2 part:Every segments summary
SELECT
    segment,
    COUNT(DISTINCT(user_id)) AS customer_count,
    ROUND(SUM(lifetime_revenue)::numeric,2) AS segment_revenue,
    ROUND(AVG(lifetime_revenue)::numeric,2) AS avg_lifetime_revenue
FROM customer_segments
GROUP BY segment
ORDER BY segment_revenue DESC;
--INSIGHT:The company suffers from an extreme retention issue.
--The huge majority of users never return for repeat purchases,
--leaving a tiny fraction of highly loyal customers who drive repeat orders.

--3 part:New/Repeat customers
SELECT
    CASE
        WHEN w.is_repeat_session=0 THEN 'New' ELSE 'Repeat'
        END AS  session_order,
    COUNT(DISTINCT o.user_id) AS user_count,
    COUNT(DISTINCT o.order_id) AS order_count,
    SUM(price_usd) AS total_revenue,
    ROUND((COUNT(DISTINCT o.order_id)*100.0)/COUNT(DISTINCT w.website_session_id)::numeric,2) AS conversion_rate,
FROM website_sessions w
LEFT JOIN orders o ON o.website_session_id=w.website_session_id
GROUP BY is_repeat_session;
--INSIGHT:They bring in significantly more money ($1.56 million versus $372k)
--and make up the most revenue of business.This confirms the overall problem:
--and this confirms the main problem, which is that the business is very weak at
--retaining previous clients and the entire business is geared towards newcomers

--4 part:Device performance
SELECT
    w.device_type,
    COUNT(DISTINCT w.user_id) AS user_count,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(COUNT(DISTINCT o.order_id)*100.0/COUNT(DISTINCT w.user_id),2) AS conversion_rate,
    SUM(price_usd)
FROM website_sessions w
LEFT JOIN orders o ON o.website_session_id=w.website_session_id
GROUP BY device_type;
--INSIGHT:indicating that the mobile experience may require optimisation,
--upgrade in level of comfort,usability

--5 part:traffic utm
SELECT
    utm_source,
    COUNT(DISTINCT w.user_id) as session_count,
    COUNT(DISTINCT o.order_id) as order_count,
    ROUND(100.0*COUNT(DISTINCT o.order_id)/COUNT(DISTINCT w.user_id)::numeric,2) as conversion_rate,
    ROUND(AVG(o.price_usd)::numeric,2) as avg_order_value,
    SUM(price_usd) AS revenue_summ
FROM website_sessions w
LEFT JOIN orders o ON w.website_session_id=o.website_session_id
WHERE utm_source IS NOT NULL
GROUP BY utm_source
ORDER BY avg_order_value DESC;
--Gsearch drives the most orders, while Socialbook has the lowest conversion rate.
--Direct/NULL traffic shows the highest conversion rate (9.25%).
--INSIGHT:Gsearch is the primary scale driver—it attracts the most users and generates the most orders (21,333),
--making it the primary traffic source.
--Socialbook demonstrates the lowest performance, with a low conversion rate (3.21%),
--indicating untargeted or low-quality traffic from this source.



--ANALYSIS SUMMARY:
--1.
--Improve customer retention: Implement trigger marketing, loyalty programs, and personalized email campaigns,
--as the current customer base consists primarily of one-time buyers, and repeat sales are underutilized.
--2.
--Optimize Mobile Funnel: Improve user experience (UX/UI) on smartphones to reduce the conversion
--gap between mobile (3.37%) and desktop (9.63%).
--3.
--Redistribute your advertising budget: Disable the ineffective Socialbook channel with its minimal
--conversion rate (3.21%) and use the freed-up funds to scale up GSearch, which consistently generates the largest volume of orders.
--4.
--Boost Direct Traffic (Direct / NULL): Invest in Brand Awareness to increase the share of direct traffic,
--which has the highest conversion rate (9.25%).




















