from pygris import tracts
import requests
import pandas as pd
from sqlalchemy import create_engine

api_key = "e2751cb55d5b31578ef632b0df6c7515d06139cb"

# Step 1: Get tract boundaries
il_tracts = tracts(state="IL", county="Cook", cb=True, year=2022)
print("Tract boundaries pulled:", len(il_tracts))

# Step 2: Pull population and median household income
url = f"https://api.census.gov/data/2022/acs/acs5?get=NAME,B01003_001E,B19013_001E&for=tract:*&in=state:17+county:031&key={api_key}"
response = requests.get(url)
data = response.json()

census_df = pd.DataFrame(data[1:], columns=data[0])
print(census_df.head())
print("Census rows pulled:", len(census_df))

# Step 3: Join census data to tract boundaries
census_df['GEOID'] = census_df['state'] + census_df['county'] + census_df['tract']

merged = il_tracts.merge(census_df, on='GEOID', how='inner')

print("Merged rows:", len(merged))
print(merged[['GEOID', 'NAME_x', 'B01003_001E', 'B19013_001E']].head())

# Step 4: Prepare data for PostGIS

# Select and rename columns to match our population_zones table
pop_gdf = merged[['NAME_x', 'B01003_001E', 'B19013_001E', 'geometry']].copy()
pop_gdf = pop_gdf.rename(columns={
    'NAME_x': 'tract_name',
    'B01003_001E': 'population',
    'B19013_001E': 'median_income'
})

# Convert population and income to proper numeric types
# Census sometimes returns negative codes (like -666666666) for missing data - we'll treat those as null
pop_gdf['population'] = pd.to_numeric(pop_gdf['population'], errors='coerce')
pop_gdf['median_income'] = pd.to_numeric(pop_gdf['median_income'], errors='coerce')
pop_gdf.loc[pop_gdf['median_income'] < 0, 'median_income'] = None

# Rename geometry column to match our table's 'geom' column
pop_gdf = pop_gdf.rename_geometry('geom')

# Ensure correct coordinate system
pop_gdf = pop_gdf.set_crs("EPSG:4326", allow_override=True)

# Write to PostGIS
engine = create_engine("postgresql://postgres:postgres@localhost:5433/chicago_transit")
pop_gdf.to_postgis("population_zones", engine, if_exists="append", index=False)

print(f"Inserted {len(pop_gdf)} population zones successfully!")