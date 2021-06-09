# get_isd_count_ul_gprs <- function() {
#   r <- runif(1)
#   n <- ifelse(r <= 0.7, 1, ifelse(r <= 0.95, 2, 3))
#   return(n)
# }

trj_isd_ul_gprs <- trajectory() %>% 
  simmer::select("isd") %>% 
  seize_selected() %>% 
  timeout(function() isd.function()) %>% 
  release_selected()

trj_ul_gprs_hlr_hit <- trajectory() %>% 
  set_attribute("hlr_hit", 1) %>%
  join(trj_hlr_hit) %>% 
  join(trj_isd_ul_gprs) %>% 
  join(trj_spc_sms) %>% 
  join(trj_cmap_out)

trj_ul_gprs_hlr_miss <- trajectory() %>% 
  set_attribute("hlr_miss", 1) %>%
  join(trj_hlr_miss) %>% 
  timeout(function() update_cache_hlr(get_attribute(env, "device"), simmer::now(env))) %>% 
  #send(function() { paste0(get_attribute(env, "device"), "_cached_hlr")}) %>%
  join(trj_spc_hit) %>% # ul spc miss does not occur due to system design
  join(trj_isd_ul_gprs) %>% 
  join(trj_spc_sms) %>% 
  join(trj_cmap_out)

trj_ul_gprs <- trajectory() %>% 
  join(trj_set_attributes) %>% 
  set_attribute("rejected", 0) %>% 
  set_global("ul_gprs_current", 1, "+") %>% 
  join(trj_cmap_in) %>% 
  branch(function() is_cached_hlr(get_attribute(env, "device"), simmer::now(env)),
         trj_ul_gprs_hlr_hit,
         trj_ul_gprs_hlr_miss,
         continue = c(T, T)) %>% 
  send(function() paste0(get_attribute(env, "device"),"_", get_attribute(env, "retry"), "_ul_gprs_success")) %>% 
  set_global("ul_gprs_current", -1, "+")


