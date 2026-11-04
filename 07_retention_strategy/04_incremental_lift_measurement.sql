-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 6: Retention Strategy & Business Recommendations
-- STEP 38D: Incremental Lift Measurement Framework
--
-- PURPOSE:
-- Define the treatment vs control comparison required
-- to measure campaign-driven incremental purchases.
--
-- NOTE:
-- Olist does not contain actual campaign assignment
-- or campaign exposure records. Results are therefore
-- marked as unavailable until experiment data exists.
-- =====================================================

-- SECTION 1: Define the required experiment metrics.
WITH measurement_framework AS (

    SELECT
        'Treatment Group' AS experiment_group,
        'Customers exposed to retention campaign'
            AS group_definition,
        'Customers who purchased after campaign'
            AS required_outcome,
        'Post-campaign purchase rate'
            AS primary_metric

    UNION ALL

    SELECT
        'Control Group',
        'Customers not exposed to retention campaign',
        'Customers who purchased during the same period',
        'Post-campaign purchase rate'
),

-- SECTION 2: Define the required lift calculations.
lift_definitions AS (

    SELECT
        'Treatment Purchase Rate' AS metric_name,
        'Treatment purchasers / Treatment customers * 100'
            AS calculation_formula

    UNION ALL

    SELECT
        'Control Purchase Rate',
        'Control purchasers / Control customers * 100'

    UNION ALL

    SELECT
        'Absolute Incremental Lift',
        'Treatment purchase rate - Control purchase rate'

    UNION ALL

    SELECT
        'Relative Incremental Lift',
       '((Treatment rate - Control rate) / NULLIF(Control rate, 0)) * 100'

    UNION ALL

    SELECT
        'Incremental Purchasers',
       'Treatment customers * (Treatment rate - Control rate) / 100'
)

-- SECTION 3: Display the experiment measurement framework.
SELECT
    experiment_group AS analysis_group,
    group_definition AS group_description,
    required_outcome AS required_data,
    primary_metric AS measurement_metric,
    'Not Available - Campaign Data Required'
        AS current_status
FROM measurement_framework

UNION ALL

SELECT
    'Lift Calculation',
    metric_name,
    calculation_formula,
    'Incremental Impact',
    'Not Calculable - No Actual Experiment Results'
FROM lift_definitions;