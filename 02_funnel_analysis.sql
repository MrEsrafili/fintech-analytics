-- =============================================================================
-- 02_funnel_analysis.sql
-- Purpose : Registration-to-activation-to-retention funnel
-- Platform: Digital gold trading app
-- Logic   : Track every user from sign-up through their first trade, second
--           trade, and verified status. Each CTE adds one funnel stage.
-- Business question:
--   "How many registered users actually start trading, and how quickly
--    do they convert? Where do we lose the most users in the funnel?"
-- =============================================================================

-- Stage 0 – All registered users
WITH all_users AS (
    SELECT
        id                                      AS user_id,
        CreatedAt                               AS registered_at,
        Source                                  AS acquisition_channel,
        VerificationStatus                      AS is_verified
    FROM   users
    WHERE  CreatedAt IS NOT NULL
),

-- Stage 1 – Users who placed at least 1 order (activated)
first_order AS (
    SELECT
        user                                    AS user_id,
        MIN(createdat)                          AS first_order_date
    FROM   orders
    WHERE  createdat IS NOT NULL
    GROUP  BY user
),

-- Stage 2 – Users who placed at least 2 orders (repeat buyers)
repeat_buyers AS (
    SELECT
        user                                    AS user_id,
        COUNT(id)                               AS total_orders,
        MIN(createdat)                          AS first_order_date,
        MAX(createdat)                          AS last_order_date
    FROM   orders
    WHERE  createdat IS NOT NULL
    GROUP  BY user
    HAVING COUNT(id) >= 2
),

-- Combine stages per user
user_funnel AS (
    SELECT
        u.user_id,
        u.registered_at,
        u.acquisition_channel,
        u.is_verified,
        fo.first_order_date,
        rb.total_orders,
        rb.last_order_date,

        -- Days from registration to first order (activation lag)
        ROUND(
            julianday(fo.first_order_date) - julianday(u.registered_at),
            1
        )                                       AS days_to_first_order,

        -- Funnel stage flags
        CASE WHEN fo.user_id  IS NOT NULL THEN 1 ELSE 0 END  AS has_ordered,
        CASE WHEN rb.user_id  IS NOT NULL THEN 1 ELSE 0 END  AS is_repeat_buyer,
        CASE WHEN u.is_verified >= 1      THEN 1 ELSE 0 END  AS is_verified_flag
    FROM       all_users  u
    LEFT JOIN  first_order fo  ON fo.user_id = u.user_id
    LEFT JOIN  repeat_buyers rb ON rb.user_id = u.user_id
)

-- ── Funnel summary by acquisition channel ────────────────────────────────────
SELECT
    COALESCE(acquisition_channel, 'Unknown')    AS channel,
    COUNT(DISTINCT user_id)                     AS registered_users,

    -- Stage 1: at least 1 order
    SUM(has_ordered)                            AS activated_users,
    ROUND(1.0 * SUM(has_ordered) / COUNT(DISTINCT user_id), 4)
                                                AS activation_rate,

    -- Stage 2: 2+ orders
    SUM(is_repeat_buyer)                        AS repeat_buyers,
    ROUND(1.0 * SUM(is_repeat_buyer) / NULLIF(SUM(has_ordered), 0), 4)
                                                AS repeat_rate,

    -- Stage 3: verified users
    SUM(is_verified_flag)                       AS verified_users,
    ROUND(1.0 * SUM(is_verified_flag) / COUNT(DISTINCT user_id), 4)
                                                AS verification_rate,

    -- Speed-to-activate
    ROUND(AVG(CASE WHEN has_ordered = 1 THEN days_to_first_order END), 1)
                                                AS avg_days_to_first_order

FROM   user_funnel
GROUP  BY channel
ORDER  BY registered_users DESC;
