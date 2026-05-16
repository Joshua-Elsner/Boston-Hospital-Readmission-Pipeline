WITH stg_patients AS (
    SELECT * FROM {{ ref('stg_patients') }}
)

SELECT
    patient_id,
    first_name,
    last_name,
    gender,
    race,
    ethnicity,
    birth_date,
    death_date,
    -- Business Logic: Calculate actual age
    CASE 
        WHEN death_date IS NOT NULL THEN DATE_DIFF(CAST(death_date AS DATE), CAST(birth_date AS DATE), YEAR)
        ELSE DATE_DIFF(CURRENT_DATE(), CAST(birth_date AS DATE), YEAR)
    END AS current_age,
    city,
    state,
    county,
    zip_code
FROM stg_patients