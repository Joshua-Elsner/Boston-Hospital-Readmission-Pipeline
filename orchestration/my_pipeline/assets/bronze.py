import os
import pandas as pd
from dagster import asset, AssetExecutionContext
from google.cloud import bigquery
from dotenv import load_dotenv

# Force Python to read the hidden .env file for GCP authentication
load_dotenv()

# Define the absolute path to your raw data
RAW_DATA_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../raw_data/csv"))

@asset(group_name="bronze_layer", compute_kind="pandas")
def bronze_patients(context: AssetExecutionContext):
    """
    Ingests Synthea patient data into the BigQuery Bronze layer.
    Enforces STRING types for IDs and ZIP codes to prevent data loss.
    """
    project_id = os.environ.get("GCP_PROJECT_ID")
    client = bigquery.Client(project=project_id)
    dataset_id = f"{project_id}.bronze"
    table_id = f"{dataset_id}.patients"

    # Ensure dataset exists
    client.create_dataset(dataset_id, exists_ok=True)

    csv_path = os.path.join(RAW_DATA_DIR, "patients.csv")
    context.log.info(f"Reading from {csv_path}")
    
    # Read locally using pandas (treating everything as string initially to prevent early truncation)
    df = pd.read_csv(csv_path, dtype=str)

    # 1. Define Strict Schema
    schema = [
        bigquery.SchemaField("Id", "STRING", description="Unique Patient Identifier (MRN)"),
        bigquery.SchemaField("BIRTHDATE", "DATE"),
        bigquery.SchemaField("DEATHDATE", "DATE"),
        bigquery.SchemaField("FIRST", "STRING"),
        bigquery.SchemaField("LAST", "STRING"),
        bigquery.SchemaField("GENDER", "STRING"),
        bigquery.SchemaField("CITY", "STRING"),
        bigquery.SchemaField("STATE", "STRING"),
        # Crucial: ZIP must be a string to preserve leading zeros in Massachusetts
        bigquery.SchemaField("ZIP", "STRING"), 
        bigquery.SchemaField("LAT", "FLOAT"),
        bigquery.SchemaField("LON", "FLOAT"),
    ]

    # 2. Configure Load Job
    job_config = bigquery.LoadJobConfig(
        schema=schema,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE, # Overwrite for idempotency
        source_format=bigquery.SourceFormat.CSV,
    )

    # 3. Load to BigQuery
    context.log.info(f"Loading {len(df)} patient records to {table_id}")
    job = client.load_table_from_dataframe(df, table_id, job_config=job_config)
    job.result() # Wait for the job to complete

    context.log.info(f"Successfully loaded {job.output_rows} rows into {table_id}.")


@asset(group_name="bronze_layer", compute_kind="pandas")
def bronze_encounters(context: AssetExecutionContext, bronze_patients):
    """
    Ingests Synthea encounter data. 
    Depends on bronze_patients to establish basic lineage.
    """
    project_id = os.environ.get("GCP_PROJECT_ID")
    client = bigquery.Client(project=project_id)
    dataset_id = f"{project_id}.bronze"
    table_id = f"{dataset_id}.encounters"

    csv_path = os.path.join(RAW_DATA_DIR, "encounters.csv")
    df = pd.read_csv(csv_path, dtype=str)

    schema = [
        bigquery.SchemaField("Id", "STRING", description="Unique Encounter ID"),
        bigquery.SchemaField("START", "TIMESTAMP"),
        bigquery.SchemaField("STOP", "TIMESTAMP"),
        bigquery.SchemaField("PATIENT", "STRING", description="Foreign Key to Patients"),
        bigquery.SchemaField("ORGANIZATION", "STRING"),
        bigquery.SchemaField("PROVIDER", "STRING"),
        bigquery.SchemaField("PAYER", "STRING"),
        bigquery.SchemaField("ENCOUNTERCLASS", "STRING", description="e.g., ambulatory, emergency"),
        bigquery.SchemaField("CODE", "STRING", description="SNOMED code"),
        bigquery.SchemaField("DESCRIPTION", "STRING"),
        bigquery.SchemaField("BASE_ENCOUNTER_COST", "FLOAT"),
        bigquery.SchemaField("TOTAL_CLAIM_COST", "FLOAT"),
        bigquery.SchemaField("PAYER_COVERAGE", "FLOAT"),
        bigquery.SchemaField("REASONCODE", "STRING"),
        bigquery.SchemaField("REASONDESCRIPTION", "STRING"),
    ]

    job_config = bigquery.LoadJobConfig(
        schema=schema,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        source_format=bigquery.SourceFormat.CSV,
    )

    client.load_table_from_dataframe(df, table_id, job_config=job_config).result()
    context.log.info(f"Loaded {len(df)} encounter records.")


@asset(group_name="bronze_layer", compute_kind="pandas")
def bronze_conditions(context: AssetExecutionContext, bronze_encounters):
    """
    Ingests Synthea conditions data (diagnoses).
    Depends on bronze_encounters.
    """
    project_id = os.environ.get("GCP_PROJECT_ID")
    client = bigquery.Client(project=project_id)
    dataset_id = f"{project_id}.bronze"
    table_id = f"{dataset_id}.conditions"

    csv_path = os.path.join(RAW_DATA_DIR, "conditions.csv")
    df = pd.read_csv(csv_path, dtype=str)

    schema = [
        bigquery.SchemaField("START", "DATE"),
        bigquery.SchemaField("STOP", "DATE"),
        bigquery.SchemaField("PATIENT", "STRING", description="Foreign Key to Patients"),
        bigquery.SchemaField("ENCOUNTER", "STRING", description="Foreign Key to Encounters"),
        bigquery.SchemaField("CODE", "STRING", description="SNOMED code"),
        bigquery.SchemaField("DESCRIPTION", "STRING"),
    ]

    job_config = bigquery.LoadJobConfig(
        schema=schema,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        source_format=bigquery.SourceFormat.CSV,
    )

    client.load_table_from_dataframe(df, table_id, job_config=job_config).result()
    context.log.info(f"Loaded {len(df)} condition records.")