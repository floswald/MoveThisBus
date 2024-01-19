#__________________________________________________________
#                     Coding Task
#
# Author: Almudena Valle
# Date: 18/01/24
#
#__________________________________________________________

# Loading packages
library(httr2)
library(jsonlite)
library(purrr)
library(dplyr)
library(ggplot2)

# Setting up

# API key in edit_r_environ()
tfl_key <- Sys.getenv("TFL_KEY")

# Set the API URL, parameters, and authorization key
req <- request("https://api.tfl.gov.uk/Mode/bus/Arrivals?count=-1")
req <- req %>% req_headers("Authorization" = paste("Bearer", tfl_key))

# Number of maximum retry attempts. (I am setting it to 10, but 5 has been the maximum I have needed. I think this way is safer than doing a while loop.)
max_attempts <- 10

# 1. List of all license plates of buses working in the London bus network.

for (attempt in 1:max_attempts) {
  cat("Call attempt number: ", attempt, "\n")
  tryCatch({
    resp <- req %>% req_perform()
    if (resp$status == 200) {
      print ("Successful request.")
      break
    }
    # Given that it seems like the error of Timeout is pretty common, the code accommodates for that error.
  }, error = function(e) {
    if (grepl("SSL/TLS connection timeout", conditionMessage(e), ignore.case = TRUE)) {
      cat("Error: Timeout occurred.\n")
    } else {
      cat("Error:", conditionMessage(e), "\n")
    }
  })
  # Random delay (in seconds) between retries (uniform distribution from 1 to 5)
  retry_delay <- runif(1, min = 1, max = 5)
  Sys.sleep(retry_delay)
}
rm(retry_delay)

# Store as large list
vehicle_ids <- resp %>% resp_body_json()

# Extract only license plates
vehicle_ids <- map(vehicle_ids, pluck, "vehicleId")
cat("Total data values: ", length(vehicle_ids), ". \n")

# Keeping only unique values
vehicle_ids <- unique(unlist(vehicle_ids))
vehicle_ids <- as.list(vehicle_ids)
cat("Total unique values: ", length(vehicle_ids), ". \n")

# Print a sample of licence plates from list
cat("Sample of five licence plates from list: ", paste(head(vehicle_ids, 5), collapse = ", "))

# 2. Buses database

buses <- resp %>% resp_body_json()

# Extract buses and the lines they are currently running on, and store as a dataframe
buses <- map_df(buses, ~ tibble(
  vehicleId = .x$vehicleId,
  lineName = .x$lineName # (I am keeping only lineName as lineId seems to have the same values as this column.)
))

# Print the resulting dataframe
print(head(buses, 3))

lines_per_bus <- buses[buses$vehicleId %in% vehicle_ids, ]

# Count distinct lineNames per vehicle_id
lines_per_bus <- lines_per_bus %>%
  group_by(vehicleId) %>%
  summarize(total_lines = n_distinct(lineName))

print(head(lines_per_bus, 3))

# Calculate summary statistics
min_routes <- min(lines_per_bus$total_lines)
max_routes <- max(lines_per_bus$total_lines)
mean_routes <- round(mean(lines_per_bus$total_lines), 3)
buses_with_one_route <- nrow(subset(lines_per_bus, total_lines == 1))
buses_with_two_routes <- nrow(subset(lines_per_bus, total_lines == 2))
total_buses <- nrow(lines_per_bus)  # Calculate total buses

# Create the table, suppressing decimal zeros for integers
table <- data.frame(
  Statistic = c("Minimum Number of Routes", "Maximum Number of Routes", "Mean Number of Routes", "Buses with 1 Route", "Buses with 2 Routes", "Total Number of Buses"),
  Value = c(format(min_routes, nsmall = 0), format(max_routes, nsmall = 0), mean_routes, buses_with_one_route, buses_with_two_routes, total_buses)
)

# Print the table
print(table)
rm(min_routes, max_routes, mean_routes, buses_with_one_route, buses_with_two_routes, total_buses, table)

buses_per_route <- buses %>%
  group_by(lineName) %>%
  summarise(unique_buses = n_distinct(vehicleId)) %>%
  ungroup()

print(head(buses_per_route, 3))

mean_value <- mean(buses_per_route$unique_buses, na.rm = TRUE)

# Create a density plot with mean line
ggplot(buses_per_route, aes(x = unique_buses)) +
  geom_density(fill = "skyblue", alpha = 0.5, color = "white") +
  geom_vline(xintercept = mean_value, color = "red", linetype = "dashed", size = 1) +  # Add mean line
  labs(title = "Density Plot of Unique Buses per Route",
       x = "Unique Buses per route",
       y = "Density") +
  theme_minimal()

Mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}
mode_value <- Mode(buses_per_route$unique_buses)

print("This graph illustrates the distribution of unique buses per route in the database. The red dashed line signifies the mean number of buses for a London bus route, measured at 6.38 buses. The distribution exhibits a leftward skewness with an extended right tail. The modal route features four buses, with a maximum of 20 buses observed on a specific route.")

# Order the data by number of buses
buses_per_route <- buses_per_route[order(buses_per_route$unique_buses, decreasing = TRUE), ]

# Extract the top 5 lines
top5_lines <- head(buses_per_route$lineName, 5)

# Create a bar chart for the top 5 lines
ggplot(buses_per_route, aes(x = reorder(lineName, -unique_buses), y = unique_buses)) +
  geom_bar(stat = "identity", fill = "skyblue") +
  labs(title = "Number of Buses per Line (Top 5 Lines)",
       x = "Line Name",
       y = "Number of Buses") +
  theme_minimal() +
  geom_text(aes(label = unique_buses), vjust = -0.5) +
  scale_x_discrete(limits = top5_lines)

print("In this graph, we can observe the five routes with the highest number of unique buses, with line 38 having the maximum number of buses (20).")

