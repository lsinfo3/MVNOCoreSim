
# Load required libraries -------------------------------------------------

library(data.table)
library(tidyverse)
library(fitdistrplus)

setwd(dirname(parent.frame(2)$ofile))

# Load processing times for each of the components ------------------------

dt_times <- fread("./input/processing_times.csv")


# Fit distributions of various components ---------------------------------

# Get a rough idea about the distribution of the Message In Step (1)
descdist(dt_times[span_short == "cmap_in"]$sample)

# Fit a formal distribution to the empirical data
fit.cmap_in <- fitdist(dt_times[span_short == "cmap_in"]$sample, distr = "logis")
plot(fit.cmap_in)


# Fitting the DB Query Step (3) in case of cache miss
descdist(dt_times[span_short == "spc_miss"]$sample)
fit.spc_miss <- fitdist(dt_times[span_short == "spc_miss"]$sample, distr = "lnorm")
plot(fit.spc_miss)
