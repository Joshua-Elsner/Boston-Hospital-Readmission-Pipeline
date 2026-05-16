WITH raw_patients AS (
    SELECT * FROM {{ source('boston_hospital', 'bronze_patients') }}
)

SELECT
    Id AS patient_id,
    BIRTHDATE AS birth_date,
    DEATHDATE AS death_date,
    PREFIX AS prefix,
    FIRST AS first_name,
    LAST AS last_name,
    GENDER AS gender,
    RACE AS race,
    ETHNICITY AS ethnicity,
    CITY AS city,
    STATE AS state,
    COUNTY AS county,
    ZIP AS zip_code
FROM raw_patients