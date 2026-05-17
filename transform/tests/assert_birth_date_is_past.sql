-- test: assert_birth_date_is_past
-- If this query returns any rows, the test fails.
-- We are selecting records where the birth date is greater than today's date.

SELECT
    patient_id,
    birth_date
FROM {{ ref('stg_patients') }}
WHERE CAST(birth_date AS DATE) > CURRENT_DATE()