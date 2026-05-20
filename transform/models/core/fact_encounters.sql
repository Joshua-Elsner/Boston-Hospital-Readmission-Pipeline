WITH encounters AS (
    SELECT * FROM {{ ref('stg_encounters') }}
),

conditions AS (
    SELECT * FROM {{ ref('stg_conditions') }}
)

SELECT
    e.encounter_id,
    e.patient_id,
    e.encounter_start_datetime,
    e.encounter_end_datetime,
    e.encounter_class,
    e.encounter_description,
    e.base_cost,
    e.total_claim_cost,
    c.condition_code AS primary_diagnosis_code,
    c.condition_description AS primary_diagnosis_description
FROM encounters AS e
LEFT JOIN conditions AS c
    ON e.encounter_id = c.encounter_id
