# May 2015
# Code to Generate fies .Soil Necessary to Run DSSAT in Latin America (resolution 0.5 degrees)
# Data from The latest version (1.1) of WISE Soil Database for Crop Simulation Models data and maps can be downloaded at:
# https://hc.box.net/shared/0404zn08js (Password: bHddsc)
# Developer layer Soil Jawoo Koo j.koo@cgiar.org
# Developer code R Jeison Mesa j.mesa@cgiar.org; jeison.mesa@correounivalle.edu.co 

##########################################################################################
########### write the soil file (SOIL.SOL); make_soilfile function #######################
##########################################################################################


# Load Libraries Neccesary 
library(raster)
library(ncdf)

source("/home/jeisonmesa/Proyectos/BID/bid-cc-agricultural-sector/_scripts/mainFunctions.R") ## File Functios Necessary

path <- "/home/jeisonmesa/Proyectos/BID/bid-cc-agricultural-sector/"  ## Project Directory

# Prepare Data
id_soil <- raster(paste0(path, "02-Soil-data/","cell5m.asc"))         ##   Soil Type Identifier
proj4string(id_soil) <- CRS("+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0")  ## Add to the Coordinate System


Soil_profile <- read.table(paste0(path, "02-Soil-data/", "data_hc3ksol_5m_global.txt"), header = T)   ## Soil Profile for Cell5m (Para utilizar en el QUERY)
wise <- readLines(paste0(path, "02-Soil-data/", "WI.SOL"))      ## Soil File Wise
Soil_Generic <- readLines(paste0(path, "02-Soil-data/", "HC.SOL"))   ## Soil File Generic



## Soils Code Data Wise

##CodigoSueloWise=TiposSoilinWise(wise,getwd())
code_soil_wise <- Type_soil_wise(wise, getwd())

#head(code_soil_wise)

#CodigoSueloGeneric=TiposSoilinWise(Soil_Generic,getwd()) ## Suelos Genericos
code_soil_generic <- Type_soil_wise(Soil_Generic, getwd())

## Header Position Wise

Position_CodigoSueloWise <- which(code_soil_wise != "NA")
Position_CodigoSueloWise <- c(1,(Position_CodigoSueloWise[2:length(Position_CodigoSueloWise)] + 1))
Position_CodigoSueloWise <- Position_CodigoSueloWise[1:(length(Position_CodigoSueloWise) - 3)]
wise[Position_CodigoSueloWise]     ## Header checking the Wise


## Header Position Generic

Position_CodigoSueloGeneric<-which(code_soil_generic != "NA")
Position_CodigoSueloGeneric<-c(1,(Position_CodigoSueloGeneric[2:length(Position_CodigoSueloGeneric)] + 1))
Position_CodigoSueloGeneric<-Position_CodigoSueloGeneric[1:(length(Position_CodigoSueloGeneric) - 2)]
Soil_Generic[Position_CodigoSueloGeneric]  ## Header checking the Generic



## Get reference codes Wise
#Cod_Ref<-sapply(1:length(Position_CodigoSueloWise),function(i) SustraerTipoSuelo(wise[Position_CodigoSueloWise[i]]))
Cod_Ref <- sapply(1:length(Position_CodigoSueloWise), function(i) extract_tipe_soil(wise[Position_CodigoSueloWise[i]]))

Cod_Ref_Generic <- sapply(1:length(Position_CodigoSueloGeneric), function(i) extract_tipe_soil(Soil_Generic[Position_CodigoSueloGeneric[i]]))


## Data frame containing the code for wise and position that this is in the file Wise Soil contains the position in the file WISE

Cod_Ref_and_Position <- data.frame(Cod_Ref, Position_CodigoSueloWise)
#wise[59933]
Cod_Ref_and_Position_Generic <- data.frame(Cod_Ref_Generic, Position_CodigoSueloGeneric)
#Soil_Generic[473]


## Add to 0.5 degrees spatial resolution
prec <- raster(paste0(path, "02-Soil-data/", "prec_1971_01.nc")) ## Archive for cutting soil types in Latin America (In this case added to the climate archives)
crop_Latin <- crop(id_soil,prec, snap = 'in' )  ## Court for Latin America
crop_Latin <- resample(crop_Latin, prec,method = "ngb" )  ## Resample Resolution climatic Files
crop_Latin <- mask(crop_Latin, prec)                   ## Mask for Latin America
##plot(crop_Latin)



Data_Soil_Latin_America <- writeRaster(crop_Latin, filename = 'test', overwrite = T)    
rm(crop_Latin)

Position_Soil_<- which(Data_Soil_Latin_America[] != "NA")            ## Position where values are
#valores <- Data_Soil_Latin_America[][Position_Soil_]                ## Values
values <- Data_Soil_Latin_America[][Position_Soil_]  


## Make Soil files .SOIL 
#prepare in_data
in_data <- list()
in_data$general <- data.frame(SITE=-99,COUNTRY="Generic",LAT=-99,LON=-99,SCSFAM="Generic") # Location

make_soilfile <- function(in_data, data, path) {
  
  ## Construction header
  y <- data
  y <- y[5]
  write(y,file="x.txt")
  y<-read.table("x.txt",sep="")
  in_data$properties <- data.frame(SCOM=paste(y[1,1]),SALB=y[1,2],SLU1=y[1,3],SLDR=y[1,4],SLRO=y[1,5],SLNF=y[1,6],SLPF=1,SMHB=y[1,8],SMPX=y[1,9],SMKE=y[1,10])
  
  sink("SOIL.SOL")  
  cat("*SOILS: General DSSAT Soil Input File\n")
  cat("\n")
  cat("*BID0000001  WISE        SCL     140 GENERIC SOIL PROFILE\n")
  cat("@SITE        COUNTRY          LAT     LONG SCS Family\n")
  
  #general
  cat(paste(" ",sprintf("%1$-12s%2$-12s%3$8.3f%4$9.3f",
                        as.character(in_data$general$SITE),as.character(in_data$general$COUNTRY),
                        in_data$general$LAT, in_data$general$LON)," ",
            sprintf("%-12s",as.character(in_data$general$SCSFAM)),
            "\n",sep=""))
  
  
  #properties 
  cat("@ SCOM  SALB  SLU1  SLDR  SLRO  SLNF  SLPF  SMHB  SMPX  SMKE\n")
  cat(paste(sprintf("%1$6s%2$6.2f%3$6.1f%4$6.2f%5$6.2f%6$6.2f%7$6.2f%8$6s%9$6s%10$6s",
                    as.character(in_data$properties$SCOM),in_data$properties$SALB,
                    in_data$properties$SLU1, in_data$properties$SLDR, in_data$properties$SLRO,
                    in_data$properties$SLNF, in_data$properties$SLPF, in_data$properties$SMHB,
                    in_data$properties$SMPX, in_data$properties$SMKE),"\n",sep=""))
  cat(paste(read_oneSoilFile(data[6:length(data)], path)), sep = "\n")
  sink()
  
}

## test 
## make_soilfile(in_data, wise[59933:length(wise)], getwd())

## Extracting Archive Soil



Extraer.SoilDSSAT <- function(Codigo_identificadorSoil,path) {
  
  position <- Codigo_identificadorSoil + 1   ## Where it coincides with the raster ID
  
  posicion <- which(Soil_profile[, 1] == position)
  
  
 
    if(length(posicion) == 0){
      Wise_Position<-Cod_Ref_and_Position_Generic[11,2]
      return(make_soilfile(in_data,Soil_Generic[Wise_Position:length(wise)], path))
    
    }
  
   else {
    
      celdas_id_Wise <- Soil_profile[posicion, ]                                               ## Cells and percentage of soil File DSSAT 
      Posicion_Pct <- which(celdas_id_Wise[, "SharePct"] == max(celdas_id_Wise[, "SharePct"]))   ## The cell is chosen with the highest percentage
      Ref_for_Soil <- celdas_id_Wise[Posicion_Pct,2]
      Ref_for_Soil <- celdas_id_Wise[Posicion_Pct,2][1]
      condicion <- which(Cod_Ref_and_Position[, 1] == paste(Ref_for_Soil))
    
    
      if(length(condicion) >= 1){
         Wise_Position <- Cod_Ref_and_Position[which(Cod_Ref_and_Position[, 1] == paste(Ref_for_Soil)), ]
         return(make_soilfile(in_data, wise[Wise_Position[, 2]:length(wise)], path))
     
      }
      
      if(length(condicion) == 0){
        Wise_Position <- Cod_Ref_and_Position_Generic[which(Cod_Ref_and_Position_Generic[, 1] == paste(Ref_for_Soil)), 2]
        return(make_soilfile(in_data,Soil_Generic[Wise_Position:length(wise)], path))
        
      }
    
    
  }
  
}


## test
## the object values matches in the order of the coordinates for climate data for Latin America
##Extraer.SoilDSSAT(values[972],getwd())

save.image(file = paste0(path, "14-ObjectsR/Soil.RData")) ## Save the file Soil

