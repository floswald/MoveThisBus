# TASK 1 
# TONG LI JAN 11 2023

# LOADING ENVIRONMENT 
library(httr2)
library(dplyr)

# base url for mode
req_c <-request("https://api.tfl.gov.uk/Mode/bus/Arrivals")

#load key
TFL_KEY <- Sys.getenv("TFL_KEY")

#count -1
param <- list(
  count = -1,
  app_key = TFL_KEY)

## obtaining vehicle id and line id from mode: ####
resp_c<- req_c %>%
  req_url_query(!!!param) %>%
  req_throttle(rate = 500 / 60) %>%
  req_retry(backoff = ~ 10) %>%
  req_perform()

resp_c
# the exact time where we make the call: 
c_respJSON[[1]][["timestamp"]]

# first obtain a df of bus and line
c_respJSON <- resp_c %>% resp_body_json()

## finding whether the same bus (vehicle id) operates on the same route (line id) ----

# n of results from the last response: 
length(c_respJSON)
c_respJSON

names(c_respJSON[[1]])
header <- c( "id", "operationType", "vehicleId", "naptanId", 
             "stationName", "lineId", "lineName", "platformName", 
             "direction", "bearing", "destinationNaptanId", 
             "destinationName", "timestamp", "currentLocation", 
             "towards", "expectedArrival", "timeToLive")

names(c_respJSON[[1]])
#current line, license plates, drawing from mode
#https://api-portal.tfl.gov.uk/api-details#api=Mode&operation=Mode_Arrivals

length(c_respJSON)
buses <- data.frame(setNames(replicate(length(header), 
                                       character(length(c_respJSON)), 
                                       simplify = FALSE), header),
                    stringsAsFactors = FALSE)

# obtain the current bus-line running information as a df
for (i in 1:length(c_respJSON)) {
  for (j in header) {
    buses[i, j] <- c_respJSON[[i]][[j]]
  }
}

# write.csv(buses, "~/Desktop/buses.csv", row.names = FALSE)
####Sharing Bus: a translation of stata code----
# It takes me forever to filter the data in R so I did it in Stata and asked chat to translate it in R: 
# egen combinations = tag(vehicleid lineid)
# // drop the duplicated samples
# keep if combinations ==1
# // if one car matches iwth 1 line
# bysort vehicleid: egen treat = total(combinations)
# // drop if no switches in line
# drop if treat==1
# sort lineid
# br lineid vehicleid  direction stationname bearing

df <- buses %>%
  mutate(combinations = paste(vehicleId, lineId, sep = "_"))

df <- df %>% filter(!duplicated(df$combinations))

df <- df %>%
  group_by(vehicleId) %>%
  mutate(treat = n_distinct(combinations))

# here we have the lines that share buses
sharing_bus <- df %>% filter(treat != 1)

# Sort the df by lineid
sharing_bus <- sharing_bus %>% arrange(lineId)

# a table to show the frequency and buses being shared
sharing_bus_table <- table(sharing_bus$lineId, sharing_bus$vehicleId)
sharing_bus_table

nrow(sharing_bus_table) # lines that are sharing buses
rownames(sharing_bus_table) # line names

data.frame(freq = rowSums(sharing_bus_table)) %>%
  arrange(desc(freq))

####a barplot to represent lines that share buses----
barplot(rowSums(sharing_bus_table), names.arg = rownames(sharing_bus_table), col = "blue", 
        main = "Line sharing buses", xlab = "Line Names", ylab = "Number of Buses")

#### if we could also join all arrivals from vehicle sides----
# req_vehicle<-request("https://api.tfl.gov.uk/Vehicle")

# retry tp manually to avoid hhtp 429 (5862 bus, 12 tries)

# bus_id <- unique(buses$vehicleId)
# length(bus_id)

# Gets the predictions for a given list of vehicle Id's.
# for (i in bus_id) {
#   v_resp <- req_vehicle %>%
#     req_url_path_append(i) %>%
#     req_url_path_append("Arrivals") %>%
#     req_url_query(app_key = TFL_KEY) %>%
#     req_throttle(rate = 500 / 60) %>%
#     req_retry(backoff = ~10, max_tries = 12) %>%
#     req_perform()
# }

# v_respJSON <- v_resp %>% resp_body_json()# TASK 1 
# TONG LI JAN 11 2023

# LOADING ENVIRONMENT 
library(httr2)
library(dplyr)

# base url for mode
req_c <-request("https://api.tfl.gov.uk/Mode/bus/Arrivals")

#load key
TFL_KEY <- Sys.getenv("TFL_KEY")

#count -1
param <- list(
  count = -1,
  app_key = TFL_KEY)

## obtaining vehicle id and line id from mode: ####
resp_c<- req_c %>%
  req_url_query(!!!param) %>%
  req_throttle(rate = 500 / 60) %>%
  req_retry(backoff = ~ 10) %>%
  req_perform()

resp_c
# the exact time where we make the call: 
c_respJSON[[1]][["timestamp"]]

# first obtain a df of bus and line
c_respJSON <- resp_c %>% resp_body_json()

## finding whether the same bus (vehicle id) operates on the same route (line id) ----

# n of results from the last response: 
length(c_respJSON)
c_respJSON

names(c_respJSON[[1]])
header <- c( "id", "operationType", "vehicleId", "naptanId", 
             "stationName", "lineId", "lineName", "platformName", 
             "direction", "bearing", "destinationNaptanId", 
             "destinationName", "timestamp", "currentLocation", 
             "towards", "expectedArrival", "timeToLive")

names(c_respJSON[[1]])
#current line, license plates, drawing from mode
#https://api-portal.tfl.gov.uk/api-details#api=Mode&operation=Mode_Arrivals

length(c_respJSON)
buses <- data.frame(setNames(replicate(length(header), 
                                       character(length(c_respJSON)), 
                                       simplify = FALSE), header),
                    stringsAsFactors = FALSE)

# obtain the current bus-line running information as a df
for (i in 1:length(c_respJSON)) {
  for (j in header) {
    buses[i, j] <- c_respJSON[[i]][[j]]
  }
}

# write.csv(buses, "~/Desktop/buses.csv", row.names = FALSE)
####Sharing Bus: a translation of stata code----
# It takes me forever to filter the data in R so I did it in Stata and asked chat to translate it in R: 
# egen combinations = tag(vehicleid lineid)
# // drop the duplicated samples
# keep if combinations ==1
# // if one car matches iwth 1 line
# bysort vehicleid: egen treat = total(combinations)
# // drop if no switches in line
# drop if treat==1
# sort lineid
# br lineid vehicleid  direction stationname bearing

df <- buses %>%
  mutate(combinations = paste(vehicleId, lineId, sep = "_"))

df <- df %>% filter(!duplicated(df$combinations))

df <- df %>%
  group_by(vehicleId) %>%
  mutate(treat = n_distinct(combinations))

# here we have the lines that share buses
sharing_bus <- df %>% filter(treat != 1)

# Sort the df by lineid
sharing_bus <- sharing_bus %>% arrange(lineId)

# a table to show the frequency and buses being shared
sharing_bus_table <- table(sharing_bus$lineId, sharing_bus$vehicleId)
sharing_bus_table

nrow(sharing_bus_table) # lines that are sharing buses
rownames(sharing_bus_table) # line names

data.frame(freq = rowSums(sharing_bus_table)) %>%
  arrange(desc(freq))

####a barplot to represent lines that share buses----
barplot(rowSums(sharing_bus_table), names.arg = rownames(sharing_bus_table), col = "blue", 
        main = "Line sharing buses", xlab = "Line Names", ylab = "Number of Buses")

#### if we could also join all arrivals from vehicle sides----
# req_vehicle<-request("https://api.tfl.gov.uk/Vehicle")

# retry tp manually to avoid hhtp 429 (5862 bus, 12 tries)

# bus_id <- unique(buses$vehicleId)
# length(bus_id)

# Gets the predictions for a given list of vehicle Id's.
# for (i in bus_id) {
#   v_resp <- req_vehicle %>%
#     req_url_path_append(i) %>%
#     req_url_path_append("Arrivals") %>%
#     req_url_query(app_key = TFL_KEY) %>%
#     req_throttle(rate = 500 / 60) %>%
#     req_retry(backoff = ~10, max_tries = 12) %>%
#     req_perform()
# }

# v_respJSON <- v_resp %>% resp_body_json()