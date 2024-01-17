################################################################################
#Packages Installation
install.packages("httr")
install.packages("tidyverse")
install.packages("usethis")

library(httr)
library(tidyverse)
library(usethis)

################################################################################

mode <- "tube"
arrivals <- "-1"
readRenviron("~/.Renviron")
TFL_KEY = Sys.getenv("TFL_KEY")

##For gathering all the vehicle licence plates,
##API Calls have been made periodically every 5 minutes for 1 hour

for (i in 1:12){

##API Call
route_get <- GET(paste0("https://api.tfl.gov.uk/Mode/",
                        mode,
                        "/Arrivals?count=",
                        arrivals,
                        "&app_key=",
                        TFL_KEY
                        ))

route_content <- content(route_get)

df_temp <- tibble(V = route_content) %>% 
  unnest_wider(V)

vehicle_ids_temp <- df_temp %>% 
  distinct()

##Adding new data retrieved after each API Calls

if (exists("vehicle_ids")){
  add_on <- filter(vehicle_ids_temp, !vehicleId %in% vehicle_ids$vehicleId) 
  vehicle_ids <- rbind(vehicle_ids,add_on)
} else{
  vehicle_ids = vehicle_ids_temp
}

Sys.sleep(300)
}

df = vehicle_ids

##Investigating Vehicles Operating on Multiple Routes
vehicle_route_1 <- df %>% 
  group_by(vehicleId) %>% 
  distinct(lineId, lineName, vehicleId) %>% 
  arrange(vehicleId) %>% 
  mutate(route_count = n()) %>% 
  ungroup()

#Collapsing Data to countVehicles Operating on Multiple Routes
vehicle_route_2 <- vehicle_route_1 %>% 
  distinct(vehicleId, route_count) %>% 
  group_by(route_count) %>% 
  mutate(total_vehicles_route_count = n()) %>% 
  distinct(route_count, total_vehicles_route_count) %>% 
  arrange(route_count)

#Visualizing via Bar Graph
vehicle_route_2 %>% ggplot(aes(x=route_count, y=total_vehicles_route_count))+
  geom_col(fill="#599ad3") +
  geom_text(data=vehicle_route_2, aes(label=total_vehicles_route_count), vjust = -0.2) +
  ggtitle("Visualization of Buses Operating on Multiple Routes") +
  xlab("Number of Routes") + ylab("Vehicle Count")+
  theme(plot.title = element_text(hjust=0.45, vjust = 1, size = 18),
        axis.text=element_text(size= 14),
        axis.title = element_text(size = 14))
ggsave("Buses_Multiple_Routes.png", width = 11, height = 7)

##Investigating Routes Sharing Multiple Vehicles
vehicle_route_3 <- df %>% 
  group_by(lineId, lineName) %>% 
  distinct(vehicleId) %>% 
  arrange(lineId) %>% 
  mutate(vehicle_count=n()) %>% 
  distinct(lineId, lineName, vehicle_count) %>% 
  ungroup() %>% 
  select(lineName, vehicle_count) %>% 
  arrange(desc(vehicle_count)) %>% 
  rename(Line=lineName, Total_Number_of_Vehicles=vehicle_count)

#Saving into a csv file
write.csv(vehicle_route_3, file = "Routes_Sharing_Vehicles.csv")

################################################################################
  