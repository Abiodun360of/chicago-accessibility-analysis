from pygris import places
import geopandas as gpd

# Pull all "places" (incorporated cities/towns) in Illinois, then filter to Chicago
il_places = places(state="IL", cb=True, year=2022)
chicago_boundary = il_places[il_places['NAME'] == 'Chicago']

print(chicago_boundary[['NAME', 'geometry']])
print("Found:", len(chicago_boundary), "matching boundary")

from sqlalchemy import create_engine

chicago_boundary = chicago_boundary.rename_geometry('geom')
chicago_boundary = chicago_boundary.set_crs("EPSG:4326", allow_override=True)

engine = create_engine("postgresql://postgres:postgres@localhost:5433/chicago_transit")
chicago_boundary[['NAME', 'geom']].to_postgis("chicago_boundary", engine, if_exists="replace", index=False)

print("Chicago boundary loaded into PostGIS!")