-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 7: Executive Business Recommendations
-- STEP 39B: Executive Business Recommendations
--
-- PURPOSE:
-- Convert validated analytical findings into
-- actionable recommendations for business management.
--
-- NOTE:
-- Recommendations are proposed actions.
-- They are not proven campaign outcomes.
-- =====================================================

-- SECTION 1: Create a structured recommendation table.
WITH executive_recommendations AS (

    SELECT
        1 AS recommendation_priority,
        'High-Value Inactive Customers' AS focus_area,

        21049 AS target_customers,

        7455836.07::NUMERIC(14,2)
            AS historical_revenue,

        '56.39% of total historical revenue'
            AS supporting_evidence,

        'Prioritise high-value inactive customers for retention investigation'
            AS recommended_action,
'Reactivation Rate'
    AS success_kpi

    UNION ALL

    SELECT
        2,
        'Critical Priority Customers',
        6845,
        2484204.66::NUMERIC(14,2),
        'Customers inactive for more than 365 days',
        'Design a controlled personalised win-back campaign',
        'Reactivation Rate'

    UNION ALL

    SELECT
        3,
        'Customer Inactivity',
        65963,
        9261584.55::NUMERIC(14,2),
        '70.66% of customers and 70.05% of historical revenue',
        'Monitor customers inactive for more than 180 days',
        'Customer Reactivation Rate'

    UNION ALL

    SELECT
        4,
        'Revenue Concentration',
        23340,
        8267417.24::NUMERIC(14,2),
        'Top 25% of customers contribute 62.53% of revenue',
        'Monitor dependence on high-value customers and protect retention',
        'Top Quartile Revenue Contribution'

    UNION ALL

    SELECT
        5,
        'Campaign Effectiveness',
        NULL::INTEGER,
        NULL::NUMERIC(14,2),
        'Actual campaign exposure and response data are unavailable',
        'Run a treatment-versus-control experiment and measure incremental lift',
        'Incremental Purchase Lift'
)

-- SECTION 2: Display recommendations in priority order.
SELECT
    recommendation_priority,
    focus_area,
    target_customers,
    historical_revenue,
    supporting_evidence,
    recommended_action,
    success_kpi,

    'Proposed - Requires Business Validation'
        AS recommendation_status

FROM executive_recommendations

ORDER BY recommendation_priority;