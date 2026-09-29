library(tidyverse)
library(readxl)

#### Plot & other data  #####

#country data
ICP_countries<-read_delim("ICP_2022_data/d_country.csv", delim = ";")%>%
  dplyr::select(code, code_iso)%>%
  rename(code_country = code, country = code_iso) #country codes for ICP forests

#plot information
gv_plv<-read_delim("ICP ground vegetation data 2025/gv_plv.csv", delim = ";") #updated 2025 data



ICP_plots<-gv_plv%>% #plot information for ICP forests
  dplyr::select(survey_year,code_country,partner_code, code_plot, sample_id, survey_number, total_sample_area)%>%
  left_join(ICP_countries, by = "code_country")%>%
  arrange(country, code_plot, survey_number)%>%
  mutate(level_II_ID = paste(country, code_plot, sep ="_"))%>%
  dplyr::select(level_II_ID, sample_id, survey_year, survey_number, total_sample_area)%>%
  ungroup()

#EUNIS classification update from Liping & Markus
load("ICP_EUNIS_new Haben_combine.Rdata")#file is called final_classification_data
load("ICP_EUNIS_result.Rdata")#file is called final_classification_data

ICP_EUNIS_old<-final_classification_data%>%
  dplyr::select(sample, EUNIS.code, EUNIS.code.name)%>%
  rename(EUNIS_ID = sample)


ICP_EUNIS_extra<-all_eunis_combined%>%
  dplyr::select(sample, EUNIS.code, EUNIS.code.name)%>%
  rename(EUNIS_ID = sample)

ICP_EUNIS<-ICP_EUNIS_old%>%
  bind_rows(ICP_EUNIS_extra)%>%
  mutate(EUNIS.code.name = ifelse(EUNIS.code == "?",NA,EUNIS.code.name))%>%
  mutate(EUNIS.code = ifelse(EUNIS.code == "?",NA,EUNIS.code))%>%
  mutate(EUNIS.code.name = ifelse(EUNIS.code == "+",NA,EUNIS.code.name))%>%
  mutate(EUNIS.code = ifelse(EUNIS.code == "+",NA,EUNIS.code))


EUNIS_codes<-ICP_EUNIS%>%
  distinct(EUNIS.code, EUNIS.code.name)



#species list
d_species_list <-read_csv("ICP ground vegetation data 2025/d_species_list.csv")%>% #updated vegetation data
  select(code, genus, species) %>%
  mutate(species_name = paste(genus, gsub("\\.", "", species))) %>%
  rename(code_species=code)

#altitudes
ICP_altitude.code <-read_delim("ICP ground vegetation data 2025/adds/dictionaries/d_altitude.csv", delim = ";")%>%
  dplyr::select(code,value_max)%>%
  rename(code_altitude=code, altitude=value_max)%>%
  distinct()

#coordinates: convert from DMS format to lat lon and include 
coordinates<- gv_plv%>%
 dplyr:: select(survey_year,code_country, partner_code,code_plot, sample_id, survey_number, latitude,longitude,code_altitude) %>%
  left_join(ICP_altitude.code, by="code_altitude")%>%
  distinct(survey_year,code_country, partner_code,code_plot, sample_id,survey_number,latitude, longitude, altitude)%>%
  left_join(ICP_countries, by = "code_country")%>%
  rename(lat_dms = latitude, lon_dms = longitude)%>%
  mutate(sign_lon = ifelse(lon_dms < 0, "negative","positive"))%>% #needed to maintain negative signs in the longitudes where needed
  mutate(lat_dms = abs(lat_dms)%>% #workaround needed for reformatting into dms and dec
           str_replace('\\d+', function(m) str_pad(m, 6, pad = '0')))%>% #force into six characters
  mutate(lon_dms = abs(lon_dms)%>% #same as above
           str_replace('\\d+', function(m) str_pad(m, 6, pad = '0')))%>%
  
  mutate(lat_dms = gsub("(\\d{2})(\\d{2})(\\d{2})", "\\1_\\2_\\3", lat_dms))%>%
  mutate(lon_dms = gsub("(\\d{2,3})(\\d{2})(\\d{2})", "\\1_\\2_\\3", lon_dms))%>%
  
  mutate(level_II_ID = paste(country, code_plot,sep = "_"))%>%
  mutate(coordinate = paste(lat_dms, lon_dms, sep = ";"))%>%
  group_by(level_II_ID)%>%
  mutate(
    # Find the most frequent coordinate in this plot
    common_coord = names(sort(table(coordinate), decreasing = TRUE))[1],
    # Replace lat_lon if it's different from the common one
    fixed_coordinate = common_coord
  ) %>%
  group_by(level_II_ID)%>%
  mutate(
    # Find the most frequent coordinate in this plot
    common_altitude = names(sort(table(altitude), decreasing = TRUE))[1],
    # Replace lat_lon if it's different from the common one
    altitude = common_altitude
  ) %>%
  ungroup()%>%
  mutate(coord_split = str_split(fixed_coordinate, pattern = ";"))%>%
  rowwise()%>%
  mutate(lat_dms = coord_split[1])%>%
  mutate(lon_dms = coord_split[2])%>%
  rowwise() %>%
  mutate(latitude = {
    parts <- as.numeric(strsplit(lat_dms, "_")[[1]])
    parts[1] + parts[2] / 60 + parts[3] / 3600
  }) %>%
  mutate(longitude = {
    parts <- as.numeric(strsplit(lon_dms, "_")[[1]])
    parts[1] + parts[2] / 60 + parts[3] / 3600
  })%>%
  mutate(longitude = ifelse(sign_lon == "negative",-longitude, longitude))%>% #the signs are converted back correctly here
  dplyr::select(level_II_ID,survey_year, country,code_country,partner_code, code_plot, sample_id, survey_number, latitude, longitude, altitude)%>%
  ungroup()%>%
  distinct(level_II_ID, country,code_country,partner_code,code_plot, latitude, longitude,altitude) #retain the most important coordinates values



####Vegetation data (gv) ####
#load in vetation data
gv_vem<-read_delim("ICP ground vegetation data 2025/gv_vem.csv", delim = ";")

#combine vegetation data with species list and coordinates
ICP.veg<-left_join(gv_vem, d_species_list, by="code_species", relationship = "many-to-many")%>% #double species counted in two instances
  dplyr::select(-code_species, -code_certainty,-partner_code, -other_obs, -q_flag, -change_date, genus, species)%>%
  #left_join(coordinates, by=c("survey_year","code_country", "code_plot","sample_id","survey_number"))%>%
  left_join(coordinates, by = c("code_country","code_plot"))%>%
  dplyr::select(level_II_ID, country,longitude, latitude, everything()) 



#add understory layer information
layer_short_names <- c(
  "Tree layer (only ligneous and all climbers) > 5 m height" = "T",
  "Moss layer (i.e. terricolous bryophytes and lichens)" = "M",
  "Shrub layer (only ligneous and all climbers) > 0.5 m and ≤ 5 m height" = "S",
  "Herb layer (all non-ligneous irrespective of height, and the ligneous only if ≤ 0.5m height), including eventual seedlings and browsed trees" = "H",
  "Lower Shrubs (FR)" = "Sl",
  "Upper Shrubs (FR)" = "Su"
)

#load in the  the layer information
ICP_layer.code <- read_delim("ICP ground vegetation data 2025/adds/dictionaries/d_layer_surface.csv", delim = ";")%>%
  mutate(layer = layer_short_names)%>%
  dplyr::select(code, layer, description)%>%
  rename(code_layer_surface=code)%>%
  mutate(Layer_uniform = c("T","M","S","H","S","S"))

#combine the different plot information laters
ICP_combined<-ICP.veg%>%
  left_join(ICP_layer.code, by = "code_layer_surface")%>%
  # left_join(ICP_plots, by = c("survey_year","code_country","country","code_plot","sample_id","survey_number"), relationship = "many-to-many")%>%
  left_join(ICP_plots, by = c("level_II_ID","survey_year","sample_id","survey_number"), relationship = "many-to-many")%>%
  mutate(species_name = paste(genus, species))


# edit the ICP forest codes in order to have matching definitions: subplots are in sample_id, survey number = temporal survey within that survey year


ICP_combined


#set all undefined survey numbers and or sample_ids to -9999 (instead of -99 or -9999)


#set all sample ids to -9999 for countries that have maximum one defined sample id (either only -9999, or -9999 and one additional number) per plot (for these countries, sample_id is not being used actively)

# "Netherlands"    "Ireland"        "Greece"         "Portugal"       "Spain"          "Luxembourg"     "Sweden"         "Austria"      

# "Finland"        "Romania"        "Poland"         "Czech Republic" "Russia"         "Bulgaria"       "Latvia"         "Cyprus"   

group_1<-ICP_combined %>% 
  mutate(sample_id=ifelse(sample_id %in% c(-99,-9999),-9999,sample_id)) %>% 
  distinct(country)%>%
  filter(country %in% c("NL","IE","GR","PT","ES","LU","SE","FI","RO","PL","CZ","RU","BG","LV","NO","LT"))%>%
  pull(country)


#correct sample id for Estonia for which sample_id was simply set as a combination of survey_number and plot number

#"Estonia"

group_2<-ICP_combined %>% 
  mutate(sample_id=ifelse(sample_id %in% c(-99,-9999),-9999,sample_id)) %>% 
  distinct(country)%>%
  filter(country == "EE")%>%
  pull(country)


#correct survey_number for countries that have used this to define resurvey cycles instead of different surveys within a year

#"Bulgaria"  "Norway"    "Finland"   "Lithuania"

group_3<-ICP_combined %>% 
  mutate(sample_id=ifelse(sample_id %in% c(-99,-9999),-9999,sample_id)) %>% 
  distinct(country)%>%
  filter(country %in% c("BG","NO","FI","LT"))%>%
  pull(country)


#combine everything from the new edited ICP forests code

ICP_edit <- ICP_combined %>% 
  mutate(sample_id_edit=ifelse(sample_id %in% c(-99,-9999),-9999,sample_id)) %>% 
  mutate(sample_id_edit=ifelse(country %in% group_1,-9999,sample_id_edit))%>%
 # mutate(sample_id_edit=ifelse(country %in% group_2,-9999,sample_id_edit))%>% #looks like a correct sample id in hindsight
  mutate(survey_number_edit=ifelse(country %in% group_3,-9999,survey_number))%>%
  mutate(sample_id_edit = ifelse(sample_id_edit == -9999, NA, sample_id_edit))%>% #encode NA into -9999 because it is truly unknown
  mutate(sample_id_edit = ifelse(country == "BE", ifelse(survey_year < 1995,NA,sample_id_edit),sample_id_edit))%>%
  mutate(Spatial_ID = paste( country, code_plot, sample_id_edit, sep = "_"))%>% #originnaly, survey number was here but is not needed
  mutate(Spatial_ID = str_remove(Spatial_ID,"_NA"))%>%#in the case where sample id was NA
  mutate(Spatial_ID = ifelse(is.na(sample_id_edit),NA, Spatial_ID))



ICP_wide<-ICP_edit%>% #not al surveys are repeated, so keep thosew which are
  group_by(Spatial_ID,level_II_ID,country,partner_code, code_plot,sample_id_edit, survey_year)%>%
  summarise(total_cover = sum(species_cover))%>%
  spread(survey_year, value = total_cover)%>%
  rowwise() 

repeated_surveys<-ICP_wide%>%
  mutate(n_surveys = sum(!is.na(c_across(`1988`:last_col()))))%>%
  group_by(level_II_ID)%>%
  summarise(n_surveys = sum(n_surveys, na.rm = TRUE))%>%
  filter(n_surveys > 1) %>%
  pull(level_II_ID)#important: repetitions on plot (level-II) level, not subplot as before 


#this is the prefinal data base, only the checklist of EUNIS need to be done
ICP.veg.prefinal<-ICP_edit%>%
  dplyr::select(Spatial_ID, level_II_ID,country, partner_code,latitude, longitude,code_plot, sample_id, sample_id_edit, survey_number, survey_number_edit, survey_year,species_name, Layer_uniform,description,species_cover, total_sample_area)%>%
  rename(abundance=species_cover, Layer = Layer_uniform)%>%
  mutate(EUNIS_ID = paste(country, code_plot, sample_id, survey_year, sep = "-"))%>% #ID used by Liping to calculate EUNIS classification
  select(level_II_ID,Spatial_ID, EUNIS_ID,country,code_plot, sample_id, latitude, longitude, everything())%>%
  left_join(ICP_EUNIS, by = "EUNIS_ID", relationship = "many-to-many")%>%
  filter(level_II_ID %in% repeated_surveys) #keep only those surveys that are performed more than once



#check the gaps in the EUNIS classification and fill either based on within-plot shared types or the generic "Forests"
EUNIS_fills<-ICP.veg.prefinal%>%
  distinct(Spatial_ID, EUNIS_ID, country, code_plot,EUNIS.code, EUNIS.code.name)%>%
  group_by(country, code_plot) %>%
  arrange(EUNIS_ID, .by_group = TRUE) %>%
  mutate(
    # carry last observed forward within the group
    EUNIS.code.name = zoo::na.locf(EUNIS.code.name, na.rm = FALSE),
    # then carry first observed backward within the group
    EUNIS.code.name = zoo::na.locf(EUNIS.code.name, fromLast = TRUE, na.rm = FALSE)
  )%>% #first fill in the remaining codes based on what is available within plot
  mutate(
    # carry last observed forward within the group
    EUNIS.code = zoo::na.locf(EUNIS.code, na.rm = FALSE),
    # then carry first observed backward within the group
    EUNIS.code = zoo::na.locf(EUNIS.code, fromLast = TRUE, na.rm = FALSE)
  )%>%
    ungroup()%>%
  select(EUNIS_ID,EUNIS.code,EUNIS.code.name)
  




ICP.veg.prefinal2<-ICP.veg.prefinal%>%
  dplyr::select(-EUNIS.code, - EUNIS.code.name)%>%
  left_join(EUNIS_fills, by = "EUNIS_ID", relationship = "many-to-many")%>%
  ungroup()%>%
  distinct()%>%
  arrange(level_II_ID,Spatial_ID, survey_year)%>%
  group_by(level_II_ID,Spatial_ID,survey_year)%>%
  dplyr::select(-survey_number)%>% #the original survey number does not code what I want. I want this to be a consecutive number within each spatial plot ID
  mutate(Database = "ICP_forests")%>%
  mutate(Dataset = paste("ICP_forests_partner",partner_code, sep = "_"))%>%
  dplyr::select(-EUNIS_ID,-sample_id, -code_plot,-description)%>%
  rename(Plot_subplot_ID = Spatial_ID, PlotID = level_II_ID, Plot_size = total_sample_area)%>%
  rename_with(~ paste0(toupper(substr(.x, 1, 1)), substr(.x, 2, nchar(.x))))%>%
  dplyr::select(Database,Dataset, Country, PlotID, Plot_subplot_ID, Plot_size, Latitude, Longitude, Survey_year, Species_name, Layer, Abundance, EUNIS.code, EUNIS.code.name)%>%
  filter(Layer != "M")%>% #Remove the moss layer
  filter(Abundance!= -99)%>%#This is a placeholder for NA
  mutate(EUNIS.code = ifelse(PlotID %in% c("FI_6","FI_10"),NA, EUNIS.code))%>% #these two were duplicated, no way to know which is the correct class. Just make NA instead
  mutate(EUNIS.code.name = ifelse(PlotID %in% c("FI_6","FI_10"), NA, EUNIS.code.name))

subplotIDs<-ICP.veg.prefinal2%>%
  ungroup()%>%
  distinct(PlotID, Plot_subplot_ID, Plot_size)%>%
  group_by(PlotID)%>%
  nest()%>%
  mutate(new_data = map(.x = data, 
                        ~mutate(.x, dummy = paste(PlotID, Plot_size, sep = "_"))%>%
                          mutate(new_subplot = if_else(is.na(.x$Plot_subplot_ID),
                                                       if_else(nrow(.x)>1,1,NA),2) )
                        
  ))%>%
  select(new_data)%>%
  unnest(cols = c(new_data))%>%
  ungroup()%>%
  mutate(new_Plot_subplot_ID = ifelse(new_subplot == 1, dummy, ifelse(new_subplot == 2, Plot_subplot_ID, NA)))%>%
  select(-dummy, -new_subplot)


ICP_veg_final<-ICP.veg.prefinal2%>%
   left_join(subplotIDs, by = c("PlotID", "Plot_subplot_ID", "Plot_size"))%>%
   ungroup()%>%
  # mutate(Plot_subplot_ID = new_Plot_subplot_ID)%>%
  # select(-new_Plot_subplot_ID)%>%
  # distinct()%>%
  group_by(PlotID, Plot_subplot_ID,new_Plot_subplot_ID,Plot_size,Survey_year)%>%
  arrange(PlotID, Plot_subplot_ID,new_Plot_subplot_ID, Plot_size,Survey_year)%>%
  nest()%>%
  group_by(PlotID, Plot_subplot_ID,Plot_size)%>%
  mutate(Survey_number = row_number())%>%#correct consecutive surveys now
  unnest(data)%>%
  select(Database, Dataset, Country, PlotID, Plot_subplot_ID,Plot_size, Latitude, Longitude, Survey_number, Survey_year, Species_name, Layer, Abundance, EUNIS.code, EUNIS.code.name)

#some final checks
ICP_veg_final%>%
  ungroup()%>%
  distinct(PlotID,Plot_subplot_ID, Plot_size) #2742 plots and subplots

ICP_veg_final%>%
  distinct(PlotID,Plot_subplot_ID,Plot_size) #2827 plots

ICP_veg_final%>%
  distinct(PlotID,Plot_subplot_ID,Plot_size, Survey_number, Survey_year) #2827 plots
  
wronglist<-subplotIDs%>% #85 plots with missing or variable plot sizes. This messes up the encoding, but at least it adds yp
  group_by(PlotID, new_Plot_subplot_ID)%>% #2827 - 2742 = 85
  nest()%>%
  rowwise()%>%
  mutate(rowcount = nrow(data))%>%
  filter(rowcount > 1)




#write out the data product
write_csv(ICP_veg_final,"ICP_veg_final.csv") #2742 Plot, subplot combinations. 2827 if changeable plot size over time is accounted for

