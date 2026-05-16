WITH base_encounters AS (
    SELECT * FROM {{ ref('fact_encounters') }}
),

-- Step 1: Use window functions to look backward at the previous visit
visit_history AS (
    SELECT
        encounter_id,
        patient_id,
        encounter_start_datetime,
        encounter_end_datetime,
        encounter_class,
        primary_diagnosis_description,
        -- Grab the start date of the row immediately preceding this one, for this specific patient
        LAG(encounter_start_datetime) OVER (
            PARTITION BY patient_id 
            ORDER BY encounter_start_datetime
        ) AS previous_encounter_start,
        LAG(encounter_class) OVER (
            PARTITION BY patient_id 
            ORDER BY encounter_start_datetime
        ) AS previous_encounter_class
    FROM base_encounters
    -- Standard practice: Readmissions generally only apply to hospital admissions and ER visits
    WHERE encounter_class IN ('inpatient', 'emergency')
)

-- Step 2: Calculate the date difference and flag 30-day readmissions
SELECT
    encounter_id,
    patient_id,
    encounter_start_datetime,
    previous_encounter_start,
    encounter_class,
    previous_encounter_class,
    primary_diagnosis_description,
    -- Calculate the exact number of days between the visits
    DATE_DIFF(CAST(encounter_start_datetime AS DATE), CAST(previous_encounter_start AS DATE), DAY) AS days_since_last_visit,
    -- The Business Logic Flag
    CASE 
        WHEN DATE_DIFF(CAST(encounter_start_datetime AS DATE), CAST(previous_encounter_start AS DATE), DAY) <= 30 
        AND previous_encounter_start IS NOT NULL 
        THEN 1 
        ELSE 0 
    END AS is_30_day_readmission
FROM visit_history