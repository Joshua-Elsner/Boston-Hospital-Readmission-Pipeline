WITH raw_patients AS (
    SELECT * FROM {{ source('bronze', 'patients') }}
)

SELECT
    id AS patient_id,
    birthdate AS birth_date,
    deathdate AS death_date,
    prefix,
    first AS first_name,
    last AS last_name,
    gender,
    race,
    ethnicity,
    city,
    state,
    county,
    zip AS zip_code
FROM raw_patients
