import osmnx as ox

# Download the road network for Chicago
G = ox.graph_from_place("Chicago, Illinois, USA", network_type="drive")

print("Number of nodes (intersections):", len(G.nodes))
print("Number of edges (road segments):", len(G.edges))

# Convert the graph edges (road segments) into a GeoDataFrame
edges = ox.graph_to_gdfs(G, nodes=False, edges=True)

print(edges.columns.tolist())
print(edges.head())
print("Number of rows:", len(edges))

import geopandas as gpd
from sqlalchemy import create_engine

# Reset the index so u, v, key become normal columns instead of a multi-index
edges = edges.reset_index()

# Keep only the columns we need, and rename them to match our table
roads_gdf = edges[['name', 'highway', 'geometry']].copy()
roads_gdf = roads_gdf.rename(columns={'name': 'road_name', 'highway': 'road_type'})

# Some road_name/road_type values are lists (e.g. a road with two names) — convert to text
roads_gdf['road_name'] = roads_gdf['road_name'].astype(str)
roads_gdf['road_type'] = roads_gdf['road_type'].astype(str)

# Rename the geometry column so it matches our table's 'geom' column
roads_gdf = roads_gdf.rename_geometry('geom')

# Set the coordinate reference system explicitly to WGS84 (lat/long) to match our table
roads_gdf = roads_gdf.set_crs("EPSG:4326", allow_override=True)

# Create a SQLAlchemy engine (a connection manager) for geopandas to use
engine = create_engine("postgresql://postgres:postgres@localhost:5433/chicago_transit")

# Write to PostGIS, appending to our existing empty 'roads' table
roads_gdf.to_postgis("roads", engine, if_exists="append", index=False)

print(f"Inserted {len(roads_gdf)} road segments successfully!")