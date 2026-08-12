import osmnx as ox

tags = {
    'amenity': ['school', 'hospital'],
    'shop': ['supermarket', 'grocery']
}

poi_gdf = ox.features_from_place("Chicago, Illinois, USA", tags)

print(poi_gdf.columns.tolist())
print("Number of POIs found:", len(poi_gdf))
print(poi_gdf.geometry.geom_type.value_counts())

# Convert all geometries to points using centroid for polygons/multipolygons
poi_gdf = poi_gdf.reset_index()

# Create a point geometry: if it's already a point, keep it; otherwise use the centroid
poi_gdf['geom'] = poi_gdf.geometry.apply(
    lambda geom: geom if geom.geom_type == 'Point' else geom.centroid
)

# Determine poi_type: use 'amenity' if present, otherwise 'shop'
poi_gdf['poi_type'] = poi_gdf['amenity'].fillna(poi_gdf['shop'])

# Keep only the columns we need
poi_final = poi_gdf[['name', 'poi_type', 'geom']].copy()
poi_final = poi_final.rename(columns={'name': 'poi_name'})

# Set as the active geometry column
import geopandas as gpd
poi_final = gpd.GeoDataFrame(poi_final, geometry='geom')
poi_final = poi_final.set_crs("EPSG:4326", allow_override=True)

print(poi_final.head())
print("Final POI count:", len(poi_final))
print(poi_final['poi_type'].value_counts())

from sqlalchemy import create_engine

engine = create_engine("postgresql://postgres:postgres@localhost:5433/chicago_transit")
poi_final.to_postgis("poi", engine, if_exists="append", index=False)

print(f"Inserted {len(poi_final)} POIs successfully!")