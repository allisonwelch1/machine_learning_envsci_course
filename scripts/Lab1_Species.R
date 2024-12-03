# This script follows Lab 1 of the Machine Learning in Environmental Science course by Ben Best
# https://bbest.github.io/eds232-ml/lab1a_sdm-explore.html
# 12/2/24

# load packages, install if missing
# first load the librarin package, which then can be used to check other packages

if(!require(librarian)){
  install.packages("librarian")
}
library(librarian)

librarian::shelf(
  dismo, dplyr, DT, ggplot2, here, htmltools, leaflet, mapview, purrr, raster, readr, 
  rgbif, rgdal, rJava, sdmpredictors, sf, spocc, tidyr, devtools
)
select <- dyplyr::select # overwrite raster::select
options(readr.show_col_types = FALSE)
options(mapview.viewer = "pane")  # Render in RStudio Viewer pane

#set random seed for reproducibility
set.seed(502)

# create directory to store data
dir_data <- here("data/sdm")
dir.create(dir_data, showWarnings = F, recursive = T)

# create file paths for GBIF observational data 
obs_csv <- file.path(dir_data, "obs.csv")
obs_geo <- file.path(dir_data, "obs.geojson")

redo <- T #I think this is a way to turn on/off the file creation. See following if statements

if(!file.exists(obs_geo) | redo){
  #get species ocurrence data from GBIF with coordinates
  (res <- spocc::occ(
    query = 'Ursus maritimus',
    from = 'gbif', has_coords = T,
    limit = 10000
  ))
  
  # extract data frame from result
  df <- res$gbif$data[[1]]
  readr::write_csv(df, obs_csv)
  
  # remove latitude values below 60
  for (i in nrow(df):1) { # go backward to avoid indexing issues
    if(df$latitude[i] < 60){
      #remove the observation
      df <- df[-i,]
    }
  }
    
  
  #convert to points of observation from lon/lat columns in data frame
  obs <- df %>% 
    sf::st_as_sf(
      coords = c("longitude", "latitude"),
      crs = st_crs(4326)
    ) %>% 
    select(prov, key) # save space (joinable from obs_csv)
  sf::write_sf(obs, obs_geo, delete_dsn = T)
}


obs <- sf::read_sf(obs_geo)
nrow(obs) # number of rows

#Reproject for polar areas
obs <- sf::st_transform(obs, crs = 3413)

mapview::mapview(obs, map.types =  "CartoDB.Positron")


