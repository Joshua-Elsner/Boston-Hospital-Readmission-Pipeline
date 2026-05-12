from dagster import Definitions, load_assets_from_modules

# Import the specific layer module from your assets directory
from .assets import bronze

# Load all assets from the bronze module (patients, encounters, conditions)
all_assets = load_assets_from_modules([bronze])

defs = Definitions(
    assets=all_assets,
)