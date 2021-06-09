
# Load required libraries -------------------------------------------------

library(simmer)
library(data.table)
library(tidyverse)

setwd(dirname(parent.frame(2)$ofile))


# Source simulation versions ----------------------------------------------

source("./sim/sim_baseline_recovery.R")
source("./sim/sim_simple_dropping_recovery.R")
source("./sim/sim_msu_policing_recovery.R")
source("./sim/sim_device_policing_recovery.R")


# Generate configuration --------------------------------------------------

config <- list(
  n_devices = 50000, # The number of devices to simulate
  init_rate = 300, # The arrival rate of new devices
  runtime = 10, # Max runtime of the simulation - mostly relevant for overload scenarios in which consinuously fail to attach to the system
  policing = list(
    # Parameters for MSU Policing
    sai_vlr = 3000, # Nr. of concurrently allowed dialogs for each of the types
    sai_sgsn = 3000,
    ul = 3000,
    ul_gprs = 3000,
    # Parameters for Device Policing
    n_dev = 3000 # Nr. of concurrently allowed devices to have any dialog in the system
  ),
  capacity = list( # CPU count for each of the core components
    cmap = 8,
    hlr = 64,
    spc = 128,
    auc = 8,
    isd = Inf # ISD is a special "dummy" component representing the external network, therefore Infinite capacity is recommended
  ),
  queue = list( # Queue size of each of the components
    cmap = Inf,
    hlr = Inf,
    spc = Inf,
    auc = Inf,
    isd = Inf
  ),
  retry = list( # Time each device waits before reset and retry in seconds after the respective dialog has been issued
    sai = 6,
    ul = 15,
    ul_gprs = 15
  )
)

# Load processing times for each of the components ------------------------

dt_times <- fread("./input/processing_times.csv")

# Select which version of the simulation to run ---------------------------

# Each version of the simulation will create a subfolder with the given
# $name in ./data/
#
# This folder will contain separate, compressed files for arrivals, global
# arrivals, attributes and resources, according to common simmer terminology
#

## 
env <- sim_baseline_recovery(name = "baseline", config = config)
#env <- sim_simple_dropping_recovery(name = "simple_dropping", config = config)
#env <- sim_msu_policing_recovery(name = "msu_policing", config = config)
#env <- sim_device_policing_recovery(name = "device_policing", config = config)
## 

# Gather simulation results -----------------------------------------------

arrivals <- get_mon_arrivals(env, per_resource = T, ongoing = T) %>% as.data.table()

arrivals_global <- get_mon_arrivals(env, ongoing = T) %>% as.data.table()

attributes <- get_mon_attributes(env) %>% as.data.table()

resources <- get_mon_resources(env) %>% as.data.table()

# Example evaluation ------------------------------------------------------

# Computation of the attachment rate, meaning the rate at which devices
# complete their attachment cycle

dt_attachment_rate <- attributes %>%
  dplyr::filter(grepl("device", name) & key == "attached" & value == 1) %>%
  dplyr::mutate(bin = floor(time / 1000 / 1000)) %>%
  dplyr::group_by(bin) %>%
  dplyr::summarize(n = n()) %>%
  complete(bin = 0:max(bin), fill = list(n = 0)) %>% 
  as.data.table()

ggplot(data = dt_attachment_rate, aes(x = bin, y = n)) + 
  geom_line() + 
  labs(x = "Time [sec]", y = "Attachment Rate")



