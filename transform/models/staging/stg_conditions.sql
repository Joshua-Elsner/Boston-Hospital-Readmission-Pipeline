WITH raw_conditions AS (
    SELECT * FROM {{ source('bronze', 'conditions') }}
)

SELECT
    start AS condition_start_date,
    stop AS condition_end_date,
    patient AS patient_id,
    encounter AS encounter_id,
    code AS condition_code,
    description AS condition_description
FROM raw_conditions
