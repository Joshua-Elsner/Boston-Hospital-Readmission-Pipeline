-- test: assert_discharge_after_admission
-- If this query returns any rows, the test fails.
-- We are selecting records where a patient was discharged BEFORE they were admitted.

SELECT
    encounter_id,
    patient_id,
    encounter_start_datetime,
    encounter_end_datetime
FROM {{ ref('stg_encounters') }}
WHERE encounter_end_datetime < encounter_start_datetime