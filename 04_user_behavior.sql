-- =============================================================================
-- 04_user_behavior.sql
-- Purpose : User segmentation and behavioral pattern analysis
-- Platform: Digital gold trading app
-- Logic   : Classifies users by trading frequency, recency, and order size.
--           Uses an RFM-style framework (Recency, Frequency, Monetary value)
--           adapted for a gold trading context.
-- Business question:
--   "Who are our most valuable users? Which segments are slipping away?
--    How do verified users trade differently from unverified ones?"
-- =============================================================================


-- ── Query A: RFM-style user segments ─────────────────────────────────────────
-- Recency   = days since last order
-- Frequency = total number of orders
-- Monetary  = lifetime trading value
WITH user_stats AS (
    SELECT
        o.user                                          AS user_id,
        COUNT(o.id)                                     AS frequency,
        ROUND(SUM(o.totalvalue), 2)                     AS monetary,
        ROUND(AVG(o.totalvalue), 2)                     AS avg_order_value,
        ROUND(SUM(o.requestvolume), 2)                  AS total_weight_grams,
        MIN(o.createdat)                                AS first_order_date,
        MAX(o.createdat)                                AS last_order_date,
        ROUND(julianday('now') - julianday(MAX(o.createdat)), 0)
                                                        AS recency_days,

        -- Derived: days between first and last order (tenure span)
        ROUND(julianday(MAX(o.createdat)) - julianday(MIN(o.createdat)), 0)
                                                        AS active_span_days

    FROM   orders o
    WHERE  o.createdat IS NOT NULL
    GROUP  BY o.user
),

segmented AS (
    SELECT
        *,
        -- Frequency segment
        CASE
            WHEN frequency >= 10 THEN 'Power Trader'
            WHEN frequency >= 4  THEN 'Regular Trader'
            WHEN frequency >= 2  THEN 'Occasional Trader'
            ELSE                      'One-Time Buyer'
        END                                             AS frequency_segment,

        -- Recency segment
        CASE
            WHEN recency_days <= 30  THEN 'Active (≤30d)'
            WHEN recency_days <= 90  THEN 'Warm (31–90d)'
            WHEN recency_days <= 180 THEN 'At Risk (91–180d)'
            ELSE                          'Churned (>180d)'
        END                                             AS recency_segment

    FROM   user_stats
)

SELECT
    frequency_segment,
    recency_segment,
    COUNT(DISTINCT user_id)             AS num_users,
    ROUND(AVG(frequency), 1)            AS avg_orders,
    ROUND(AVG(monetary), 2)             AS avg_lifetime_value,
    ROUND(AVG(avg_order_value), 2)      AS avg_order_value,
    ROUND(AVG(recency_days), 0)         AS avg_recency_days,
    ROUND(AVG(active_span_days), 0)     AS avg_active_span_days

FROM   segmented
GROUP  BY frequency_segment, recency_segment
ORDER  BY avg_lifetime_value DESC;


-- =============================================================================
-- ── Query B: Verified vs. unverified user trading behaviour ──────────────────
-- Tests whether verification status correlates with higher trade volume / value.
-- Insight guides decisions about KYC incentives and verification prompts.
-- =============================================================================
/*
SELECT
    CASE
        WHEN u.VerificationStatus >= 1 THEN 'Verified'
        ELSE 'Unverified'
    END                                         AS verification_group,

    COUNT(DISTINCT u.id)                        AS total_users,
    COUNT(DISTINCT o.user)                      AS trading_users,
    ROUND(
        1.0 * COUNT(DISTINCT o.user) / COUNT(DISTINCT u.id),
        4
    )                                           AS activation_rate,

    ROUND(AVG(u.OrderCount), 1)                 AS avg_lifetime_orders,
    ROUND(AVG(u.TotalDeposit), 2)               AS avg_total_deposit,
    ROUND(AVG(u.TotalWithdraw), 2)              AS avg_total_withdraw

FROM       users  u
LEFT JOIN  orders o ON o.user = u.id
GROUP  BY  verification_group
ORDER  BY  avg_total_deposit DESC;
*/


-- =============================================================================
-- ── Query C: Gender & source breakdown ───────────────────────────────────────
-- Useful for marketing segmentation and personalised campaign planning.
-- =============================================================================
/*
SELECT
    COALESCE(u.Gender, 'Unknown')           AS gender,
    COALESCE(u.Source, 'Unknown')           AS acquisition_source,
    COUNT(DISTINCT u.id)                    AS total_users,
    ROUND(AVG(u.OrderCount), 1)             AS avg_orders,
    ROUND(AVG(u.TotalDeposit), 2)           AS avg_deposit,
    COUNT(DISTINCT CASE WHEN u.VerificationStatus >= 1 THEN u.id END)
                                            AS verified_users

FROM   users u
GROUP  BY gender, acquisition_source
ORDER  BY total_users DESC;
*/
