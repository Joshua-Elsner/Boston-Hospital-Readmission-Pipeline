WITH raw_encounters AS (
    SELECT * FROM {{ source('boston_hospital', 'bronze_encounters') }}
)

SELECT
    Id AS encounter_id,
    START AS encounter_start_datetime,
    STOP AS encounter_end_datetime,
    PATIENT AS patient_id,
    ORGANIZATION AS organization_id,
    PROVIDER AS provider_id,
    ENCOUNTERCLASS AS encounter_class,
    CODE AS encounter_code,
    DESCRIPTION AS encounter_description,
    BASE_ENCOUNTER_COST AS base_cost,
    TOTAL_CLAIM_COST AS total_claim_cost,
    PAYER_COVERAGE AS payer_coverage,
    REASONCODE AS reason_code,
    REASONDESCRIPTION AS reason_description
FROM raw_encounters