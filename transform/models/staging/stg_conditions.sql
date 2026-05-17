WITH raw_conditions AS (
    SELECT * FROM {{ source('bronze', 'conditions') }}
)

SELECT
    START AS condition_start_date,
    STOP AS condition_end_date,
    PATIENT AS patient_id,
    ENCOUNTER AS encounter_id,
    CODE AS condition_code,
    DESCRIPTION AS condition_description
FROM raw_conditions