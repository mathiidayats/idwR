library(tidyverse)
library(gstat)
library(sp)
library(raster)

# Set seed 
set.seed(123)

# dummy coordinates
n <- 100 #
x <- runif(n, min = 106, max = 109)  # Longitude
y <- runif(n, min = -7.5, max = -5.5) # Latitude
dates <- seq(as.Date("2024-01-01"), as.Date("2024-12-31"), by = "day")

# example structure : data frame 
data <- expand.grid(x = x, y = y, Date = dates) %>%
  mutate(Pr = runif(nrow(.), min = 0, max = 50)) # 

# extend and spatial resolution
grid <- expand.grid(x = seq(106.1, 109, .05), y = seq(-8, -5.8,.05)) # spatial res = 0.05
coordinates(grid) <- c("x", "y")
gridded(grid) <- TRUE
# iwdR
interpolasi <- data %>%
  arrange(Date) %>%
  group_by(Date) %>%
  group_map(~ {
    daily_data <- .x
    daily_data <- daily_data %>% filter(!is.na(Pr))
    # convert daily_data to SpatialPointsDataFrame
    coordinates(daily_data) <- c("x", "y")
    # IDW Interpolation with two paramters of (idp =2, nmax=10)
    idw_result <- idw(formula = Pr ~ 1,
                      locations = daily_data,
                      newdata = grid,
                      nmax = 10,  
                      idp = 2)
    # convert IDW results to data.frame()
    as.data.frame(idw_result) %>%
      mutate(Date = unique(.y$Date))
  }, .keep = TRUE) %>%
  bind_rows() %>%
  dplyr::select(c(x, y, Date, var1.pred))
#LONG TO WIDE FORMAT
interpolasi_mod <- interpolasi%>%
  pivot_wider(names_from = Date,
              values_from =  "var1.pred")
# TO RASTER
library(terra)
idwR <- rast(interpolasi_mod)
#SAVE RASTER
library(stars)
x <- st_as_stars(idwR)
write_stars(x, "daily_IDW.tif")
