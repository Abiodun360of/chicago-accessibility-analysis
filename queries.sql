-- Create table for CTA transit stops (point locations)
CREATE TABLE transit_stops (
    stop_id SERIAL PRIMARY KEY,
    stop_name VARCHAR(255),
    route_type VARCHAR(50),
    geom GEOMETRY(Point, 4326)
);

-- Create table for Chicago road network (line segments)
CREATE TABLE roads (
    road_id SERIAL PRIMARY KEY,
    road_name VARCHAR(255),
    road_type VARCHAR(50),
    geom GEOMETRY(LineString, 4326)
);

-- Create table for Census tracts with population/income data
CREATE TABLE population_zones (
    zone_id SERIAL PRIMARY KEY,
    tract_name VARCHAR(255),
    population INTEGER,
    median_income NUMERIC,
    geom GEOMETRY(MultiPolygon, 4326)
);

-- Create table for points of interest (schools, hospitals, groceries)
CREATE TABLE poi (
    poi_id SERIAL PRIMARY KEY,
    poi_name VARCHAR(255),
    poi_type VARCHAR(50),
    geom GEOMETRY(Point, 4326)
);


-- Create spatial indexes for fast proximity/distance queries on all geometry columns
CREATE INDEX idx_transit_stops_geom ON transit_stops USING GIST (geom);
CREATE INDEX idx_roads_geom ON roads USING GIST (geom);
CREATE INDEX idx_population_zones_geom ON population_zones USING GIST (geom);
CREATE INDEX idx_poi_geom ON poi USING GIST (geom);

SELECT COUNT(*) FROM chicago_zones;

-- Chicago's official city boundary was loaded separately via Python (get_chicago_boundary.py)
-- into a table called chicago_boundary, using pygris to pull the boundary from the Census Bureau.

-- Create a view that filters population_zones down to only tracts actually within Chicago city limits
-- (population_zones originally included all of Cook County, which incorrectly included suburbs)
CREATE VIEW chicago_zones AS
SELECT p.*
FROM population_zones p, chicago_boundary c
WHERE ST_Intersects(p.geom, c.geom);




-- ============================================
-- ACCESSIBILITY ANALYSIS QUERIES
-- ============================================

-- Query 1: Count transit stops near each population zone (using approximate degree distance)
-- NOTE: This early version used raw degrees (0.005 ≈ 500m at Chicago's latitude only)
-- and included all of Cook County, not just Chicago. Kept here to show the debugging process.
SELECT 
    p.zone_id,
    p.tract_name,
    p.population,
    COUNT(t.stop_id) AS nearby_stops
FROM population_zones p
LEFT JOIN transit_stops t
    ON ST_DWithin(p.geom, t.geom, 0.005)
GROUP BY p.zone_id, p.tract_name, p.population
ORDER BY nearby_stops DESC
LIMIT 10;

-- Query 2: Same as above, but sorted to find the LEAST accessible zones
-- HAVING filters out zero-population zones (parks, industrial land) so results are meaningful
SELECT 
    p.zone_id,
    p.tract_name,
    p.population,
    COUNT(t.stop_id) AS nearby_stops
FROM population_zones p
LEFT JOIN transit_stops t
    ON ST_DWithin(p.geom, t.geom, 0.005)
GROUP BY p.zone_id, p.tract_name, p.population
HAVING p.population > 500
ORDER BY nearby_stops ASC
LIMIT 10;

-- Query 3: Diagnostic query - find the actual nearest stop to a specific zone,
-- regardless of distance, to verify whether "0 nearby stops" results were real or a bug
SELECT 
    p.zone_id,
    p.tract_name,
    t.stop_name,
    ST_Distance(p.geom, t.geom) AS distance_degrees
FROM chicago_zones p, transit_stops t
WHERE p.zone_id = 1150
ORDER BY distance_degrees ASC
LIMIT 5;

-- Query 4: Corrected version - uses chicago_zones (real Chicago only, not Cook County)
-- and ::geography casting for accurate real-world distance in meters (500m = walkable distance)
SELECT 
    p.zone_id,
    p.tract_name,
    p.population,
    COUNT(t.stop_id) AS nearby_stops
FROM chicago_zones p
LEFT JOIN transit_stops t
    ON ST_DWithin(p.geom::geography, t.geom::geography, 500)
GROUP BY p.zone_id, p.tract_name, p.population
HAVING p.population > 500
ORDER BY nearby_stops ASC
LIMIT 10;

-- Query 5: FINAL combined accessibility query
-- Counts nearby transit stops, schools, hospitals, and groceries per zone in one result
-- Uses COUNT(DISTINCT ...) because joining two tables at once multiplies matching rows
-- Uses CASE WHEN to split poi counts into subcategories within a single query
SELECT 
    p.zone_id,
    p.tract_name,
    p.population,
    COUNT(DISTINCT t.stop_id) AS nearby_stops,
    COUNT(DISTINCT CASE WHEN poi.poi_type = 'school' THEN poi.poi_id END) AS nearby_schools,
    COUNT(DISTINCT CASE WHEN poi.poi_type = 'hospital' THEN poi.poi_id END) AS nearby_hospitals,
    COUNT(DISTINCT CASE WHEN poi.poi_type IN ('supermarket','grocery') THEN poi.poi_id END) AS nearby_groceries
FROM chicago_zones p
LEFT JOIN transit_stops t ON ST_DWithin(p.geom::geography, t.geom::geography, 500)
LEFT JOIN poi ON ST_DWithin(p.geom::geography, poi.geom::geography, 800)
GROUP BY p.zone_id, p.tract_name, p.population
ORDER BY p.zone_id
LIMIT 15;