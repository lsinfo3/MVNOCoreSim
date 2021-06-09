trj_reject <- trajectory() %>% 
  renege_abort() %>% 
  timeout(function() {
    n_unattached <- get_global(env, "unattached")
    
    ## Load based method
    retry_in <- ceiling((n_unattached / 840) * 1000 * 1000)
    return(retry_in)
    
    ## Emnify method
    #buckets <- ceiling(n_unattached / config$init_rate)
    #t <- sample(1:buckets, 1)
    #return(t * 1000 * 1000)
  }) %>%
  timeout(function() {
    dev <<- c(dev, get_attribute(env, "device"))
    ret <<- c(ret, get_attribute(env, "retry")+1)
    cyc <<- c(cyc, get_attribute(env, "cycle"))
    return(0)
  }) %>%
  set_global("unattached", -1, "+") %>% 
  activate("retry_device") %>% 
  leave(1)

trj_reject2 <- trajectory() %>% 
  renege_abort() %>% 
  timeout(function() {
    dev <<- c(dev, get_attribute(env, "device"))
    ret <<- c(ret, get_attribute(env, "retry")+1)
    cyc <<- c(cyc, get_attribute(env, "cycle"))
    return(retry_timer_sai)
  }) %>% set_global("unattached", -1, "+") %>% 
  set_attribute("sai_vlr_timeout", 1) %>% 
  activate("retry_device") %>% 
  leave(1)
  
trj_timeout <- trajectory() %>% 
  timeout(function() {
    dev <<- c(dev, get_attribute(env, "device"))
    ret <<- c(ret, get_attribute(env, "retry")+1)
    cyc <<- c(cyc, get_attribute(env, "cycle"))
    return(0)
  }) %>% set_global("unattached", -1, "+") %>% 
  set_global("devices_current", -1, "+")
  
# Main device behavior
trj_device <- trajectory() %>% 
  set_attribute("attached", 0) %>% 
  set_global("unattached", 1, "+") %>% 
  trap(function() paste0(get_attribute(env, "device"),"_", get_attribute(env, "retry"), "_sai_success"), handler = trajectory() %>% renege_abort()) %>%
  trap(function() paste0(get_attribute(env, "device"),"_", get_attribute(env, "retry"), "_ul_success"), handler = trajectory() %>% renege_abort()) %>%
  trap(function() paste0(get_attribute(env, "device"),"_", get_attribute(env, "retry"), "_ul_gprs_success"), handler = trajectory() %>% renege_abort()) %>%
  trap(function() paste0(get_attribute(env, "device"),"_", get_attribute(env, "retry"), "_device_reject"), handler = trajectory() %>% set_attribute("device_reject", 1) %>% join(trj_reject)) %>%
  #log_("Start SAI!") %>% 
  timeout(function() {
    dev <<- c(dev, get_attribute(env, "device"))
    ret <<- c(ret, get_attribute(env, "retry"))
    cyc <<- c(cyc, get_attribute(env, "cycle"))
    return(0)
  }) %>% 
  activate("sai_vlr") %>% 
  renege_in(retry_timer_sai, out = trajectory() %>%
              join(trj_timeout) %>% 
              set_attribute("sai_vlr_timeout", 1) %>% 
              activate("retry_device")) %>% 
  wait() %>% 
  #log_("SAI Success!") %>% 
  #log_("Start UL!") %>% 
  timeout(function() {
    dev <<- c(dev, get_attribute(env, "device"))
    ret <<- c(ret, get_attribute(env, "retry"))
    cyc <<- c(cyc, get_attribute(env, "cycle"))
    return(0)
  }) %>% 
  activate("ul") %>% 
  renege_in(retry_timer_ul, out = trajectory() %>% 
              join(trj_timeout) %>% 
              set_attribute("ul_timeout", 1) %>% 
              activate("retry_device")) %>% 
  wait() %>% 
  #log_("UL Success!") %>% 
  #log_("Start SAI!") %>% 
  timeout(function() {
    dev <<- c(dev, get_attribute(env, "device"))
    ret <<- c(ret, get_attribute(env, "retry"))
    cyc <<- c(cyc, get_attribute(env, "cycle"))
    return(0)
  }) %>% 
  activate("sai_sgsn") %>% 
  renege_in(retry_timer_sai, out = trajectory() %>% 
              join(trj_timeout) %>%
              set_attribute("sai_sgsn_timeout", 1) %>%
              activate("retry_device")) %>% 
  wait() %>% 
  #log_("SAI Success!") %>%
  #log_("Start UL_GPRS!") %>% 
  timeout(function() {
    dev <<- c(dev, get_attribute(env, "device"))
    ret <<- c(ret, get_attribute(env, "retry"))
    cyc <<- c(cyc, get_attribute(env, "cycle"))
    return(0)
  }) %>% 
  activate("ul_gprs") %>% 
  renege_in(retry_timer_ul_gprs, out = trajectory() %>% 
              join(trj_timeout) %>%
              set_attribute("ul_gprs_timeout", 1) %>% 
              activate("retry_device")) %>% 
  wait() %>% 
  set_attribute("attached", 1) %>% 
  set_global("unattached", -1, "+") %>% 
  set_global("devices_current", -1, "+")

# Different device types (new, retry, cycle)
trj_new_device <- trajectory() %>% 
  set_attribute("device", function() { get_global(env, "nDevices") } ) %>%
  set_attribute("retry", 0) %>%
  set_attribute("cycle", 0) %>%
  set_global("nDevices", 1, "+") %>% 
  join(trj_device)

trj_retry_device <- trajectory() %>% 
  set_attribute("device", function() { i <- dev[1]; dev <<- tail(dev, -1); return(i) }) %>% 
  set_attribute("retry", function() { i <- ret[1]; ret <<- tail(ret, -1); return(i) }) %>% 
  set_attribute("cycle", function() { i <- cyc[1]; cyc <<- tail(cyc, -1); return(i) }) %>%
  set_global("nRetries", 1, "+") %>% 
  join(trj_device)

trj_cycle_device <- trajectory() %>%
  set_attribute("device", function() { i <- dev[1]; dev <<- tail(dev, -1); return(i) }) %>%
  set_attribute("retry", function() { i <- ret[1]; ret <<- tail(ret, -1); return(i) }) %>%
  set_attribute("cycle", function() { i <- cyc[1]; cyc <<- tail(cyc, -1); return(i) }) %>%
  set_global("nCycles", 1, "+") %>%
  join(trj_device)