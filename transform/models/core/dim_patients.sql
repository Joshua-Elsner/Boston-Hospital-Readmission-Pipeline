WITH stg_patients AS (
    SELECT * FROM {{ ref('stg_patients') }}
),

calculate_age AS (
    SELECT
        patient_id,
        first_name,
        last_name,
        gender,
        race,
        ethnicity,
        birth_date,
        death_date,
        city,
        state,
        county,
        zip_code,
        -- Business Logic: Calculate actual age
        CASE
            WHEN death_date IS NOT NULL THEN DATE_DIFF(CAST(death_date AS DATE), CAST(birth_date AS DATE), YEAR)
            ELSE DATE_DIFF(CURRENT_DATE(), CAST(birth_date AS DATE), YEAR)
        END AS current_age
    FROM stg_patients
)

SELECT
    *,
    -- Business Logic: Assign Age Bracket
    CASE
        WHEN current_age < 18 THEN '0-17'
        WHEN current_age BETWEEN 18 AND 34 THEN '18-34'
        WHEN current_age BETWEEN 35 AND 49 THEN '35-49'
        WHEN current_age BETWEEN 50 AND 64 THEN '50-64'
        WHEN current_age >= 65 THEN '65+'
        ELSE 'Unknown'
    END AS age_bracket
FROM calculate_age
