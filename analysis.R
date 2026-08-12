library(DBI)
library(RPostgres)

con <- dbConnect(
  RPostgres::Postgres(),
  dbname = "chicago_transit",
  host = "localhost",
  port = 5433,
  user = "postgres",
  password = "postgres"
)

print("Connected successfully!")


query <- "
SELECT 
    p.zone_id,
    p.tract_name,
    p.population,
    p.median_income,
    COUNT(DISTINCT t.stop_id) AS nearby_stops,
    COUNT(DISTINCT CASE WHEN poi.poi_type = 'school' THEN poi.poi_id END) AS nearby_schools,
    COUNT(DISTINCT CASE WHEN poi.poi_type = 'hospital' THEN poi.poi_id END) AS nearby_hospitals,
    COUNT(DISTINCT CASE WHEN poi.poi_type IN ('supermarket','grocery') THEN poi.poi_id END) AS nearby_groceries
FROM chicago_zones p
LEFT JOIN transit_stops t ON ST_DWithin(p.geom::geography, t.geom::geography, 500)
LEFT JOIN poi ON ST_DWithin(p.geom::geography, poi.geom::geography, 800)
GROUP BY p.zone_id, p.tract_name, p.population, p.median_income
ORDER BY p.zone_id
"

accessibility_data <- dbGetQuery(con, query)

print(head(accessibility_data))
print(nrow(accessibility_data))


library(DBI)

accessibility_data <- dbGetQuery(con, query)

print(head(accessibility_data))
print(nrow(accessibility_data))

library(DBI)
accessibility_data <- dbGetQuery(con, query)

View(accessibility_data)

cor(accessibility_data$median_income, accessibility_data$nearby_stops, use = "complete.obs")

cor(accessibility_data$median_income, accessibility_data$nearby_groceries, use = "complete.obs")

cor(accessibility_data$median_income, accessibility_data$nearby_schools, use = "complete.obs")

library(DBI)
library(RPostgres)
con <- dbConnect(
  RPostgres::Postgres(),
  dbname = "chicago_transit",
  host = "localhost",
  port = 5433,
  user = "postgres",
  password = "postgres"
)
dbGetQuery(con, "SELECT 1")
query <- "
SELECT 
    p.zone_id,
    p.tract_name,
    p.population,
    p.median_income,
    COUNT(DISTINCT t.stop_id) AS nearby_stops,
    COUNT(DISTINCT CASE WHEN poi.poi_type = 'school' THEN poi.poi_id END) AS nearby_schools,
    COUNT(DISTINCT CASE WHEN poi.poi_type = 'hospital' THEN poi.poi_id END) AS nearby_hospitals,
    COUNT(DISTINCT CASE WHEN poi.poi_type IN ('supermarket','grocery') THEN poi.poi_id END) AS nearby_groceries
FROM chicago_zones p
LEFT JOIN transit_stops t ON ST_DWithin(p.geom::geography, t.geom::geography, 500)
LEFT JOIN poi ON ST_DWithin(p.geom::geography, poi.geom::geography, 800)
GROUP BY p.zone_id, p.tract_name, p.population, p.median_income
ORDER BY p.zone_id
"

accessibility_data <- dbGetQuery(con, query)

exists("accessibility_data")
nrow(accessibility_data)
accessibility_data <- dbGetQuery(con, query)
nrow(accessibility_data)

library(ggplot2)

ggplot(accessibility_data, aes(x = median_income, y = nearby_groceries)) +
  geom_point(alpha = 0.5, color = "darkgreen") +
  geom_smooth(method = "lm", color = "red") +
  labs(
    title = "Median Income vs. Nearby Grocery Access in Chicago",
    x = "Median Household Income ($)",
    y = "Number of Nearby Grocery Stores"
  )
saveRDS(accessibility_data, "accessibility_data.rds")
accessibility_data <- readRDS("accessibility_data.rds")

install.packages("tidyr")

library(dplyr)
library(tidyr)

income_correlations <- data.frame(
  category = c("Transit Stops", "Schools", "Hospitals", "Groceries"),
  correlation = c(
    cor(accessibility_data$median_income, accessibility_data$nearby_stops, use = "complete.obs"),
    cor(accessibility_data$median_income, accessibility_data$nearby_schools, use = "complete.obs"),
    cor(accessibility_data$median_income, accessibility_data$nearby_hospitals, use = "complete.obs"),
    cor(accessibility_data$median_income, accessibility_data$nearby_groceries, use = "complete.obs")
  )
)

print(income_correlations)

accessibility_data <- readRDS("accessibility_data.rds")

income_correlations <- data.frame(
  category = c("Transit Stops", "Schools", "Hospitals", "Groceries"),
  correlation = c(
    cor(accessibility_data$median_income, accessibility_data$nearby_stops, use = "complete.obs"),
    cor(accessibility_data$median_income, accessibility_data$nearby_schools, use = "complete.obs"),
    cor(accessibility_data$median_income, accessibility_data$nearby_hospitals, use = "complete.obs"),
    cor(accessibility_data$median_income, accessibility_data$nearby_groceries, use = "complete.obs")
  )
)

library(ggplot2)

ggplot(income_correlations, aes(x = category, y = correlation, fill = category)) +
  geom_col() +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray40") +
  labs(
    title = "Correlation Between Median Income and Accessibility Metrics",
    x = "",
    y = "Correlation with Median Income"
  ) +
  theme(legend.position = "none")

ggsave("income_accessibility_correlations.png", width = 8, height = 5, dpi = 300)

ggplot(accessibility_data, aes(x = median_income, y = nearby_groceries)) +
  geom_point(alpha = 0.5, color = "darkgreen") +
  geom_smooth(method = "lm", color = "red") +
  labs(
    title = "Median Income vs. Nearby Grocery Access in Chicago",
    x = "Median Household Income ($)",
    y = "Number of Nearby Grocery Stores"
  )

ggsave("income_vs_groceries.png", width = 8, height = 5, dpi = 300)

accessibility_data$total_access_score <- accessibility_data$nearby_stops + 
  accessibility_data$nearby_schools + 
  accessibility_data$nearby_hospitals + 
  accessibility_data$nearby_groceries

summary(accessibility_data$total_access_score)


threshold <- quantile(accessibility_data$total_access_score, 0.25, na.rm = TRUE)
print(threshold)

accessibility_data$underserved <- ifelse(accessibility_data$total_access_score <= threshold, 1, 0)


table(accessibility_data$underserved)

model <- glm(underserved ~ population + median_income, 
             data = accessibility_data, 
             family = "binomial")

summary(model)

accessibility_data$predicted_prob <- predict(model, type = "response")

accessibility_data$predicted_class <- ifelse(accessibility_data$predicted_prob >= 0.5, 1, 0)

table(Actual = accessibility_data$underserved, Predicted = accessibility_data$predicted_class)


model <- glm(underserved ~ population + median_income, 
             data = accessibility_data, 
             family = "binomial",
             na.action = na.exclude)

accessibility_data$predicted_prob <- predict(model, type = "response")
accessibility_data$predicted_class <- ifelse(accessibility_data$predicted_prob >= 0.5, 1, 0)

table(Actual = accessibility_data$underserved, Predicted = accessibility_data$predicted_class)


area_query <- "
SELECT zone_id, ST_Area(geom::geography) AS area_sqm
FROM chicago_zones
"

area_data <- dbGetQuery(con, area_query)
head(area_data)

accessibility_data <- merge(accessibility_data, area_data, by = "zone_id")

accessibility_data$density <- accessibility_data$population / accessibility_data$area_sqm

summary(accessibility_data$density)


model2 <- glm(underserved ~ population + median_income + density, 
              data = accessibility_data, 
              family = "binomial",
              na.action = na.exclude)

summary(model2)

downtown_query <- "
SELECT 
    zone_id,
    ST_Distance(
        geom::geography, 
        ST_SetSRID(ST_MakePoint(-87.6298, 41.8781), 4326)::geography
    ) AS distance_from_downtown
FROM chicago_zones
"

downtown_data <- dbGetQuery(con, downtown_query)
head(downtown_data)

accessibility_data <- merge(accessibility_data, downtown_data, by = "zone_id")

model3 <- glm(underserved ~ population + median_income + density + distance_from_downtown, 
              data = accessibility_data, 
              family = "binomial",
              na.action = na.exclude)

summary(model3)


library(DBI)
library(RPostgres)

con <- dbConnect(
  RPostgres::Postgres(),
  dbname = "chicago_transit",
  host = "localhost",
  port = 5433,
  user = "postgres",
  password = "postgres"
)

accessibility_data <- readRDS("accessibility_data.rds")
nrow(accessibility_data)

accessibility_data$total_access_score <- accessibility_data$nearby_stops + 
  accessibility_data$nearby_schools + 
  accessibility_data$nearby_hospitals + 
  accessibility_data$nearby_groceries

threshold <- quantile(accessibility_data$total_access_score, 0.25, na.rm = TRUE)
accessibility_data$underserved <- ifelse(accessibility_data$total_access_score <= threshold, 1, 0)

table(accessibility_data$underserved)

area_query <- "
SELECT zone_id, ST_Area(geom::geography) AS area_sqm
FROM chicago_zones
"
area_data <- dbGetQuery(con, area_query)

downtown_query <- "
SELECT 
    zone_id,
    ST_Distance(
        geom::geography, 
        ST_SetSRID(ST_MakePoint(-87.6298, 41.8781), 4326)::geography
    ) AS distance_from_downtown
FROM chicago_zones
"
downtown_data <- dbGetQuery(con, downtown_query)

accessibility_data <- merge(accessibility_data, area_data, by = "zone_id")
accessibility_data <- merge(accessibility_data, downtown_data, by = "zone_id")

accessibility_data$density <- accessibility_data$population / accessibility_data$area_sqm

model3 <- glm(underserved ~ population + median_income + density + distance_from_downtown, 
              data = accessibility_data, 
              family = "binomial",
              na.action = na.exclude)

summary(model3)
colnames(accessibility_data)
identical(accessibility_data$distance_from_downtown.x, accessibility_data$distance_from_downtown.y)

accessibility_data$distance_from_downtown <- accessibility_data$distance_from_downtown.x
accessibility_data$distance_from_downtown.x <- NULL
accessibility_data$distance_from_downtown.y <- NULL

colnames(accessibility_data)

model3 <- glm(underserved ~ population + median_income + density + distance_from_downtown, 
              data = accessibility_data, 
              family = "binomial",
              na.action = na.exclude)

summary(model3)

saveRDS(accessibility_data, "accessibility_data.rds")

accessibility_data$predicted_prob3 <- predict(model3, type = "response")
accessibility_data$predicted_class3 <- ifelse(accessibility_data$predicted_prob3 >= 0.5, 1, 0)

table(Actual = accessibility_data$underserved, Predicted = accessibility_data$predicted_class3)

recall <- 82 / (82 + 138)
print(recall)
accessibility_data$predicted_class3_v2 <- ifelse(accessibility_data$predicted_prob3 >= 0.35, 1, 0)

table(Actual = accessibility_data$underserved, Predicted = accessibility_data$predicted_class3_v2)

accessibility_data$predicted_class3_v2 <- ifelse(accessibility_data$predicted_prob3 >= 0.35, 1, 0)
table(Actual = accessibility_data$underserved, Predicted = accessibility_data$predicted_class3_v2)

library(DBI)
library(RPostgres)

con <- dbConnect(
  RPostgres::Postgres(),
  dbname = "chicago_transit",
  host = "localhost",
  port = 5433,
  user = "postgres",
  password = "postgres"
)

accessibility_data <- readRDS("accessibility_data.rds")

model3 <- glm(underserved ~ population + median_income + density + distance_from_downtown, 
              data = accessibility_data, 
              family = "binomial",
              na.action = na.exclude)

accessibility_data$predicted_prob3 <- predict(model3, type = "response")
accessibility_data$predicted_class3_v2 <- ifelse(accessibility_data$predicted_prob3 >= 0.35, 1, 0)

table(Actual = accessibility_data$underserved, Predicted = accessibility_data$predicted_class3_v2)

