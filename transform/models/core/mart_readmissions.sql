WITH base_encounters AS (
    SELECT * FROM {{ ref('fact_encounters') }}
),

-- Bring in the dimension table where you calculated the age brackets
patients AS (
    SELECT * FROM {{ ref('dim_patients') }}
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

-- Step 2: Calculate the date difference, flag 30-day readmissions, and attach demographics/conditions
SELECT
    -- 1. Simple Targets First (Fixes ST06)
    vh.encounter_id,
    vh.patient_id,
    p.current_age,
    p.age_bracket,
    vh.encounter_start_datetime,
    vh.previous_encounter_start,
    vh.encounter_class,
    vh.previous_encounter_class,
    vh.primary_diagnosis_description,

    -- 2. Simple Calculations Next
    DATE_TRUNC(CAST(vh.encounter_start_datetime AS DATE), MONTH) AS encounter_month,

    -- 3. Complex Business Logic (Keep all your existing WHEN statements inside this block)
    CASE
        WHEN vh.primary_diagnosis_description IS NULL THEN 'Administrative / No Diagnosis Provided'

        WHEN
            LOWER(vh.primary_diagnosis_description) LIKE '%employment%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%labor force%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%isolation%' THEN 'Social & Administrative Findings'

        WHEN LOWER(vh.primary_diagnosis_description) LIKE '%history of%' THEN 'Medical History / Status'

        WHEN
            LOWER(vh.primary_diagnosis_description) LIKE '%heart%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%hypertension%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%fibrillation%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%stroke%' THEN 'Cardiovascular'

        WHEN
            LOWER(vh.primary_diagnosis_description) LIKE '%diabetes%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%prediabetes%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%neuropathy%' THEN 'Endocrine & Metabolic'

        WHEN
            LOWER(vh.primary_diagnosis_description) LIKE '%pneumonia%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%asthma%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%bronchitis%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%pulmonary%' THEN 'Respiratory'

        WHEN
            LOWER(vh.primary_diagnosis_description) LIKE '%infection%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%sepsis%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%covid%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%virus%' THEN 'Infectious Disease'

        WHEN
            LOWER(vh.primary_diagnosis_description) LIKE '%depress%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%anxiety%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%stress%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%suicide%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%schizophrenia%' THEN 'Mental Health & Behavioral'

        WHEN
            LOWER(vh.primary_diagnosis_description) LIKE '%injury%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%fracture%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%burn%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%laceration%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%sprain%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%concussion%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%overdose%' THEN 'Injury & Trauma'

        WHEN
            LOWER(vh.primary_diagnosis_description) LIKE '%arthritis%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%osteoporosis%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%pain%' THEN 'Musculoskeletal'

        WHEN
            LOWER(vh.primary_diagnosis_description) LIKE '%neoplasm%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%cancer%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%tumor%' THEN 'Oncology (Cancer)'

        WHEN
            LOWER(vh.primary_diagnosis_description) LIKE '%pregnancy%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%maternal%' THEN 'Maternal & Pregnancy'

        WHEN
            LOWER(vh.primary_diagnosis_description) LIKE '%medication%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%prescription%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%refill%'
            OR LOWER(vh.primary_diagnosis_description) LIKE '%pharm%' THEN 'Medication Management & Review'

        ELSE 'Other / Uncategorized'
    END AS condition_bracket,

    -- 4. Multi-line logic to stay under 120 characters (Fixes LT05)
    DATE_DIFF(
        CAST(vh.encounter_start_datetime AS DATE),
        CAST(vh.previous_encounter_start AS DATE),
        DAY
    ) AS days_since_last_visit,

    CASE
        WHEN
            DATE_DIFF(
                CAST(vh.encounter_start_datetime AS DATE),
                CAST(vh.previous_encounter_start AS DATE),
                DAY
            ) <= 30
            AND vh.previous_encounter_start IS NOT NULL
            THEN 1
        ELSE 0
    END AS is_30_day_readmission

FROM visit_history AS vh
LEFT JOIN patients AS p
    ON vh.patient_id = p.patient_id
