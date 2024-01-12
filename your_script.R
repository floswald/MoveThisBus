#January 12, 2024
#Daman Dhaliwal
#This program evaluates the London Bus Network

#install and load libraries
packages <- c("tidyverse", "httr2", "glue")
for (pkg in packages) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg)
    library(pkg, character.only = TRUE)
  }
}

api_key <- Sys.getenv("TFL_KEY")

#get data from the api
mode <- "bus"
count <- -1
url <- glue::glue("https://api.tfl.gov.uk/Mode/{mode}/Arrivals?count={count}&app_key={api_key}")
req <- request(url)
resp <- req_perform(req)

content <- resp_body_json(resp)

buses <- bind_rows(content)

#unique vehicleIDs/license plates
unique_buses <- buses %>%
  distinct(buses$vehicleId)
no_unique_buses <- nrow(unique_buses)

#calculate the number of routes each bus operates on
no_of_lines = buses %>%
  group_by(vehicleId) %>%
  summarize(num_lines = n_distinct(lineId))

multiple_routes <- no_of_lines %>%
  filter(num_lines > 1)

#join with the original 'buses' data frame to get additional information
routes_with_destinations <- buses %>%
  semi_join(multiple_routes, by = "vehicleId") %>%
  distinct(vehicleId, lineId, destinationName)

num_buses_multiple_routes <- nrow(multiple_routes)

#calculate the number of buses operating on each line
#cannot use just lineId because lineId is shared by outbound and inbound routes
no_of_buses = buses %>%
  group_by(lineId,destinationName) %>%
  summarize(num_buses = n_distinct(vehicleId))

multiple_buses <- no_of_buses %>%
  filter(num_buses > 1)

num_routes_multiple_buses <- nrow(multiple_buses)

#join with the original 'buses' data frame to get additional information
busy_routes_with_destinations <- buses %>%
  semi_join(multiple_buses, by = c('lineId','destinationName')) %>%
  distinct(lineId, destinationName)


#print the no of unique buses
cat("The number of unique buses operating in the London Bus Network right now are:", no_unique_buses, "\n")

#print the no of buses operating on more than 1 route
#print those routes
cat("The number of buses operating on more than one route right now are:", num_buses_multiple_routes, "\n")

#print the routes and destinations for these buses
if (num_buses_multiple_routes > 0) {
  cat("These routes and destinations are:\n")
  print(routes_with_destinations[, c("lineId", "destinationName")])
} else {
  cat("No buses are operating on more than one route right now.\n")
}

#print the no of routes having more than one bus
cat("The number of routes that have more than one bus operating on them right now are:", num_routes_multiple_buses, "\n")

#print these routes and destinations
top_routes <- no_of_buses %>%
  arrange(desc(num_buses))

if (num_routes_multiple_buses > 0) {
  cat("The top 10 routes with the most buses right now are: \n")
  print(head(top_routes, n = 10))
} else {
  cat("No routes have more than one bus operating on them right now")
}

