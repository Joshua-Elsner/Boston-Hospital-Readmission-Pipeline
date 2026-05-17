import os
from dagster import Definitions, load_assets_from_modules, AssetKey
from dagster_dbt import DbtCliResource, dbt_assets, DbtProject, DagsterDbtTranslator
from .assets import bronze

# 1. Load your Python ingestion assets
python_assets = load_assets_from_modules([bronze])

# 2. Point Dagster to your dbt project folder
DBT_PROJECT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../transform"))

my_dbt_project = DbtProject(project_dir=DBT_PROJECT_DIR)
my_dbt_project.prepare_if_dev() # Compiles the dbt project

# 3. The Bridge: Tell Dagster your Python scripts feed your dbt models!
class CustomDagsterDbtTranslator(DagsterDbtTranslator):
    def get_asset_key(self, dbt_resource_props):
        # When dbt looks for a source table (e.g., 'patients'), point it to the Python asset ('bronze_patients')
        if dbt_resource_props["resource_type"] == "source":
            table_name = dbt_resource_props["name"]
            return AssetKey([f"bronze_{table_name}"])
        
        return super().get_asset_key(dbt_resource_props)

# 4. Read the compiled dbt models with the translator attached
@dbt_assets(
    manifest=my_dbt_project.manifest_path,
    dagster_dbt_translator=CustomDagsterDbtTranslator()
)
def hospital_dbt_assets(context, dbt: DbtCliResource):
    yield from dbt.cli(["build"], context=context).stream()

# 5. Combine everything into the final Definitions object
defs = Definitions(
    assets=[*python_assets, hospital_dbt_assets],
    resources={
        "dbt": DbtCliResource(project_dir=my_dbt_project),
    },
)