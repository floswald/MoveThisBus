

library(tidyverse)
library(httr2)
library(jsonlite)
library(data.table)

#############################################
# Data gathering and preparation

base_url <- "https://api.tfl.gov.uk/Mode"
mode <- "/bus"
type <- "/Arrivals"
counts <- "?count=-1"

param <- list(
  app_key = Sys.getenv("TFL_KEY")
)

urlz <- paste0(base_url, mode, type, counts)

req <- request(urlz) |> 
  req_url_query(!!!param)

resp <- req |> req_timeout(200) |> req_perform()
mode_bus <- resp |> resp_body_json()

write_json(mode_bus, "./mode_bus.json")

bus_temp <- fromJSON("./mode_bus.json")

bus_df<- data.frame(matrix(unlist(bus_temp), 
                                     nrow = length(bus_temp[[1]]), 
                                     byrow = F), stringsAsFactors = T)
colnames(bus_df) <- colnames(bus_temp)
bus_df <- bus_df |> select(1:20)

##############
# analysis of buses and routes

## the `vehicleID` and `linesID` (routeID) pair gives the indication
## that how many `lines` a vehicles is catering.


vehicle_line_counts <- bus_df %>%
  group_by(vehicleId) %>%
  summarise(unique_line_count = n_distinct(lineId))

# except for a few vehicles, most cater to one line only.

## multi_line_vehicles: these vehicles cater more than 1 routes

multi_line_vehicles <- vehicle_line_counts |> 
  filter(unique_line_count>1)

cat("these vehicles cater more than 1 routes:\n")

print(multi_line_vehicles)

## routes which share buses: these routes

sharing_bus_routes <- bus_df |>
  filter(vehicleId %in% multi_line_vehicles$vehicleId) |> 
  select(lineId, direction, destinationName) |> distinct()

cat("routes which share buses: these routes:\n")
print(sharing_bus_routes)



