WITH raw_encounters AS (
    SELECT * FROM {{ source('bronze', 'encounters') }}
)

SELECT
    id AS encounter_id,
    start AS encounter_start_datetime,
    stop AS encounter_end_datetime,
    patient AS patient_id,
    organization AS organization_id,
    provider AS provider_id,
    encounterclass AS encounter_class,
    code AS encounter_code,
    description AS encounter_description,
    base_encounter_cost AS base_cost,
    total_claim_cost,
    payer_coverage,
    reasoncode AS reason_code,
    reasondescription AS reason_description
FROM raw_encounters
