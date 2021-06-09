
sim_msu_policing_recovery <- function(name, config) {
  
  # Load libs
  library(simmer)
  library(futile.logger)
  library(data.table)
  library(tidyverse)
  
  # Parse config --------------------------------------------------------
  
  # Init time and runtime
  runtime_us <- config$runtime * 60 * 1000 * 1000
  runtime_total <- runtime_us
  
  # Monitoring level (0, 1 or 2)
  mon_level <- 2
  
  # Capacities
  cmap.schedule <- config$capacity$cmap
  hlr.schedule <- config$capacity$hlr
  spc.schedule <- config$capacity$spc
  auc.schedule <- config$capacity$auc
  isd.schedule <- config$capacity$isd
  
  # Processing settings
  if (config$init_rate == 0) {
    init.df <- data.frame(time = rep(0, config$n_devices))
  } else {
    #t <- (1 / config$init_rate) * 1000 * 1000
    init.df <- data.frame(time = rgeom(n = config$n_devices, p = config$init_rate / 1000 / 1000))
  }
  
  source("./sim/sample_helpers.R")
  
  # Retry behavior
  retry_timer_sai <- config$retry$sai * 1000 * 1000
  retry_timer_ul <- config$retry$ul * 1000 * 1000
  retry_timer_ul_gprs <- config$retry$ul_gprs * 1000 * 1000
  
  # Setup simulation environment
  
  dev <- c()
  ret <- c()
  cyc <- c()
  
  hlr_timer <- 20 * 60 * 1000 * 1000
  hlr_cache <- rep(-hlr_timer, config$n_devices)
  
  spc_timer <- 24 * 60 * 60 * 1000 * 1000
  spc_cache <- rep(-spc_timer, config$n_devices)
  
  is_cached_hlr <- function(key, time) {
    value <- hlr_cache[key+1]
    if ((time - value) < hlr_timer) {
      return(1)
    }
    return(2)
  }
  
  update_cache_hlr <- function(key, time) {
    hlr_cache[key+1] <<- time
    return(0)
  }
  
  is_cached_spc <- function(key, time) {
    value <- spc_cache[key+1]
    if ((time - value) < spc_timer) {
      return(1)
    }
    return(2)
  }
  
  update_cache_spc <- function(key, time) {
    spc_cache[key+1] <<- time
    return(0)
  }
  
  files.trajectories = list.files("./sim/trajectories/msu_policing_recovery/", full.names = T)
  for (f in files.trajectories) {
    source(f, local = T)
  }
  
  env <- simmer() %>% 
    add_global("nDevices", 0) %>% 
    add_global("sai_vlr_current", 0) %>% 
    add_global("sai_sgsn_current", 0) %>% 
    add_global("ul_current", 0) %>% 
    add_global("ul_gprs_current", 0)
  
  env %>%
    # Resources
    add_resource(name = "cmap", capacity = cmap.schedule, queue_size = config$queue$cmap) %>% 
    add_resource(name = "hlr", capacity = hlr.schedule, queue_size = config$queue$hlr) %>% 
    add_resource(name = "auc", capacity = auc.schedule, queue_size = config$queue$auc) %>% 
    add_resource(name = "spc", capacity = spc.schedule, queue_size = config$queue$spc) %>% 
    add_resource(name = "isd", capacity = isd.schedule, queue_size = config$queue$isd) %>% 
    
    # Devices
    #add_generator(name_prefix = "new_device", trajectory = trj_new_device, distribution = at(100), mon = 2) %>% 
    add_dataframe(name_prefix = "new_device", trajectory = trj_new_device, data = init.df, mon = mon_level, col_time = "time", time = "interarrival") %>% 
    add_generator(name_prefix = "retry_device", trajectory = trj_retry_device, distribution = when_activated(), mon = mon_level) %>% 
    
    # Dialogs
    add_generator(name_prefix = "sai_vlr", trajectory = trj_sai_vlr, distribution = when_activated(), mon = mon_level) %>% 
    add_generator(name_prefix = "ul", trajectory = trj_ul, distribution = when_activated(), mon = mon_level) %>% 
    add_generator(name_prefix = "sai_sgsn", trajectory = trj_sai_sgsn, distribution = when_activated(), mon = mon_level) %>% 
    add_generator(name_prefix = "ul_gprs", trajectory = trj_ul_gprs, distribution = when_activated(), mon = mon_level)
  
  
  # Run simulation ----------------------------------------------------------
  
  progress_steps <- 100
  logger_ <- function(msg) {
    flog.info(paste0(name, " -- ", msg, " (nDev: ", get_global(env, "nDevices"), ", unattached: ", get_global(env, "unattached"), ", time: ", round(now(env) / 1000 / 1000 / 60, 2), ")"))
  }
  
  # tic("simtime")
  sim_start_time <- as.numeric(Sys.time())
  env %>% 
    reset() %>% 
    simmer::run(until = runtime_total, progress = logger_, steps = progress_steps)
  #simmer::run(until = runtime_total)
  # toc()
  sim_end_time <- as.numeric(Sys.time())
  
  # Collecting results ---------------------------------------------------------
  
  resources = get_mon_resources(env) %>% as.data.table()
  
  arrivals_global <- get_mon_arrivals(env, ongoing = T) %>% as.data.table()
  
  arrivals = get_mon_arrivals(env, per_resource = T, ongoing = T) %>% as.data.table()
  
  attributes = get_mon_attributes(env) %>% as.data.table()
  
  # Writing results ---------------------------------------------------------
  
  dir <- paste("./data/", name, sep = "/")
  dir.create(dir, recursive = T, showWarnings = F)
  
  resources[, `:=`(name = name,
                   nDevices = config$n_devices,
                   runtime = config$runtime,
                   init_rate = config$init_rate,
                   policing_sai_vlr = config$policing$sai_vlr,
                   policing_sai_sgsn = config$policing$sai_sgsn,
                   policing_ul = config$policing$ul,
                   policing_ul_gprs = config$policing$ul_gprs,
                   sim = "msu_policing_recovery")]
  
  arrivals[, `:=`(name = name,
                  nDevices = config$n_devices,
                  runtime = config$runtime,
                  init_rate = config$init_rate,
                  policing_sai_vlr = config$policing$sai_vlr,
                  policing_sai_sgsn = config$policing$sai_sgsn,
                  policing_ul = config$policing$ul,
                  policing_ul_gprs = config$policing$ul_gprs,
                  sim = "msu_policing_recovery")]
  
  arrivals_global[, `:=`(name = name,
                         nDevices = config$n_devices,
                         runtime = config$runtime,
                         init_rate = config$init_rate,
                         policing_sai_vlr = config$policing$sai_vlr,
                         policing_sai_sgsn = config$policing$sai_sgsn,
                         policing_ul = config$policing$ul,
                         policing_ul_gprs = config$policing$ul_gprs,
                         sim = "msu_policing_recovery")]
  
  attributes[, `:=`(name = name,
                    nDevices = config$n_devices,
                    runtime = config$runtime,
                    init_rate = config$init_rate,
                    policing_sai_vlr = config$policing$sai_vlr,
                    policing_sai_sgsn = config$policing$sai_sgsn,
                    policing_ul = config$policing$ul,
                    policing_ul_gprs = config$policing$ul_gprs,
                    sim = "msu_policing_recovery")]
  
  fwrite(resources, paste0(dir, "/resources.csv.gz"))
  fwrite(arrivals, paste0(dir, "/arrivals.csv.gz"))
  fwrite(arrivals_global, paste0(dir, "/arrivals_global.csv.gz"))
  fwrite(attributes, paste0(dir, "/attributes.csv.gz"))
  
  
  config$real_duration = round(sim_end_time - sim_start_time)
  
  fwrite(config %>% as.data.frame(), paste0(dir, "/config.csv"))
  
  return(env)
}
