import pandas as pd
import psycopg2

conn = psycopg2.connect(
    dbname="chicago_transit",
    user="postgres",
    password="postgres",
    host="localhost",
    port="5433"
)
cur = conn.cursor()

print("Connected to database successfully!")

# Load the CSV file
stops_df = pd.read_csv(r"C:\Users\user\Desktop\chicago\stops.txt")

# Look at the first few rows and column names
print(stops_df.columns.tolist())
print(stops_df.head())

# Loop through each row and insert into the database
for index, row in stops_df.iterrows():
    cur.execute("""
        INSERT INTO transit_stops (stop_name, geom)
        VALUES (%s, ST_SetSRID(ST_MakePoint(%s, %s), 4326))
    """, (row['stop_name'], row['stop_lon'], row['stop_lat']))

conn.commit()
print(f"Inserted {len(stops_df)} stops successfully!")
