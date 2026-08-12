# Chicago Transit & Service Accessibility Analysis

A spatial data analysis project examining accessibility to public transit, schools, hospitals, and grocery stores across Chicago neighborhoods, using a PostGIS spatial database built from real, open government and crowd-sourced data.

## Project Goal

To identify which Chicago neighborhoods are underserved by essential infrastructure, and to understand what factors (income, population, density, location) best explain accessibility gaps across the city.

## Tech Stack

- **Database:** PostgreSQL 18 + PostGIS 3.6.2
- **ETL / Data Loading:** Python (psycopg2, geopandas, osmnx, pygris, SQLAlchemy)
- **Spatial Analysis:** SQL / PostGIS (spatial joins, geography-accurate distance, views)
- **Statistical Analysis & Modeling:** R (DBI, dplyr, ggplot2, logistic regression)

## Data Sources

| Dataset | Source | Records |
|---|---|---|
| Transit stops | CTA GTFS feed | 11,177 |
| Road network | OpenStreetMap (OSMnx) | 77,448 |
| Population & income | US Census TIGER/ACS | 870 tracts (Chicago city limits) |
| Schools, hospitals, groceries | OpenStreetMap | 1,358 |

## Database Design

Four spatial tables (`transit_stops`, `roads`, `population_zones`, `poi`), each with the appropriate PostGIS geometry type and a GiST spatial index. A `chicago_zones` view filters Census tracts down to Chicago city limits only, correcting an early data-scope issue where suburban Cook County tracts were incorrectly included.

## Methodology

1. Built spatial proximity queries using `ST_DWithin` (transit within 500m, POIs within 800m) with `::geography` casting for accurate real-world distance
2. Computed a combined accessibility score per neighborhood across four service categories
3. Ran correlation analysis in R between income and each accessibility dimension
4. Built a logistic regression model predicting "underserved" status from population, income, density, and distance from downtown

## Key Findings

- **Grocery access, not transit or healthcare, shows the clearest income disparity** in Chicago (r = 0.30 vs. near-zero for other categories)
- **Distance from downtown is the strongest predictor** of poor accessibility — stronger than income or population
- A logistic regression model achieved 59% recall in identifying underserved neighborhoods (at a 0.35 classification threshold)
- Basic demographics alone only partially explain accessibility gaps, suggesting historical infrastructure planning plays a larger role

## Files

- `load_stops.py`, `load_roads.py`, `load_population.py`, `load_poi.py` — data loading pipelines
- `queries.sql` — full spatial SQL analysis
- `analysis.R` — R statistical analysis and modeling
- `analysis.Rmd` / `analysis.html` — final report with charts and findings

## Author

Ofobutu Abiodun Emmanuel (Abbeycity) — AI & Geospatial Data Scientist