import streamlit as st
import psycopg2
import pandas as pd
import folium
from streamlit_folium import st_folium

st.title("Chicago Accessibility Dashboard")
st.write("Exploring transit, school, hospital, and grocery access across Chicago neighborhoods.")

conn = psycopg2.connect(
    dbname="chicago_transit",
    user="postgres",
    password="postgres",
    host="localhost",
    port="5433"
)

query = """
SELECT zone_id, tract_name, population, median_income,
       ST_X(ST_Centroid(geom)) AS lon, ST_Y(ST_Centroid(geom)) AS lat
FROM chicago_zones
LIMIT 50
"""
data = pd.read_sql(query, conn)

st.write(f"Showing {len(data)} Chicago neighborhoods")
st.dataframe(data)
st.subheader("Neighborhood Map")

m = folium.Map(location=[41.8781, -87.6298], zoom_start=11)

for _, row in data.iterrows():
    folium.CircleMarker(
        location=[row['lat'], row['lon']],
        radius=5,
        popup=f"{row['tract_name']}: {row['population']} people",
        color="blue",
        fill=True
    ).add_to(m)

st_folium(m, width=700, height=500)