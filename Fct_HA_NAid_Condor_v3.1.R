# Function to detect off-wrist in database (LKPilz, 2020-2021)
# IMPORTANT: coded considering resolution of 1 min, file from Condor
#            please note that this algorithm was run with the raw actimetry dataset in our paper

# V3.0: updates (05-06/12/2020 filter 1 and 2)
# V3.1: updates filter 1 - 230 instead of 225 



### Cleaning (detecting offwrist) Condor actigraphy data based on:

### 1) Temperature difference between consecutive measures is smaller than 0.15 in at least 59 min out of 60 around that point (centered)
###    C1 = 1 assigned to an interval of 45 min before + 30 min after
### 2) Activity (== 0) - 90 zeros in 90 min around that point (centered)
###    C2 = 1 assigned to an interval of 60 min before + 45 min after 
### 3) C1 + C2 = NAid
### 4) Filter 1: if epoch belongs to  interval with at least 230 zeros in 240 min AND at least 75 zeros in 90 min = NAid
###              (regardless of temperature)
### 5) Filter 2: lower bar around long chunks of missing - 2 hours before/after NAid chunks longer than 4h:
###              if there are at least 220 zeros in 240 min around that point (centered) AND at least 81 zeros in 90 min around that point (centered) = NAid
###             (regardless of temperature)
### 5) Filter 3: for whole day exclusions - if mean activity of that day < 100 = NAid
### 6) Filter 4: for data in between missing chunks
###              Type 1: if interval in between chunks is < 10min = Naid
###              Type 2: if interval in between is < 10min OR 
###                      if interval in between is < 4h AND NA chunks before/after > 1h OR 
###                      if interval in between is < 20% of sum of before and after NA chunks



### Output: 

### NAid column (numeric vector) added to dataset (in which 1 = off-wrist, 0 = on-wrist)


### Arguments:

### 1) data: condor file imported as dataframe (do not change headers name; function uses: PIM and TEMPERATURE)
### 2) filterBet = filter 4 on?                       *DEFAULT == F 
### 3) filterAround = filter 2 on?                    *DEFAULT == F
### 4) filterBetType = filter 4 type (see above)      *DEFAULT == 1

### note: filters 2 and 4 are the ones of highest complexity


# Dependencies (packages needed):

library(RcppRoll)
library(dplyr)


# Function:

idNA <- function(data, filterBet = F, filterAround = F, filterBetType = 1) {
  
  #remove empty rows 
  data <- data[rowSums(is.na(data)) != ncol(data),]
  
  # 1) Condition 1 ----
  
  # compute diff between consecutive values
  data <- data %>%
    mutate(TempDiff = TEMPERATURE - lag(TEMPERATURE))  
  
  data$TempDiffBin <-ifelse(abs(data$TempDiff) < .15, 1,0)
  
  # use roll_sum to get T of little variation for long durations
  
  data <- data %>%
    mutate(Temp_roll_sum = roll_sum(TempDiffBin, 60, align = "center", fill = NA))
  hist(data$Temp_roll_sum, breaks = 60)
  
  data$Temp_roll_sum <- ifelse(is.na(data$Temp_roll_sum), 0, data$Temp_roll_sum)
  
  data$C1 <- rep(NA, nrow(data))
  
  for (i in 46:nrow(data)) {
    if (data$Temp_roll_sum[i] > 58)  {
      data$C1[(i-45):(i+29)]  <- paste0(rep(1, 75)) # goes earlier (45min bef to increase sensitivity and make sure 'temperature decay' does not interfere)
    } else {}}
  
  ## make C1 var
  data$C1[is.na(data$C1)] <- 0
  data$C1 <- as.numeric(data$C1)
  
  
  # 2) Condition 2 ----
  
  # make variable PIMzero: if PIM == 0 , PIMzero == 1
  data$PIMzero <- ifelse(data$PIM == 0,1,0)
  
  data <- data %>%
    mutate(roll_sum = roll_sum(PIMzero, 90, align = "center", fill = NA))
  
  data$C2 <- rep(NA, nrow(data))
  data$roll_sum_NAzero <- ifelse(is.na(data$roll_sum), 0, data$roll_sum)
  
  # ---- 90 zeros in 90 min = C2 positive
  for (i in 61:nrow(data)) {
    if (data$roll_sum_NAzero[i] > 89)  {
      data$C2[(i-60):(i+44)]  <- paste0(rep(1, 105)) 
    } else {}}
  
  ## make C2 var
  data$C2 <- as.numeric(as.character(data$C2)) 
  data$C2[is.na(data$C2)] <- 0
  
  # 3) Put together C1 + C2  ----
  
  data$Csum <- data$C1 + data$C2
  data$Csum<- as.factor(data$Csum)
  data$NAid<- ifelse(data$Csum == 2,1,0)
  
  
  # 4) FILTER 1 - 4 hours window roll sum > 229 min  -----
  
  data <- data %>%
    mutate(roll_sum_4 = roll_sum(PIMzero, 240, align = "center", fill = NA))
  
  data$filter4h <- rep(NA, nrow(data))
  
  for (i in 121:(nrow(data)-121)) {
    if (!is.na(data$roll_sum_4[i]) & data$roll_sum_4[i] > 229)  {
      data$filter4h[(i-120):(i+120)]  <- paste0(rep(1, 241)) ## check! why 245 and not 241
    } else {}}
  
  data$filter4h <- as.numeric(as.character(data$filter4h)) 
  
  data$filter4h[is.na(data$filter4h)] <- 0
  
  data$NAid <- ifelse(data$NAid == 1, 1, 
                      ifelse(data$NAid == 0 & data$filter4h == 1 & data$roll_sum_NAzero > 75, 1, 0))
  
  
  # 5) FILTER 2: lower bar around chunks of missing ----
  if(filterAround == T) {  
    # > 80 roll_sum_NAzero before or after long chunks
    
    # identify chunks
    is_NA <- rle(data$NAid == 1)
    position <- which(is_NA$values == 1) ## detect all no matter length
    position.lengths.cumsum <- cumsum(is_NA$lengths)
    
    ends <- position.lengths.cumsum[position]
    newindex <- ifelse(position > 1, position - 1, 0)
    starts <-  position.lengths.cumsum[newindex] + 1
    
    if(length(starts) == length(ends)) {
      chunks2 <- as.data.frame(cbind(starts, ends)) } else {
        starts <- c(1,starts)
        chunks2 <- as.data.frame(cbind(starts, ends))
      }
    chunks2$length <- chunks2$ends - chunks2$starts
    
    chunks2$start_next_chunk <- rep(NA, nrow(chunks2))
    chunks2$length_next_chunk <- rep(NA, nrow(chunks2))
    
    
    #chunks2 for NAidFilter
    chunks2$ends <- ifelse(chunks2$length > 240, chunks2$ends + 120, chunks2$ends)
    chunks2$starts <- ifelse(chunks2$length > 240, chunks2$starts - 120, chunks2$starts)
    chunks2$starts <- ifelse(chunks2$starts < 0, 1, chunks2$starts)
    chunks2$length <- chunks2$ends - chunks2$starts
    
    if(nrow(chunks2) == 0) { } else {
      for(i in 1:(nrow(chunks2))) {
        chunks2$start_next_chunk[i] <-  chunks2$starts[(i+1)]
      }
      
      for(i in 1:(nrow(chunks2))) {
        chunks2$length_next_chunk[i] <-  chunks2$length[(i+1)]
      }
      chunks2$distance_from_next <- chunks2$start_next_chunk - chunks2$ends
    }
    
    chunks2$distance_from_next[nrow(chunks2)] <- 0 # so that condition is not messed up
    chunks2$length <- ifelse(chunks2$distance_from_next < 0, chunks2$length + chunks2$distance_from_next, chunks2$length)
    chunks2$distance_from_next <- ifelse(chunks2$distance_from_next < 0, 0, chunks2$distance_from_next)
    chunks2$length <- ifelse(chunks2$length < 0, 0, chunks2$length)
    chunks2$distance_from_next[nrow(chunks2)] <-  ifelse((nrow(data) - chunks2$ends[nrow(chunks2)] +1) <0, 0, (nrow(data) - chunks2$ends[nrow(chunks2)] +1))
    
    use1 <- subset(chunks2, select = c(starts,length))
    use2 <- subset(chunks2, select = c(ends, distance_from_next))
    use2 <- plyr::rename(use2, c(distance_from_next = "length", ends = "starts"))
    use1$NAidF <- rep(1, nrow(use1))
    use2$NAidF <- rep(0, nrow(use2))
    use <- merge(use1,use2, id = "NAidF", all = T)
    
    if(nrow(use) == 0) { } else if (use$starts[1] > 1) {
      row1 <- data.frame(starts = c(1), length = use$starts[1] -1, NAidF = 0)
      use <- rbind(row1, use)
    } 
    
    
    list.rle <- list(lengths = use$length, values = use$NAidF)
    NAidF <- inverse.rle(list.rle)
    NAidF <- NAidF[1:nrow(data)]
    
    data <- cbind(data,NAidF)
    
    data$NAid <- ifelse(data$NAid == 1, 1,
                        ifelse(data$NAid == 0 & data$NAidF == 1 & data$roll_sum_NAzero > 80 & data$roll_sum_4 > 200 & !is.na(data$roll_sum_4), 1, 0)) }
  
  # 6) FILTER 3: if day only has missing and some noise, detect as missing  ----
  # detect average activity of that day, if mean < 100, set all to 1
  
  for(i in 1:(nrow(data)/1440)) {
    i <- (i*1440)-1440
    day <- data$PIM[i:(i+1439)]
    value <- mean(day, na.rm = T)
    if(value < 100 | is.na(value)) {data$NAid[i:(i+1439)] <- rep(1, 1440)} else {
      data$NAid[i:(i+1439)] <- data$NAid[i:(i+1439)] }
  }
  
  # 7) FILTER 4: fill short intervals (<240min) in between long NA chunks (>60 min) or <20% of NA chunks or intervals of <10min in between NA chunks: ----
  
  if(filterBet == T) {
    
    is_NA <- rle(data$NAid == 1)
    position <- which(is_NA$values == 1) ## detect all no matter length
    position.lengths.cumsum <- cumsum(is_NA$lengths)
    
    ends <- position.lengths.cumsum[position]
    newindex <- ifelse(position > 1, position - 1, 0)
    starts <-  position.lengths.cumsum[newindex] + 1
    
    if(length(starts) == length(ends)) {
      chunks <- as.data.frame(cbind(starts, ends)) } else {
        starts <- c(1,starts)
        chunks <- as.data.frame(cbind(starts, ends))
      }
    
    chunks$length <- chunks$ends - chunks$starts
    
    chunks$start_next_chunk <- rep(NA, nrow(chunks))
    
    if(nrow(chunks) == 0) { } else {
      for(i in 1:(nrow(chunks))) {
        chunks$start_next_chunk[i] <-  chunks$starts[(i+1)]
      }
      
      chunks$length_next_chunk <- rep(NA, nrow(chunks))
      
      for(i in 1:(nrow(chunks))) {
        chunks$length_next_chunk[i] <-  chunks$length[(i+1)]
      }
      
      chunks$distance_from_next <- chunks$start_next_chunk - chunks$ends
      
      # if interval in between NA chunks is < 10min
      
      if(filterBetType == 1) { 
        chunks$fill <- ifelse(chunks$distance_from_next < 10, 1, 0) }
      
      # if interval in between NA chunks is < 4h & NA chunks before/after > 1h OR interval in between is <10min OR < interval in between is < 20% of sum of bef and after NA chunks
      
      if(filterBetType == 2) { 
        chunks$fill <- ifelse(chunks$distance_from_next < 240 & chunks$length > 60 & chunks$length_next_chunk >60,1,
                              ifelse(chunks$distance_from_next < 10,1,
                                     ifelse((chunks$distance_from_next/(chunks$length + chunks$length_next_chunk)) < .2, 1, 0)))
      }
      chunks <- chunks[which(chunks$fill == 1),]
      chunks <- chunks[,c(2,4, 6)] ##
      
    }
    
    if(nrow(chunks) == 0) {} else{
      for(i in 1:nrow(chunks)) {
        data$NAid[chunks$ends[i]:chunks$start_next_chunk[i]] <- 1
      } }
  }
  
  # get rid of unnecessary variables
  data <- dplyr::select(data, -c( "TempDiffBin", "TempDiff", "Temp_roll_sum", "PIMzero", "roll_sum",
                                 "Csum", "C1", "C2", "roll_sum_NAzero", "roll_sum_4", "filter4h"))

  if(filterAround == T) {
    data <-  dplyr::select(data, -NAidF)
                  }

  return(data)
}


# # Don't run - tests:
#
# NA01 <- read.csv("data_acti_raw/NA01.txt", sep = ";", skip = 21)
# NA01_clean <- idNA(NA01, filterBet = T, filterAround = T)
# summary(factor(NA01_clean$NAid))

# # test plot - for purposes of seeing the conditions 
# # -- in order to use, comment out lines of code in which we get rid of unnecessary VARS (line 272 - 278)
#
# ggplot(NA01_clean, aes(y = TempDiff, x = seq(1, nrow(NA01_clean), 1))) +
#   geom_line() +
#   geom_line(aes(y = ((roll_sum_NAzero-min(roll_sum_NAzero))/(max(roll_sum_NAzero) - min(roll_sum_NAzero)))-1,  
#                 x = seq(1, nrow(NA01_clean), 1)), color = "grey75") +
#   theme_bw() +
#   geom_point(aes(y = as.numeric(C1-1.01),x = seq(1, nrow(NA01_clean), 1)), color = "green") +
#   geom_point(aes(y = as.numeric(C2-1.02),x = seq(1, nrow(NA01_clean), 1)), color = "red") +
#   geom_point(aes(y = as.numeric(NAid-1.03),x = seq(1, nrow(NA01_clean), 1)), color = "yellow") +
#   geom_hline(yintercept = c(-0.1, 0.1), color = "red") +
#   scale_y_continuous(limits = c(-.5,.5), breaks = seq(-1,1,0.1)) + # some data will be flagged as missing, but it is just the unmarked conditions and very low TempDiff values - comment this out to see
#   scale_x_continuous(breaks = seq(0, nrow(NA01_clean), 1440), labels = seq(0, nrow(NA01_clean)/1440, 1))
